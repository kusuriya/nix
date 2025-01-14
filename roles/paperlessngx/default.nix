{ self
, lib
, config
, pkg
, ...
}:
{
  services.paperless = {
    enable = true;
    address = "0.0.0.0";
    consumptionDir = "/dozer-files/files/paperless/import";
    dataDir = "/dozer-files/files/paperless/data";
    port = 28981;
  };
}
