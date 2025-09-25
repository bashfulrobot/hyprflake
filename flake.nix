{
  description = "Reusable Hyprland flake with cachix and home-manager support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cachix = {
      url = "github:cachix/cachix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs, hyprland, home-manager, cachix, stylix, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosModules = {
        hyprland = import ./modules/nixos/hyprland.nix;
        cachix = import ./modules/nixos/cachix.nix;
        stylix = import ./modules/nixos/stylix.nix;
        dconf = import ./modules/nixos/dconf.nix;
        xdg = import ./modules/nixos/xdg.nix;
      };

      homeManagerModules = {
        hyprland = import ./modules/home-manager/hyprland.nix;
        stylix = import ./modules/home-manager/stylix.nix;
        dconf = import ./modules/home-manager/dconf.nix;
        xdg = import ./modules/home-manager/xdg.nix;
      };

      lib = {
        mkHyprlandSystem = { extraModules ? [] }:
          nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              hyprland.nixosModules.default
              home-manager.nixosModules.home-manager
              stylix.nixosModules.stylix
              self.nixosModules.hyprland
              self.nixosModules.cachix
              self.nixosModules.stylix
              self.nixosModules.dconf
              self.nixosModules.xdg
            ] ++ extraModules;
          };

        mkHyprlandHome = { extraModules ? [] }:
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              hyprland.homeManagerModules.default
              stylix.homeManagerModules.stylix
              self.homeManagerModules.hyprland
              self.homeManagerModules.stylix
              self.homeManagerModules.dconf
              self.homeManagerModules.xdg
            ] ++ extraModules;
            extraSpecialArgs = { inherit hyprland stylix; };
          };
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [ nixpkgs-fmt nil ];
      };
    };
}