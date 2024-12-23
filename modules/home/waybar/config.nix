{ config, pkgs, lib, ... }:

{
  programs.waybar = {
    settings = [{
      height = 30;
      margin = "20 20 10 20";
      spacing = 10;
      modules-left = ["hyprland/workspaces" "hyprland/window"];
      modules-right = ["tray" "pulseaudio" "cpu" "memory" "clock"];
      tray = {
        # "icon-size" = 21;
        spacing = 10;
      };
      "hyprland/workspaces" = {
        on-click = "activate";
        format = "{icon}";
        format-icons = {
          "1" = "󰈹";
          "2" = "󰈮";
          "3" = "󰭹";
          "4" = "";
          "5" = "";
          "6" = "󱞁";
          "10" = "";
          # "urgent" = "";
          # "active" = "";
          default = "";
        };
      };
      clock = {
        tooltip-format = "{:%H:%M}";
        tooltip = true;
        format-alt = "{:%A, %B %d, %Y}";
        format = "{:%I:%M %p}";
      };
      memory = {
	format = "{}% ";
      };
      pulseaudio = {
        # "scroll-step" = 1; # %, can be a float
        format = "{volume}% {icon} {format_source}";
        format-bluetooth = "{volume}% {icon} {format_source}";
        format-bluetooth-muted = " {icon} {format_source}";
        format-muted = " {format_source}";
        format-source = "{volume}% ";
        format-source-muted = "";
        format-icons = {
          headphone = "󰋎";
          hands-free = "󰋎";
          headset = "󰋎";
          phone = "";
          portable = "";
          car = "";
          default = ["" "" ""];
        };
        on-click = "pavucontrol";
      };
    }];
  };
}
