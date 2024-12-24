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
	# neovim
	ncdu
	yazi
#	discord-canary
	pavucontrol
	pass
	grim
	slurp
	wl-clipboard
	pulseaudio
  ];

  home.file = {
	# ".config/nvim" = {
	# 	source = ./configs/nvim;
	# 	recursive = true;
	# };
	".config/neofetch" = {
		source = ./configs/neofetch;
		recursive = true;
	};
  };
  home.sessionVariables = {
  };


  # home.pointerCursor = {
  #   package = pkgs.catppuccin-cursors.mochaPeach;
  #   name = "Catppuccin-Mocha-Peach-Cursors";
  #   size = 40;
  #   gtk.enable = true;
  # };
  #
  # gtk = {
  #   enable = true;
  #   iconTheme = {
  #     package = (pkgs.catppuccin-papirus-folders.override { flavor = "mocha"; accent = "peach"; });
  #     name  = "Papirus-Dark";
  #   };
  #   theme = {
  #     package = (pkgs.catppuccin-gtk.override { accents = [ "peach" ]; size = "standard"; variant = "mocha"; });
  #     name = "Catppuccin-Mocha-Standard-Peach-Dark";
  #   };
  # };
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

}
