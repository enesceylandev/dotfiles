{ config, pkgs, ... }:

{
  wayland.windowManager.hyprland.settings = {
    monitor="DP-1,1920x1080@165,0x0,1";

    exec-once = [
      "waybar"
      "hyprpaper"
      "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    ];

    windowrule = [
      "opacity 0.3 override 0.3 override,title:(.*)(- Youtube)"
    ];

    input = {
      kb_layout = "tr,us";
      kb_options = "grp:win_space_toggle";
      follow_mouse = 1;
      sensitivity = 0;
      touchpad = {
	  natural_scroll = "no";
      };
      force_no_accel = true;
    };

    general = {
      "$mainMod" = "SUPER";
      "$terminal" = "kitty";
      "$browser" = "firefox";
      gaps_in = 10;
      gaps_out = 20;
      border_size = 2;
      "col.active_border" = "rgb(8aadf4) rgb(24273A) rgb(24273A) rgb(8aadf4) 45deg";
      "col.inactive_border" = "rgb(24273A) rgb(24273A) rgb(24273A) rgb(24273A) 45deg";
      layout = "master";
      # layout = dwindle;
      allow_tearing = false;
    };
    
    cursor = {
      no_hardware_cursors = true;
    };

    decoration = {
      rounding = 10;
    };

    animations = {
      enabled = "no";
      bezier = [
	"myBezier, 0.05, 0.9, 0.1, 0.5"
      ];
      animation = [
	"windows, 1, 7, myBezier"
	"windowsOut, 1, 7, default, popin 80%"
	"border, 1, 10, default"
	"borderangle, 1, 8, default"
	"fade, 1, 7, default"
	"workspaces, 1, 6, default"
      ];
    };

    misc = {
      middle_click_paste = false;
      force_default_wallpaper = -1;
    };
  };

  home.sessionVariables = {
    XCURSOR_SIZE = "20";
    QT_QPA_PLATFORMTHEME = "qt5ct";
    LIBVA_DRIVER_NAME = "nvidia";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}   
