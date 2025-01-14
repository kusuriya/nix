{ self
, lib
, config
, pkg
, ...
}:
{
  services.paperless = {
    enable = true;
    address = "10.88.0.1";
    consumptionDir = "/dozer-files/files/paperless/import";
    dataDir = "/dozer-files/files/paperless/data";
    consumptionDirIsPublic = true;
    port = 28981;
    environmentFile = "/etc/paperless/env";
  };
  environment.etc."paperless/env" = {
    mode = "0555";
    text = ''
      PAPERLESS_URL="https://paperless.lan.corrupted.io"
    '';
  };
}
