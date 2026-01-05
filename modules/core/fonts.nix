{ lib, config, pkgs, ... }:
{
  fonts = {
    packages = with pkgs; [
      dejavu_fonts
      emacs-all-the-icons-fonts
      jetbrains-mono
      font-awesome
      noto-fonts
      noto-fonts-color-emoji
      fira-mono
      fira-sans
      nerd-fonts.caskaydia-cove
      nerd-fonts.caskaydia-mono
      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      nerd-fonts.jetbrains-mono
    ];
  };
}
