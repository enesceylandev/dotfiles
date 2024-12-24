{ pkgs, ... }:

{
  imports = [
    ./hyprland
    ./waybar
    ./nvim
    
    ./rofi.nix
    ./btop.nix
    ./browser.nix
    ./sh.nix
    ./kitty.nix
    ./dunst.nix
  ];
}
