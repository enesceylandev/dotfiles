{ config, lib, pkgs, ... }:

{
  programs.obs-studio = {
  enable = false;
  plugins = with pkgs.obs-studio-plugins; [
    wlrobs
    obs-backgroundremoval
    obs-pipewire-audio-capture
  ];
  };
}
