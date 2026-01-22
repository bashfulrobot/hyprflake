# Consuming Hyprflake in Your Flake

This guide covers how to properly integrate hyprflake into your own NixOS flake.

## Required Input Configuration

**IMPORTANT:** You **MUST** set up input follows to ensure version consistency across all dependencies.

Without follows, you may experience:

- Outdated nested dependencies even after updating hyprflake
- Duplicate packages increasing closure size
- Version conflicts between dependencies

### Recommended flake.nix inputs

```nix
{
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

    waybar-auto-hide = {
      url = "github:bashfulrobot/nixpkg-waybar-auto-hide";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprflake = {
      url = "github:bashfulrobot/hyprflake";
      # Follow all inputs to ensure version consistency
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        stylix.follows = "stylix";
        waybar-auto-hide.follows = "waybar-auto-hide";
      };
    };
  };
}
```

## Benefits of Input Follows

- Single source of truth for all package versions in your flake's lock file
- Reduced closure size (no duplicate dependencies)
- Guaranteed compatibility between hyprflake and its sub-dependencies
- Independent updates: update hyprflake without updating its transitive dependencies
- Simplified debugging: all versions controlled in one place

## Why nixpkgs Instead of Upstream Flakes

- Hyprland and hyprshell are sourced from **nixpkgs** (not upstream flakes)
- Versions are managed by nixpkgs maintainers - stable, tested releases
- No binary cache configuration needed (nixpkgs is cached by default)
- Update with `nix flake update nixpkgs` like any other package

## Local Development

If you're developing hyprflake locally and consuming it from another flake, use path references with follows:

```nix
hyprflake = {
  url = "path:/home/user/dev/nix/hyprflake";
  inputs = {
    nixpkgs.follows = "nixpkgs";
    home-manager.follows = "home-manager";
    stylix.follows = "stylix";
    waybar-auto-hide.follows = "waybar-auto-hide";
  };
};
```

## Helper Functions

Hyprflake provides helper functions for common use cases:

### mkHyprlandSystem

Creates a complete NixOS system configuration:

```nix
inputs.hyprflake.lib.mkHyprlandSystem {
  extraModules = [
    ./hardware-configuration.nix
    { networking.hostName = "my-system"; }
  ];
}
```

### mkHyprlandHome

Creates a Home Manager configuration:

```nix
inputs.hyprflake.lib.mkHyprlandHome {
  extraModules = [
    { home.username = "myuser"; }
  ];
}
```

## Module Integration

If not using helper functions, import the modules directly:

**NixOS configuration:**

```nix
{
  imports = [ inputs.hyprflake.nixosModules.default ];

  programs.hyprflake = {
    enable = true;
    # ... options
  };
}
```

**Home Manager configuration:**

```nix
{
  imports = [ inputs.hyprflake.homeManagerModules.default ];

  wayland.windowManager.hyprflake = {
    enable = true;
    # ... options
  };
}
```
