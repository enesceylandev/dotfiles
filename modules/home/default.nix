{ pkgs, ... }:

{
  imports = [
    ./hyprland
    ./waybar
    
    ./rofi.nix
    ./btop.nix
    ./browser.nix
    ./sh.nix
    ./kitty.nix
    ./dunst.nix
    ./fastfetch.nix
  ];
}
