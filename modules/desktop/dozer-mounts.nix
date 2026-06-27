{ ... }:
{
  # --- NFS mounts from dozer (NAS) ---
  # Uses systemd automount (noauto) so the mount is only established on first
  # access, and unmounted after 5 minutes of idle to save bandwidth.
  # 'timeo=14' and 'retrans=2' tune timeout/retry for unreliable links.
  fileSystems."/data" = {
    device = "dozer:/mnt/dozer-files/hermes-data";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "async" "x-systemd.idle-timeout=5min" "timeo=14" "retrans=2" ];
  };

  fileSystems."/dozer/files" = {
    device = "dozer:/mnt/dozer-files/files";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=5min" "timeo=14" "retrans=2" ];
  };
}
