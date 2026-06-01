{
  description = "Opinionated Hyprland desktop environment flake - consumable by other flakes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    voxtype = {
      url = "github:peteonrails/voxtype";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    waybar-auto-hide = {
      url = "github:bashfulrobot/nixpkg-waybar-auto-hide";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dank-material-shell = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DankMaterialShell launcher plugin: emoji + unicode picker (trigger ":e").
    # Replaces the dropped rofimoji as a DMS-native plugin. Not a flake.
    dms-emoji-launcher = {
      url = "github:devnullvoid/dms-emoji-launcher/1c0a7d337a52b48f9499060076703a35e8dd4f4f";
      flake = false;
    };
  };

  outputs = { nixpkgs, ... }@flakeInputs:
    {
      # Main module export - import this in your flake
      # Call the modules function directly with hyprflake's inputs
      nixosModules.default = import ./modules { hyprflakeInputs = flakeInputs; };

      # Formatter for nix files
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
    };
}

