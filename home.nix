{ config, pkgs, ... }:

{
  imports = [
    ./sh.nix
  ];
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "enes";
  home.homeDirectory = "/home/enes";

  home.stateVersion = "24.11"; # Please read the comment before changing.
  home.enableNixpkgsReleaseCheck = false;
  home.packages = [
    pkgs.hello

  ];

  home.file = {
	".config/kitty" = {
		source = ./configs/kitty;
	};
	".config/waybar" = {
		source = ./configs/waybar;
	};
	".config/hypr" = {
		source = ./configs/hypr;
	};
	".config/dunst" = {
		source = ./configs/dunst;
	};
	".config/rofi" = {
		source = ./configs/rofi;
	};
	".config/nvim" = {
		source = ./configs/nvim;
	};
	".config/neofetch" = {
		source = ./configs/neofetch;
	};
	".config/btop" = {
		source = ./configs/btop;
	};
	
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/enes/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

}
