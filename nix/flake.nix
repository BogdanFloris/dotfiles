{
  description = "Global packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        # install with: nix profile install ~/dotfiles/nix#global
        packages.global = pkgs.buildEnv {
          name = "global-profile";
          paths = with pkgs; [
            # shell + plugins
	    fish
            fishPlugins.fish-you-should-use
            fishPlugins.plugin-git
            fishPlugins.hydro
            fishPlugins.sponge
            fishPlugins.colored-man-pages

            # baseline CLIs
            tmux
            direnv
            sesh
            git
            ripgrep
            fd
            fzf
            curl
	    jq
            wget
	    stow
	    bat
	    jujutsu
	    atuin
            zoxide
            neovim
          ];
        };
      });
}
