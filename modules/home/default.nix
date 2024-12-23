{ pkgs, ... }:

{
  imports = [
    ./btop.nix
    ./browser.nix
    ./sh.nix
    ./hyprland
    ./waybar
    ./kitty
  ];
}
