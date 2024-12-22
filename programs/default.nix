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

  environment.systemPackages = with pkgs; [
     git
     gcc 
     nodejs_22
     unzip
  ];
}
