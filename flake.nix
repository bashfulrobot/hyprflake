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

    # Snappy Switcher: a fast, zero-runtime-deps MRU Alt+Tab window switcher
    # for Hyprland (Wayland layer-shell overlay, talks to Hyprland IPC). Fills
    # the traditional-alt-tab gap DMS does not cover — its SUPER+Tab overview
    # is an exposé, not an MRU switcher. Consumed by
    # modules/desktop/snappy-switcher. Upstream ships no home-manager module.
    snappy-switcher = {
      url = "github:OpalAayan/snappy-switcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dank-material-shell = {
      # Pinned to a release tag (bump with `just bump`). This input provides the DMS
      # home-manager module (modules/desktop/dank). The greeter nixosModule
      # used to live here too, but v1.6.0 split it out into the dank-greeter
      # input below (see nixosModules.greeter's builtins.warn in DMS's
      # flake.nix). The dms-shell *package* now comes from nixpkgs
      # (`pkgs.dms-shell`), which has caught up to v1.5.0 and carries the
      # Lua-config dispatch fix that once forced consuming the package from
      # here. Bump this pin with `just bump dank-material-shell` when a newer
      # DMS release is out; the hyprflake-updates timer flags that.
      url = "github:AvengeMedia/DankMaterialShell/v2.1.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DMS's login-screen greeter, split out of dank-material-shell as of DMS
    # v1.6.0. Provides the NixOS module (modules/default.nix) that defines
    # `programs.dms-greeter.*`, consumed by modules/desktop/display-manager.
    dank-greeter = {
      url = "github:AvengeMedia/dank-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DankMaterialShell launcher plugin: emoji + unicode picker (trigger ":e").
    # Replaces the dropped rofimoji as a DMS-native plugin. Not a flake.
    dms-emoji-launcher = {
      url = "github:devnullvoid/dms-emoji-launcher/cd7bbba76c0d9b8da65337de5125659846e1ce5c";
      flake = false;
    };

    # DankMaterialShell bar widget: open PRs you authored and issues assigned
    # to you, polled from GitHub via the `gh` CLI. Wired as a `githubNotifier`
    # plugin and placed in the bar's right cluster (modules/desktop/dank). The
    # plugin's `id` is `githubNotifier`, which must match its attr name there so
    # DMS resolves the widget. SHA-pinned like the rest, not the moving branch;
    # bump deliberately.
    dms-github-notifier = {
      url = "github:psyreactor/dms-githubNotifier/24ce96bc73d08ae60261a0fbe6370d10ac62221a";
      flake = false;
    };

    # DankMaterialShell launcher plugin: run a shell command from the launcher
    # (trigger ">"). Plugin `id` is `commandRunner`. SHA-pinned; bump
    # deliberately.
    dms-command-runner = {
      url = "github:devnullvoid/dms-command-runner/ea59490eede60d7dc87697b670f1eccc6ad54593";
      flake = false;
    };

    # DankMaterialShell launcher plugin: evaluate a math expression and copy the
    # result (trigger "="). Plugin `id` is `calculator`; declares
    # `requires_dms >= 1.4.0`, satisfied by the pinned DMS above. SHA-pinned.
    dms-calculator = {
      url = "github:rochacbruno/DankCalculator/a27b80ad8c3dd42da11af83461674fb362817515";
      flake = false;
    };

    # AvengeMedia's first-party DMS plugin monorepo. We consume two daemon
    # plugins from subdirectories: DankBatteryAlerts (low-battery
    # notifications) and DankHooks (run scripts on system events). Their plugin
    # `id`s are `dankBatteryAlerts` and `dankHooks`; the attr names in
    # modules/desktop/dank match. Only those two subdirs are linked into the
    # DMS plugins dir and loaded; the rest of the monorepo (some siblings call
    # out to api.danklinux.com) lands in the store closure but is never linked
    # or enabled, so it cannot run. Review the whole subtree's diff on each pin
    # bump regardless. SHA-pinned; bump deliberately.
    dms-plugins = {
      url = "github:AvengeMedia/dms-plugins/7a964dad725964550734e43dbbcf88c72829d847";
      flake = false;
    };

    # DankSearch (dsearch): the dank ecosystem's indexed filesystem search
    # server. The DMS launcher's file search auto-detects it (DSearchService.qml
    # runs `command -v dsearch`, then execs `dsearch search --json`); without it
    # the launcher shows "File search requires dsearch". Consumed as a
    # home-manager module (programs.dsearch) in modules/desktop/dank — the
    # DMS-native, DMS-first search backend. Index lives under XDG_CACHE_HOME,
    # not the store.
    #
    # Pinned to a SHA, not the moving default branch, for the same reason as
    # dank-material-shell above: dsearch is a daemon that walks the user's home
    # and holds fsnotify watches, so an unreviewed upstream change to its walk
    # or watch behavior should not drift in on `nix flake update`. Bump
    # deliberately by editing this rev.
    danksearch = {
      url = "github:AvengeMedia/danksearch/a25a7be5626ef4776a1600b1013583cff5ed71f9";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@flakeInputs:
    {
      # Main module export - import this in your flake
      # Call the modules function directly with hyprflake's inputs
      nixosModules.default = import ./modules { hyprflakeInputs = flakeInputs; };

      # Formatter for nix files
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

      # Eval, lint and script-test gates; see ./checks.nix.
      checks.x86_64-linux = import ./checks.nix {
        inherit self nixpkgs;
        inherit (flakeInputs) home-manager;
      };
    };
}
