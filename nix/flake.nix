{
  description = "Global packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pwndbg.url = "github:pwndbg/pwndbg";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    pwndbg,
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
            helix

            # ai tools
            claude-code
            codex
          ])
          ++ [pwndbg.packages.${system}.pwndbg-lldb]
          ++ lib.optionals pkgs.stdenv.isLinux [pkgs.xclip pkgs.wl-clipboard];
      };
    });
}
