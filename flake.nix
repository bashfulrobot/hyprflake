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

    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dank-material-shell = {
      # Pinned to a specific master commit, NOT the moving `master` branch.
      # The Lua-config dispatch fix (HyprlandService.qml emits `hl.dsp.*`
      # instead of legacy `workspace N`, which Hyprland's Lua config rejects)
      # is not in any release tag yet — the latest, v1.4.6, lacks it. Freezing
      # the SHA stops `nix flake update` from drifting onto unreviewed master
      # commits; bumping is then a deliberate edit. Run `just dms-check` to see
      # when a *release* carries the fix; at that point pin the tag here and
      # restore `package = pkgs.dms-shell` in modules/desktop/dank. The shell
      # package is consumed from this input (see modules/desktop/dank); the
      # home module always was. See docs/workarounds.md.
      url = "github:AvengeMedia/DankMaterialShell/335c5b4ac55382c2077ab2a18129c03dafb9558b";
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

