{
  description = "NixOS workstation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pwndbg.url = "github:pwndbg/pwndbg";
    xremap-flake.url = "github:xremap/nix-flake";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
    xremap-flake,
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
      nixosConfigurations.erebor = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          lanzaboote.nixosModules.lanzaboote
          xremap-flake.nixosModules.default
          ./hosts/erebor/disko.nix
          ./hosts/erebor/hardware-configuration.nix
          ./hosts/erebor/configuration.nix
        ];
      };
    };
}
