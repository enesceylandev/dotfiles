{ config, pkgs, ... }:

{
  imports =
    [
      ./modules/core
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.defaultUserShell = pkgs.zsh;
  users.users.enes = {
    isNormalUser = true;
    description = "enes";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    ];
  };


}
