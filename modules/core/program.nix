{ config, pkgs, ... }:

{
  programs = {
    zsh.enable = true;
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  };

  environment.variables = {
    EDITOR = "nvim";
  };
}
