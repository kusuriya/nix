/*
 * USB Video Class (UVC) Device Emulation with V4L2 Backend
 * 
 * This device reads from a V4L2 device on the host (e.g., OBS Virtual Camera)
 * and presents it as a USB webcam to the guest.
 *
 * Copyright (c) 2024
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "qemu/osdep.h"
#include "qemu/module.h"
#include "qemu/thread.h"
#include "qemu/main-loop.h"
#include "qapi/error.h"
#include "hw/usb.h"
#include "hw/usb/desc.h"
#include "migration/vmstate.h"

#include <linux/videodev2.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <poll.h>

/* UVC Specification Constants */
#define UVC_SC_VIDEOCONTROL             0x01
#define UVC_SC_VIDEOSTREAMING           0x02

#define UVC_VC_HEADER                   0x01
#define UVC_VC_INPUT_TERMINAL           0x02
#define UVC_VC_OUTPUT_TERMINAL          0x03
#define UVC_VC_PROCESSING_UNIT          0x05

#define UVC_VS_INPUT_HEADER             0x01
#define UVC_VS_FORMAT_UNCOMPRESSED      0x04
#define UVC_VS_FRAME_UNCOMPRESSED       0x05
#define UVC_VS_FORMAT_MJPEG             0x06
#define UVC_VS_FRAME_MJPEG              0x07
#define UVC_VS_COLORFORMAT              0x0D

#define UVC_TT_STREAMING                0x0101
#define UVC_ITT_CAMERA                  0x0201
#define UVC_OTT_DISPLAY                 0x0301

/* UVC Request Codes */
#define UVC_SET_CUR                     0x01
#define UVC_GET_CUR                     0x81
#define UVC_GET_MIN                     0x82
#define UVC_GET_MAX                     0x83
#define UVC_GET_RES                     0x84
#define UVC_GET_LEN                     0x85
#define UVC_GET_INFO                    0x86
#define UVC_GET_DEF                     0x87

/* Video Streaming Interface Controls */
#define UVC_VS_PROBE_CONTROL            0x01
#define UVC_VS_COMMIT_CONTROL           0x02

/* V4L2 Buffer Management */
#define V4L2_BUFFER_COUNT               4
#define MAX_FRAME_SIZE                  (1920 * 1080 * 2)

#define TYPE_USB_UVC "usb-uvc"
OBJECT_DECLARE_SIMPLE_TYPE(USBUVCState, USB_UVC)

/* UVC Probe/Commit Control Structure */
typedef struct QEMU_PACKED UVCProbeCommit {
    uint16_t bmHint;
    uint8_t  bFormatIndex;
    uint8_t  bFrameIndex;
    uint32_t dwFrameInterval;
    uint16_t wKeyFrameRate;
    uint16_t wPFrameRate;
    uint16_t wCompQuality;
    uint16_t wCompWindowSize;
    uint16_t wDelay;
    uint32_t dwMaxVideoFrameSize;
    uint32_t dwMaxPayloadTransferSize;
    uint32_t dwClockFrequency;
    uint8_t  bmFramingInfo;
    uint8_t  bPreferedVersion;
    uint8_t  bMinVersion;
    uint8_t  bMaxVersion;
} UVCProbeCommit;

/* V4L2 Buffer */
typedef struct V4L2Buffer {
    void *start;
    size_t length;
} V4L2Buffer;

/* Frame Format Descriptor */
typedef struct UVCFrameFormat {
    uint32_t width;
    uint32_t height;
    uint32_t pixel_format;  /* V4L2 format */
    uint32_t frame_interval; /* 100ns units */
} UVCFrameFormat;

struct USBUVCState {
    USBDevice dev;

    /* V4L2 Backend */
    char *v4l2_device;
    int v4l2_fd;
    V4L2Buffer buffers[V4L2_BUFFER_COUNT];
    int n_buffers;
    bool streaming;

    /* Current format */
    UVCFrameFormat current_format;
    UVCProbeCommit probe;
    UVCProbeCommit commit;

    /* Frame buffer for USB transfer */
    uint8_t *frame_data;
    uint32_t frame_size;
    uint32_t frame_offset;
    bool frame_ready;
    uint8_t frame_id;

    /* USB Endpoints */
    USBEndpoint *ep_iso;

    /* Async I/O */
    QemuMutex frame_mutex;
    QEMUBH *bh;
};

/* ============== USB Descriptors ============== */

enum {
    STR_MANUFACTURER = 1,
    STR_PRODUCT,
    STR_SERIALNUMBER,
    STR_CONFIG,
    STR_VIDEO_CONTROL,
    STR_VIDEO_STREAMING,
};

static const USBDescStrings desc_strings = {
    [STR_MANUFACTURER]    = "QEMU",
    [STR_PRODUCT]         = "QEMU USB Webcam",
    [STR_SERIALNUMBER]    = "1",
    [STR_CONFIG]          = "Video Config",
    [STR_VIDEO_CONTROL]   = "Video Control",
    [STR_VIDEO_STREAMING] = "Video Streaming",
};

/* UVC Video Control Interface Header Descriptor */
static const uint8_t uvc_vc_header[] = {
    0x0D,                   /* bLength */
    0x24,                   /* bDescriptorType: CS_INTERFACE */
    UVC_VC_HEADER,          /* bDescriptorSubType: VC_HEADER */
    0x10, 0x01,             /* bcdUVC: 1.10 */
    0x47, 0x00,             /* wTotalLength: 71 bytes */
    0x00, 0x6C, 0xDC, 0x02, /* dwClockFrequency: 48MHz */
    0x01,                   /* bInCollection: 1 streaming interface */
    0x01,                   /* baInterfaceNr(1): interface 1 */
};

/* Camera Terminal Descriptor */
static const uint8_t uvc_camera_terminal[] = {
    0x12,                   /* bLength */
    0x24,                   /* bDescriptorType: CS_INTERFACE */
    UVC_VC_INPUT_TERMINAL,  /* bDescriptorSubType: VC_INPUT_TERMINAL */
    0x01,                   /* bTerminalID */
    0x01, 0x02,             /* wTerminalType: ITT_CAMERA */
    0x00,                   /* bAssocTerminal */
    0x00,                   /* iTerminal */
    0x00, 0x00,             /* wObjectiveFocalLengthMin */
    0x00, 0x00,             /* wObjectiveFocalLengthMax */
    0x00, 0x00,             /* wOcularFocalLength */
    0x03,                   /* bControlSize */
    0x00, 0x00, 0x00,       /* bmControls */
};

/* Processing Unit Descriptor */
static const uint8_t uvc_processing_unit[] = {
    0x0C,                   /* bLength */
    0x24,                   /* bDescriptorType: CS_INTERFACE */
    UVC_VC_PROCESSING_UNIT, /* bDescriptorSubType: VC_PROCESSING_UNIT */
    0x02,                   /* bUnitID */
    0x01,                   /* bSourceID: Camera Terminal */
    0x00, 0x00,             /* wMaxMultiplier */
    0x03,                   /* bControlSize */
    0x00, 0x00, 0x00,       /* bmControls */
    0x00,                   /* iProcessing */
    0x00,                   /* bmVideoStandards */
};

/* Output Terminal Descriptor */
static const uint8_t uvc_output_terminal[] = {
    0x09,                   /* bLength */
    0x24,                   /* bDescriptorType: CS_INTERFACE */
    UVC_VC_OUTPUT_TERMINAL, /* bDescriptorSubType: VC_OUTPUT_TERMINAL */
    0x03,                   /* bTerminalID */
    0x01, 0x01,             /* wTerminalType: TT_STREAMING */
    0x00,                   /* bAssocTerminal */
    0x02,                   /* bSourceID: Processing Unit */
    0x00,                   /* iTerminal */
};

/* Video Streaming Input Header */
static const uint8_t uvc_vs_input_header[] = {
    0x0E,                   /* bLength */
    0x24,                   /* bDescriptorType: CS_INTERFACE */
    UVC_VS_INPUT_HEADER,    /* bDescriptorSubType: VS_INPUT_HEADER */
    0x01,                   /* bNumFormats */
    0x47, 0x00,             /* wTotalLength */
    0x81,                   /* bEndpointAddress: EP 1 IN */
    0x00,                   /* bmInfo */
    0x03,                   /* bTerminalLink: Output Terminal */
    0x00,                   /* bStillCaptureMethod */
    0x00,                   /* bTriggerSupport */
    0x00,                   /* bTriggerUsage */
    0x01,                   /* bControlSize */
    0x00,                   /* bmaControls */
};

/* MJPEG Format Descriptor */
static const uint8_t uvc_mjpeg_format[] = {
    0x0B,                   /* bLength */
    0x24,                   /* bDescriptorType: CS_INTERFACE */
    UVC_VS_FORMAT_MJPEG,    /* bDescriptorSubType: VS_FORMAT_MJPEG */
    0x01,                   /* bFormatIndex */
    0x01,                   /* bNumFrameDescriptors */
    0x01,                   /* bmFlags: FixedSizeSamples */
    0x01,                   /* bDefaultFrameIndex */
    0x00,                   /* bAspectRatioX */
    0x00,                   /* bAspectRatioY */
    0x00,                   /* bmInterlaceFlags */
    0x00,                   /* bCopyProtect */
};

/* MJPEG Frame Descriptor - 640x480 @ 30fps */
static const uint8_t uvc_mjpeg_frame_640x480[] = {
    0x26,                   /* bLength */
    0x24,                   /* bDescriptorType: CS_INTERFACE */
    UVC_VS_FRAME_MJPEG,     /* bDescriptorSubType: VS_FRAME_MJPEG */
    0x01,                   /* bFrameIndex */
    0x00,                   /* bmCapabilities */
    0x80, 0x02,             /* wWidth: 640 */
    0xE0, 0x01,             /* wHeight: 480 */
    0x00, 0x00, 0x77, 0x01, /* dwMinBitRate: 24576000 */
    0x00, 0x00, 0x77, 0x01, /* dwMaxBitRate: 24576000 */
    0x00, 0x60, 0x09, 0x00, /* dwMaxVideoFrameBufferSize: 614400 */
    0x15, 0x16, 0x05, 0x00, /* dwDefaultFrameInterval: 333333 (30fps) */
    0x01,                   /* bFrameIntervalType: 1 discrete */
    0x15, 0x16, 0x05, 0x00, /* dwFrameInterval(1): 333333 (30fps) */
};

/* Color Matching Descriptor */
static const uint8_t uvc_color_matching[] = {
    0x06,                   /* bLength */
    0x24,                   /* bDescriptorType: CS_INTERFACE */
    UVC_VS_COLORFORMAT,     /* bDescriptorSubType: VS_COLORFORMAT */
    0x01,                   /* bColorPrimaries: BT.709 */
    0x01,                   /* bTransferCharacteristics: BT.709 */
    0x04,                   /* bMatrixCoefficients: SMPTE 170M */
};

/* Full-speed endpoint companion */
static const USBDescIface desc_iface_video_control = {
    .bInterfaceNumber              = 0,
    .bNumEndpoints                 = 0,
    .bInterfaceClass               = USB_CLASS_VIDEO,
    .bInterfaceSubClass            = UVC_SC_VIDEOCONTROL,
    .bInterfaceProtocol            = 0x00,
    .iInterface                    = STR_VIDEO_CONTROL,
};

static const USBDescIface desc_iface_video_streaming_alt0 = {
    .bInterfaceNumber              = 1,
    .bAlternateSetting             = 0,
    .bNumEndpoints                 = 0,
    .bInterfaceClass               = USB_CLASS_VIDEO,
    .bInterfaceSubClass            = UVC_SC_VIDEOSTREAMING,
    .bInterfaceProtocol            = 0x00,
    .iInterface                    = STR_VIDEO_STREAMING,
};

static const USBDescIface desc_iface_video_streaming_alt1 = {
    .bInterfaceNumber              = 1,
    .bAlternateSetting             = 1,
    .bNumEndpoints                 = 1,
    .bInterfaceClass               = USB_CLASS_VIDEO,
    .bInterfaceSubClass            = UVC_SC_VIDEOSTREAMING,
    .bInterfaceProtocol            = 0x00,
    .iInterface                    = STR_VIDEO_STREAMING,
    .eps = (USBDescEndpoint[]) {
        {
            .bEndpointAddress      = USB_DIR_IN | 0x01,
            .bmAttributes          = USB_ENDPOINT_XFER_ISOC | 0x04, /* Async */
            .wMaxPacketSize        = 1024,
            .bInterval             = 1,
        },
    },
};

static const USBDescDevice desc_device = {
    .bcdUSB                        = 0x0200,
    .bDeviceClass                  = 0xEF,  /* Misc */
    .bDeviceSubClass               = 0x02,  /* Common */
    .bDeviceProtocol               = 0x01,  /* IAD */
    .bMaxPacketSize0               = 64,
    .bNumConfigurations            = 1,
    .confs = (USBDescConfig[]) {
        {
            .bNumInterfaces        = 2,
            .bConfigurationValue   = 1,
            .iConfiguration        = STR_CONFIG,
            .bmAttributes          = USB_CFG_ATT_ONE,
            .bMaxPower             = 250, /* 500mA */
            .nif = 3,
            .ifs = (const USBDescIface *[]) {
                &desc_iface_video_control,
                &desc_iface_video_streaming_alt0,
                &desc_iface_video_streaming_alt1,
            },
        },
    },
};

static const USBDesc desc = {
    .id = {
        .idVendor          = 0x1d6b,  /* Linux Foundation */
        .idProduct         = 0x0102,  /* Webcam gadget */
        .bcdDevice         = 0x0100,
        .iManufacturer     = STR_MANUFACTURER,
        .iProduct          = STR_PRODUCT,
        .iSerialNumber     = STR_SERIALNUMBER,
    },
    .full = &desc_device,
    .high = &desc_device,
    .str  = desc_strings,
};

/* ============== V4L2 Backend Functions ============== */

static int uvc_v4l2_open(USBUVCState *s, Error **errp)
{
    struct v4l2_capability cap;
    struct v4l2_format fmt;

    s->v4l2_fd = open(s->v4l2_device, O_RDWR | O_NONBLOCK);
    if (s->v4l2_fd < 0) {
        error_setg(errp, "Cannot open V4L2 device %s: %s",
                   s->v4l2_device, strerror(errno));
        return -1;
    }

    /* Query capabilities */
    if (ioctl(s->v4l2_fd, VIDIOC_QUERYCAP, &cap) < 0) {
        error_setg(errp, "VIDIOC_QUERYCAP failed: %s", strerror(errno));
        goto fail;
    }

    if (!(cap.capabilities & V4L2_CAP_VIDEO_CAPTURE)) {
        error_setg(errp, "%s is not a video capture device", s->v4l2_device);
        goto fail;
    }

    /* Set format - try MJPEG first, fall back to YUYV */
    memset(&fmt, 0, sizeof(fmt));
    fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    fmt.fmt.pix.width = 640;
    fmt.fmt.pix.height = 480;
    fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_MJPEG;
    fmt.fmt.pix.field = V4L2_FIELD_NONE;

    if (ioctl(s->v4l2_fd, VIDIOC_S_FMT, &fmt) < 0) {
        /* Try YUYV */
        fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV;
        if (ioctl(s->v4l2_fd, VIDIOC_S_FMT, &fmt) < 0) {
            error_setg(errp, "Cannot set video format: %s", strerror(errno));
            goto fail;
        }
    }

    s->current_format.width = fmt.fmt.pix.width;
    s->current_format.height = fmt.fmt.pix.height;
    s->current_format.pixel_format = fmt.fmt.pix.pixelformat;
    s->current_format.frame_interval = 333333; /* 30fps in 100ns units */

    return 0;

fail:
    close(s->v4l2_fd);
    s->v4l2_fd = -1;
    return -1;
}

static int uvc_v4l2_init_mmap(USBUVCState *s, Error **errp)
{
    struct v4l2_requestbuffers req;
    int i;

    memset(&req, 0, sizeof(req));
    req.count = V4L2_BUFFER_COUNT;
    req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    req.memory = V4L2_MEMORY_MMAP;

    if (ioctl(s->v4l2_fd, VIDIOC_REQBUFS, &req) < 0) {
        error_setg(errp, "VIDIOC_REQBUFS failed: %s", strerror(errno));
        return -1;
    }

    s->n_buffers = req.count;

    for (i = 0; i < s->n_buffers; i++) {
        struct v4l2_buffer buf;

        memset(&buf, 0, sizeof(buf));
        buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
        buf.memory = V4L2_MEMORY_MMAP;
        buf.index = i;

        if (ioctl(s->v4l2_fd, VIDIOC_QUERYBUF, &buf) < 0) {
            error_setg(errp, "VIDIOC_QUERYBUF failed: %s", strerror(errno));
            return -1;
        }

        s->buffers[i].length = buf.length;
        s->buffers[i].start = mmap(NULL, buf.length,
                                   PROT_READ | PROT_WRITE,
                                   MAP_SHARED, s->v4l2_fd, buf.m.offset);

        if (s->buffers[i].start == MAP_FAILED) {
            error_setg(errp, "mmap failed: %s", strerror(errno));
            return -1;
        }
    }

    return 0;
}

static int uvc_v4l2_start_streaming(USBUVCState *s, Error **errp)
{
    enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    int i;

    /* Queue all buffers */
    for (i = 0; i < s->n_buffers; i++) {
        struct v4l2_buffer buf;

        memset(&buf, 0, sizeof(buf));
        buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
        buf.memory = V4L2_MEMORY_MMAP;
        buf.index = i;

        if (ioctl(s->v4l2_fd, VIDIOC_QBUF, &buf) < 0) {
            error_setg(errp, "VIDIOC_QBUF failed: %s", strerror(errno));
            return -1;
        }
    }

    /* Start streaming */
    if (ioctl(s->v4l2_fd, VIDIOC_STREAMON, &type) < 0) {
        error_setg(errp, "VIDIOC_STREAMON failed: %s", strerror(errno));
        return -1;
    }

    s->streaming = true;
    return 0;
}

static void uvc_v4l2_stop_streaming(USBUVCState *s)
{
    enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;

    if (s->streaming) {
        ioctl(s->v4l2_fd, VIDIOC_STREAMOFF, &type);
        s->streaming = false;
    }
}

static int uvc_v4l2_read_frame(USBUVCState *s)
{
    struct v4l2_buffer buf;
    struct pollfd pfd;
    int ret;

    if (!s->streaming || s->v4l2_fd < 0) {
        return -1;
    }

    /* Poll for available frame */
    pfd.fd = s->v4l2_fd;
    pfd.events = POLLIN;
    ret = poll(&pfd, 1, 0);  /* Non-blocking */

    if (ret <= 0) {
        return -1;  /* No frame available */
    }

    /* Dequeue buffer */
    memset(&buf, 0, sizeof(buf));
    buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    buf.memory = V4L2_MEMORY_MMAP;

    if (ioctl(s->v4l2_fd, VIDIOC_DQBUF, &buf) < 0) {
        return -1;
    }

    /* Copy frame data */
    qemu_mutex_lock(&s->frame_mutex);

    s->frame_size = buf.bytesused;
    if (s->frame_size > MAX_FRAME_SIZE) {
        s->frame_size = MAX_FRAME_SIZE;
    }
    memcpy(s->frame_data, s->buffers[buf.index].start, s->frame_size);
    s->frame_offset = 0;
    s->frame_ready = true;
    s->frame_id ^= 1;  /* Toggle frame ID */

    qemu_mutex_unlock(&s->frame_mutex);

    /* Re-queue buffer */
    if (ioctl(s->v4l2_fd, VIDIOC_QBUF, &buf) < 0) {
        return -1;
    }

    return 0;
}

/* ============== USB UVC Protocol Handling ============== */

static void uvc_init_probe_commit(USBUVCState *s, UVCProbeCommit *pc)
{
    memset(pc, 0, sizeof(*pc));
    pc->bmHint = 0x0001;
    pc->bFormatIndex = 1;
    pc->bFrameIndex = 1;
    pc->dwFrameInterval = s->current_format.frame_interval;
    pc->dwMaxVideoFrameSize = s->current_format.width * 
                              s->current_format.height * 2;
    pc->dwMaxPayloadTransferSize = 1024;
    pc->dwClockFrequency = 48000000;
    pc->bmFramingInfo = 0x03;
    pc->bPreferedVersion = 1;
    pc->bMinVersion = 1;
    pc->bMaxVersion = 1;
}

static int uvc_handle_control(USBUVCState *s, USBPacket *p,
                              int request, int value, int index,
                              int length, uint8_t *data)
{
    int interface = index & 0xff;
    int cs = (value >> 8) & 0xff;
    int ret = 0;

    if (interface == 1) {  /* Video Streaming Interface */
        switch (cs) {
        case UVC_VS_PROBE_CONTROL:
            switch (request) {
            case UVC_SET_CUR:
                if (length >= sizeof(UVCProbeCommit)) {
                    memcpy(&s->probe, data, sizeof(UVCProbeCommit));
                }
                ret = length;
                break;
            case UVC_GET_CUR:
            case UVC_GET_MIN:
            case UVC_GET_MAX:
            case UVC_GET_DEF:
                uvc_init_probe_commit(s, &s->probe);
                memcpy(data, &s->probe, MIN(length, sizeof(UVCProbeCommit)));
                ret = MIN(length, sizeof(UVCProbeCommit));
                break;
            case UVC_GET_LEN:
                data[0] = sizeof(UVCProbeCommit) & 0xff;
                data[1] = (sizeof(UVCProbeCommit) >> 8) & 0xff;
                ret = 2;
                break;
            case UVC_GET_INFO:
                data[0] = 0x03;  /* GET/SET supported */
                ret = 1;
                break;
            }
            break;

        case UVC_VS_COMMIT_CONTROL:
            switch (request) {
            case UVC_SET_CUR:
                if (length >= sizeof(UVCProbeCommit)) {
                    memcpy(&s->commit, data, sizeof(UVCProbeCommit));
                }
                ret = length;
                break;
            case UVC_GET_CUR:
                memcpy(data, &s->commit, MIN(length, sizeof(UVCProbeCommit)));
                ret = MIN(length, sizeof(UVCProbeCommit));
                break;
            case UVC_GET_LEN:
                data[0] = sizeof(UVCProbeCommit) & 0xff;
                data[1] = (sizeof(UVCProbeCommit) >> 8) & 0xff;
                ret = 2;
                break;
            case UVC_GET_INFO:
                data[0] = 0x03;
                ret = 1;
                break;
            }
            break;
        }
    }

    return ret;
}

/* Build UVC payload header */
static int uvc_build_header(USBUVCState *s, uint8_t *buf, bool eof)
{
    buf[0] = 2;  /* Header length */
    buf[1] = 0x80 | (s->frame_id ? 0x01 : 0x00);  /* BFH: EOH + FID */
    if (eof) {
        buf[1] |= 0x02;  /* EOF */
    }
    return 2;
}

/* ============== USB Device Callbacks ============== */

static void usb_uvc_handle_reset(USBDevice *dev)
{
    USBUVCState *s = USB_UVC(dev);

    uvc_v4l2_stop_streaming(s);
    s->frame_ready = false;
    s->frame_offset = 0;
}

static void usb_uvc_handle_control(USBDevice *dev, USBPacket *p,
                                   int request, int value, int index,
                                   int length, uint8_t *data)
{
    USBUVCState *s = USB_UVC(dev);
    int ret;

    ret = usb_desc_handle_control(dev, p, request, value, index, length, data);
    if (ret >= 0) {
        return;
    }

    switch (request) {
    case ClassInterfaceRequest | USB_REQ_GET_CUR:
    case ClassInterfaceRequest | USB_REQ_GET_MIN:
    case ClassInterfaceRequest | USB_REQ_GET_MAX:
    case ClassInterfaceRequest | USB_REQ_GET_RES:
    case ClassInterfaceRequest | USB_REQ_GET_LEN:
    case ClassInterfaceRequest | USB_REQ_GET_INFO:
    case ClassInterfaceRequest | USB_REQ_GET_DEF:
    case ClassInterfaceOutRequest | USB_REQ_SET_CUR:
        ret = uvc_handle_control(s, p, request & 0xff, value, index,
                                 length, data);
        if (ret > 0) {
            p->actual_length = ret;
        } else {
            p->status = USB_RET_STALL;
        }
        break;

    default:
        p->status = USB_RET_STALL;
        break;
    }
}

static void usb_uvc_handle_data(USBDevice *dev, USBPacket *p)
{
    USBUVCState *s = USB_UVC(dev);
    uint8_t buf[1024];
    int header_len;
    int payload_len;
    int copy_len;
    bool eof = false;

    switch (p->pid) {
    case USB_TOKEN_IN:
        if (p->ep->nr == 1) {  /* Isochronous endpoint */
            /* Try to get a new frame if needed */
            if (!s->frame_ready || s->frame_offset >= s->frame_size) {
                uvc_v4l2_read_frame(s);
                s->frame_offset = 0;
            }

            qemu_mutex_lock(&s->frame_mutex);

            if (!s->frame_ready) {
                /* No frame available, send empty packet with header */
                header_len = uvc_build_header(s, buf, false);
                usb_packet_copy(p, buf, header_len);
                qemu_mutex_unlock(&s->frame_mutex);
                return;
            }

            /* Calculate how much data to send */
            payload_len = p->iov.size - 2;  /* Reserve space for header */
            copy_len = MIN(payload_len, s->frame_size - s->frame_offset);

            if (s->frame_offset + copy_len >= s->frame_size) {
                eof = true;
            }

            /* Build header */
            header_len = uvc_build_header(s, buf, eof);

            /* Copy header */
            usb_packet_copy(p, buf, header_len);

            /* Copy payload */
            usb_packet_copy(p, s->frame_data + s->frame_offset, copy_len);
            s->frame_offset += copy_len;

            if (eof) {
                s->frame_ready = false;
                s->frame_offset = 0;
            }

            qemu_mutex_unlock(&s->frame_mutex);
        }
        break;

    default:
        p->status = USB_RET_STALL;
        break;
    }
}

static void usb_uvc_set_interface(USBDevice *dev, int iface,
                                  int old_alt, int new_alt)
{
    USBUVCState *s = USB_UVC(dev);
    Error *local_err = NULL;

    if (iface == 1) {  /* Video Streaming Interface */
        if (new_alt == 1 && old_alt == 0) {
            /* Start streaming */
            if (uvc_v4l2_init_mmap(s, &local_err) < 0) {
                error_report_err(local_err);
                return;
            }
            if (uvc_v4l2_start_streaming(s, &local_err) < 0) {
                error_report_err(local_err);
                return;
            }
        } else if (new_alt == 0 && old_alt == 1) {
            /* Stop streaming */
            uvc_v4l2_stop_streaming(s);
        }
    }
}

/* ============== Device Lifecycle ============== */

static void usb_uvc_realize(USBDevice *dev, Error **errp)
{
    USBUVCState *s = USB_UVC(dev);

    usb_desc_create_serial(dev);
    usb_desc_init(dev);

    if (!s->v4l2_device) {
        s->v4l2_device = g_strdup("/dev/video0");
    }

    s->v4l2_fd = -1;
    s->frame_data = g_malloc(MAX_FRAME_SIZE);
    s->frame_ready = false;
    s->frame_id = 0;

    qemu_mutex_init(&s->frame_mutex);

    /* Open V4L2 device */
    if (uvc_v4l2_open(s, errp) < 0) {
        return;
    }

    /* Initialize probe/commit */
    uvc_init_probe_commit(s, &s->probe);
    uvc_init_probe_commit(s, &s->commit);
}

static void usb_uvc_unrealize(USBDevice *dev)
{
    USBUVCState *s = USB_UVC(dev);
    int i;

    uvc_v4l2_stop_streaming(s);

    /* Unmap buffers */
    for (i = 0; i < s->n_buffers; i++) {
        if (s->buffers[i].start && s->buffers[i].start != MAP_FAILED) {
            munmap(s->buffers[i].start, s->buffers[i].length);
        }
    }

    if (s->v4l2_fd >= 0) {
        close(s->v4l2_fd);
    }

    g_free(s->frame_data);
    g_free(s->v4l2_device);
    qemu_mutex_destroy(&s->frame_mutex);
}

static Property usb_uvc_properties[] = {
    DEFINE_PROP_STRING("v4l2", USBUVCState, v4l2_device),
    DEFINE_PROP_END_OF_LIST(),
};

static void usb_uvc_class_init(ObjectClass *klass, void *data)
{
    DeviceClass *dc = DEVICE_CLASS(klass);
    USBDeviceClass *uc = USB_DEVICE_CLASS(klass);

    uc->product_desc   = "QEMU USB Webcam";
    uc->usb_desc       = &desc;
    uc->realize        = usb_uvc_realize;
    uc->unrealize      = usb_uvc_unrealize;
    uc->handle_reset   = usb_uvc_handle_reset;
    uc->handle_control = usb_uvc_handle_control;
    uc->handle_data    = usb_uvc_handle_data;
    uc->set_interface  = usb_uvc_set_interface;

    device_class_set_props(dc, usb_uvc_properties);
    set_bit(DEVICE_CATEGORY_MISC, dc->categories);
}

static const TypeInfo usb_uvc_info = {
    .name          = TYPE_USB_UVC,
    .parent        = TYPE_USB_DEVICE,
    .instance_size = sizeof(USBUVCState),
    .class_init    = usb_uvc_class_init,
};

static void usb_uvc_register_types(void)
{
    type_register_static(&usb_uvc_info);
}

type_init(usb_uvc_register_types)
