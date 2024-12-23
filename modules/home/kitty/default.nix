{ config, pkgs, lib, ... }:

{
  imports = [
    ./config.nix
    # ./style.nix
  ];

  programs.kitty = {
    enable = true;
  };
}
