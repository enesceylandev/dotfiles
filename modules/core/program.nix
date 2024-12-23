{ config, pkgs, ... }:

{
  programs = {
    zsh.enable = true;
    firefox.enable = true;
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  };
}
