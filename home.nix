{ config, pkgs, ... }:

{
  imports = [
    ./modules/home
  ];
  home.username = "enes";
  home.homeDirectory = "/home/enes";

  home.stateVersion = "24.11";
  home.enableNixpkgsReleaseCheck = false;
  home.packages = with pkgs; [
	neovim
	# kitty
	ncdu
	rofi-wayland
	yazi
#	discord-canary
	grim
	slurp
	wl-clipboard
	pulseaudio
  ];

  home.file = {
	# ".config/kitty" = {
	# 	source = ./configs/kitty;
	# 	recursive = true;
	# };
	# ".config/waybar" = {
	# 	source = ./configs/waybar;
	# 	recursive = true;
	# };
	# ".config/hypr" = {
	# 	source = ./configs/hypr;
	# 	recursive = true;
	# };
	".config/dunst" = {
		source = ./configs/dunst;
		recursive = true;
	};
	".config/rofi" = {
		source = ./configs/rofi;
		recursive = true;
	};
	".config/nvim" = {
		source = ./configs/nvim;
		recursive = true;
	};
	".config/neofetch" = {
		source = ./configs/neofetch;
		recursive = true;
	};
	".config/btop" = {
		source = ./configs/btop;
		recursive = true;
	};
	
  };
  home.sessionVariables = {
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

}
