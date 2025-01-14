{ self
, lib
, config
, pkg
, ...
}:
{
  virtualisation = {
    oci-containers.containers = {
      nginx-proxy-manager = {
        image = "docker.io/jc21/nginx-proxy-manager:latest";
        autoStart = true;
        ports = [
          "80:80"
          "81:81"
          "443:443"
        ];
        volumes = [
          "npm:/data"
          "npm-le:/etc/letsencrypt"
        ];
      };
    };
  };
}
