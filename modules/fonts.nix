{ lib, config, pkgs, ... }:
{
  fonts.packages = with pkgs; [
    dejavu_fonts
    emacs-all-the-icons-fonts
    jetbrains-mono
    font-awesome
    noto-fonts
    noto-fonts-emoji
    nerdfonts
  ];

}
