
{ config, pkgs, ... }:

{
  imports = [
      ./network.nix
      ./program.nix
      ./base.nix
      ./hardware-configuration.nix
      ./gpg.nix
    ];

  environment.systemPackages = with pkgs; [
     git
     gh
     gcc 
     python313
     nodejs_22
     unzip
     ripgrep
     dunst
     libnotify
     fzf
     nemo
     docker-compose
  ];

  virtualisation.docker.enable = true;
  users.users.enes.extraGroups = [ "docker" ];}
