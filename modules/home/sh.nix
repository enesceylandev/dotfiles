{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true; 
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };
    shellAliases = {
      hm = "home-manager switch --flake ~/.dotfiles";
      update-home = "home-manager switch --flake ~/.dotfiles";
      update-nix = "sudo nixos-rebuild switch --flake ~/.dotfiles";
    };
    oh-my-zsh = {
      enable = true;
      theme = "fishy";
      plugins = [
	"sudo"
	"git"
      ];
    };
  };

}
