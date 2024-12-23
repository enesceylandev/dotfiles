{ ... }:

{
  imports = [
    ./config.nix
    ./keybinds.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
  };
}
