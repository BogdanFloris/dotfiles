{
  description = "NixOS workstation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pwndbg.url = "github:pwndbg/pwndbg";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secure Boot for NixOS — lets SB stay permanently ON for Windows
    # anti-cheat while NixOS boots with self-enrolled keys.
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    pwndbg,
    disko,
    lanzaboote,
    ...
  }:
    (flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      lib = pkgs.lib;
    in {
      packages.global = pkgs.buildEnv {
        name = "global-profile";
        paths =
          (import ./packages.nix {inherit pkgs;})
          ++ [pwndbg.packages.${system}.pwndbg]
          ++ lib.optionals pkgs.stdenv.isLinux [pkgs.xclip pkgs.wl-clipboard];
      };
    }))
    // {
      nixosConfigurations.workstation = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          lanzaboote.nixosModules.lanzaboote
          ./hosts/workstation/disko.nix
          ./hosts/workstation/hardware-configuration.nix
          ./hosts/workstation/configuration.nix
        ];
      };
    };
}
