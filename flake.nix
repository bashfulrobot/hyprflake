{
  description = "Hyprland configuration for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, hyprland, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      nixosModules.default = { config, lib, ... }: {
        imports = [ ./configuration.nix ];

        nix = {
          settings = {
            experimental-features = [ "nix-command" "flakes" ];
            substituters =
              [ "https://cache.nixos.org" "https://hyprland.cachix.org" ];
            trusted-public-keys = [
              "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
            ];
          };
        };
      };

      homeManagerModules.default = { config, lib, ... }: {
        imports = [ hyprland.homeManagerModules.default ./home.nix ];
      };
    };
}
