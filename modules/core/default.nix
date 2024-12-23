
{ config, pkgs, ... }:

{
  imports = [
      ./network.nix
      ./program.nix
      ./base.nix
      ./hardware-configuration.nix
    ];

  environment.systemPackages = with pkgs; [
     git
     gcc 
     nodejs_22
     unzip
     dunst
     libnotify
  ];
}
