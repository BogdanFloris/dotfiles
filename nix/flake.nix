{
  description = "Global packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      lib = pkgs.lib;
    in {
      packages.global = pkgs.buildEnv {
        name = "global-profile";
        paths =
          (with pkgs; [
            alejandra
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
            python313
            jdk25
            android-tools
            gradle
            clang-tools
            starship
            coreutils
            zsh-autosuggestions
            zsh-syntax-highlighting
            stylua
            lua-language-server

            # ai tools
            claude-code
          ])
          # Linux-only clipboard for tmux copy-mode
          ++ lib.optionals pkgs.stdenv.isLinux [pkgs.xclip];
      };
    });
}
