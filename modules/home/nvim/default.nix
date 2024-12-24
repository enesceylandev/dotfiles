{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;


    extraLuaConfig = ''
      ${builtins.readFile ./options.lua}
      ${builtins.readFile ./keymaps.lua}
      '';
  };
}
