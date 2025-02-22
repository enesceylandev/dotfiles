{ pkgs, ... }:

{
  home.packages = with pkgs; [
    hyprpaper
  ];

  services.hyprpaper = {
    enable = true;
    package = pkgs.hyprpaper;
    settings = {
      ipc = "off";
      splash = false;

      preload =
        ["/home/enes/Pictures/Untitled.jpg"];

      wallpaper = [
        "DP-1,/home/enes/Pictures/Untitled.jpg"
      ];
    };
  };
}
