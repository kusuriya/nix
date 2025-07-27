{pkgs, lib, config, ...}:
{
    virtualisation.oci-containers.containers."dakland" = {
        image = "itzg/minecraft-bedrock-server";
        hostname = "dakland";
        pull = "newer";
        autoStart = true;
        environment = {
            EULA = "TRUE";
            GAMEMODE = "creative";
            OPS = "2533274802535679,2535435176223471";
            ALLOW_CHEATS = "true";
        };
        volumes = [
            "mcbr-data:/data"
        ];
        ports = [
            "19132:19132/udp"
        ];
    };
}
