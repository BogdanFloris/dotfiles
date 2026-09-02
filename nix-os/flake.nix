{
  description = "NixOS workstation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
    pwndbg.url = "github:pwndbg/pwndbg";
    sidra.url = "github:wimpysworld/sidra";
    xremap-flake.url = "github:xremap/nix-flake";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-master,
    flake-utils,
    pwndbg,
    sidra,
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
          ++ lib.optionals pkgs.stdenv.isLinux [sidra.packages.${system}.default]
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
          {environment.systemPackages = [sidra.packages.x86_64-linux.default];}
          {
            # track claude-code from nixpkgs master
            nixpkgs.overlays = [
              (final: prev: {
                claude-code =
                  (import nixpkgs-master {
                    inherit (prev.stdenv.hostPlatform) system;
                    config.allowUnfree = true;
                  })
                  .claude-code;
              })
            ];
          }
          ./hosts/erebor/disko.nix
          ./hosts/erebor/hardware-configuration.nix
          ./hosts/erebor/configuration.nix
        ];
      };
    };
}
