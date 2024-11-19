{config, lib, pkgs, ...}:
{
services.greetd = {
      enable = true;
      settings = rec {
        initial_session = {
          command = "Hyprland";
          user = "kusuriya";
        };
        default_session = initial_session;
      };
    };
}
