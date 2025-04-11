{ lib, pkgs, config, ... }:
{
  services.samba = {
    enable = true;
    openFirewall = true;
    securityType = "user";
    settings = {
      global = {
        "workgroup" = "CORRUPTED";
        "server string" = "DOZER";
        "netbios name" = "DOZER";
        "security" = "user";
        "guest account" = "nobody";
      };
      "files" = {
        "path" = "/dozer-files/files";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
      "scans" = {
        "path" = "/dozer-files/scans";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
      "movies" = {
        "path" = "/dozer-files/media/movies";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
      "tv" = {
        "path" = "/dozer-files/media/tv";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
      "music" = {
        "path" = "/dozer-files/media/music";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
      "documents" = {
        "path" = "/dozer-files/documents";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
      "home" = {
        "path" = "/dozer-files/home";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
      "photos" = {
        "path" = "/dozer-files/photos";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
}
