{ config, pkgs, lib, ... }:

{
  programs.kitty = {
    enable = true;
    themeFile = "Catppuccin-Macchiato";

    font = {
      name = "Iosevka Term";
      size = 14.0;
    };
    
    settings = {
        background_opacity = 1;
        editor = "/usr/bin/nvim";
        confirm_os_window_close = 0;
        window_margin_width = 5;
        window_padding_width = 3;
        cursor_trail_decay = "0.1 0.4";
        cursor_trail = 1;
        cursor_blink_interval = 0;
    };
  };
}
