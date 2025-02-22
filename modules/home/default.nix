{ pkgs, ... }:

{
  imports = [
    ./hyprland
    ./waybar
    ./hyprpaper.nix
    
    ./rofi.nix
    ./btop.nix
    ./browser.nix
    ./sh.nix
    ./kitty.nix
    ./dunst.nix
    ./fastfetch.nix
    ./theme.nix
  ];
}
