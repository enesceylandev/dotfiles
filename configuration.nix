{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./services/dns.nix
      ./services/base.nix
      ./programs
    ];


  nix.settings.experimental-features = [ "nix-command" "flakes" ];



  users.defaultUserShell = pkgs.zsh;
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.enes = {
    isNormalUser = true;
    description = "enes";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
	neovim
	kitty
	ncdu
	btop
	rofi
	waybar
	nemo
	discord-canary
	grim
	wl-clipboard
	pulseaudio
    ];
  };


}
