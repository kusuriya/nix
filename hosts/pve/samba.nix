{lib,pkgs,config,...}:
{
  services.samba = {
    enable = true;
    openFirewall = true;
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
  };
  };
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
}
