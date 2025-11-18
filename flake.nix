{
  description = "Opinionated Hyprland desktop environment flake - consumable by other flakes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs, hyprland, home-manager, stylix, ... }@inputs:
    let
      # Capture hyprflake's inputs to pass to modules
      flakeInputs = inputs;
    in
    {
      # Main module export - import this in your flake
      # Override _module.args to pass hyprflake's own inputs to all submodules
      nixosModules.default = {
        imports = [ ./modules ];
        _module.args = { inputs = flakeInputs; };
      };

      # Formatter for nix files
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
    };
}
