{ self
, lib
, config
, pkg
, ...
}:
{
  virtualisation = {
    oci-containers.containers = {
      albyhub = {
        image = "ghcr.io/getalby/hub:latest";
        autoStart = true;
        ports = [ "8080:8080" ];
        volumes = [ "albyhub:/data" ];
        environment = {
          WORK_DIR = "/data";
        };
        workdir = "/data";
        extraOptions = ["--pull always"];
      };
    };
  };
}
