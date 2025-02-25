{ ... }:


{
  wayland.windowManager.hyprland.settings = {
  bind = [
    ",XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
    ",XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
    ",XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"

    "$mainMod, Q, exec, $terminal"
    "$mainMod SHIFT, Q, exec, $terminal btop"
    "$mainMod, C, killactive, "
    "$mainMod, V, togglefloating,"
    "$mainMod, E, exec, $terminal yazi "
    "$mainMod, F, fullscreen"
    "$mainMod, Escape, exec, rofi -show drun"
    "$mainMod, P, pseudo" # dwindle

    "$mainMod, b, exec, $browser"
    "$mainMod SHIFT, b, exec, $browser "
    "$mainMod SHIFT, n, exec, neovide"
    "$mainMod, d, exec, $terminal $browser --new-window https://discord.com/channels/@me" 
    "$mainMod, n, exec, $terminal nvim"
    "$mainMod SHIFT, n, exec, $terminal ~/.dotfiles/modules/home/hyprland/scripts/fn.sh" 
    "$mainMod control, n, exec, $terminal ~/.dotfiles/modules/home/hyprland/scripts/open_quicknote.sh"
    "$mainMod SHIFT, E, exec, $terminal ncdu"
    "$mainMod, g, exec, $terminal $browser --new-window https://github.com/MedusaCollins"
    "$mainMod, w, exec, $terminal $browser --new-window https://web.whatsapp.com/"
    "$mainMod SHIFT, c, exec, $terminal $browser --new-window https://chatgpt.com/"
    "$mainMod, m, exec, $terminal $browser --new-window https://cloud.mongodb.com/v2/670408777918f42d2c7f2da3#/metrics/replicaSet/6704090f28fdba0104dec6da/explorer/Users/accounts/find "
    "$mainMod, l, exec, $terminal $browser --new-window https://www.linkedin.com/"

    #Move focus with mainMod + arrow keys
    "$mainMod, left, movefocus, l"
    "$mainMod, right, movefocus, r"
    "$mainMod, up, movefocus, u"
    "$mainMod, down, movefocus, d"

    # Switch workspaces with mainMod + [0-9]
    "$mainMod, 1, workspace, 1"
    "$mainMod, 2, workspace, 2"
    "$mainMod, 3, workspace, 3"
    "$mainMod, 4, workspace, 4"
    "$mainMod, 5, workspace, 5"
    "$mainMod, 6, workspace, 6"
    "$mainMod, 7, workspace, 7"
    "$mainMod, 8, workspace, 8"
    "$mainMod, 9, workspace, 9"
    "$mainMod, 0, workspace, 10"
    "$mainMod control, 1, workspace, 6"
    "$mainMod control, 2, workspace, 7"
    "$mainMod control, 3, workspace, 8"
    "$mainMod control, 4, workspace, 9"
    "$mainMod control, 5, workspace, 10"

    # Move active window to a workspace with mainMod + SHIFT + [0-9]
    "$mainMod SHIFT, 1, movetoworkspace, 1"
    "$mainMod SHIFT, 2, movetoworkspace, 2"
    "$mainMod SHIFT, 3, movetoworkspace, 3"
    "$mainMod SHIFT, 4, movetoworkspace, 4"
    "$mainMod SHIFT, 5, movetoworkspace, 5"
    "$mainMod SHIFT, 6, movetoworkspace, 6"
    "$mainMod SHIFT, 7, movetoworkspace, 7"
    "$mainMod SHIFT, 8, movetoworkspace, 8"
    "$mainMod SHIFT, 9, movetoworkspace, 9"
    "$mainMod SHIFT, 0, movetoworkspace, 10"
    "$mainMod control SHIFT, 1, movetoworkspace, 6"
    "$mainMod control SHIFT, 2, movetoworkspace, 7"
    "$mainMod control SHIFT, 3, movetoworkspace, 8"
    "$mainMod control SHIFT, 4, movetoworkspace, 9"
    "$mainMod control SHIFT, 5, movetoworkspace, 10"

    "$mainMod control, right, resizeactive, 100 0"
    "$mainMod control, left, resizeactive, -100 0"
    "$mainMod control, up, resizeactive, 0 -100"
    "$mainMod control, down, resizeactive, 0 100"

    "$mainMod SHIFT, left, movewindow, l"
    "$mainMod SHIFT, right, movewindow, r"
    "$mainMod SHIFT, up, movewindow, u"
    "$mainMod SHIFT, down, movewindow, d"

    "$mainMod SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"
    "$mainMod control, S, exec, grim -g \"$(slurp)\" - | wl-copy && wl-paste > ~/Documents/notes/media/Screenshot-$(date +%F_%T).png "
    ];

    # Move/resize windows with mainMod + LMB/RMB and dragging
    bindm = [
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
    ];
  };
}
