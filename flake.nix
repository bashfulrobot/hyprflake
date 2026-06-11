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

    # DankMaterialShell bar widget: open PRs you authored and issues assigned
    # to you, polled from GitHub via the `gh` CLI. Wired as a `githubNotifier`
    # plugin and placed in the bar's right cluster (modules/desktop/dank). The
    # plugin's `id` is `githubNotifier`, which must match its attr name there so
    # DMS resolves the widget. SHA-pinned like the rest, not the moving branch;
    # bump deliberately.
    dms-github-notifier = {
      url = "github:psyreactor/dms-githubNotifier/01c929dd8df3d4dcfe12bfa743eec5d096ae6fde";
      flake = false;
    };

    # DankMaterialShell launcher plugin: run a shell command from the launcher
    # (trigger ">"). Plugin `id` is `commandRunner`. SHA-pinned; bump
    # deliberately.
    dms-command-runner = {
      url = "github:devnullvoid/dms-command-runner/35277695de06beadaba701cb94cc8b096b233319";
      flake = false;
    };

    # DankMaterialShell launcher plugin: evaluate a math expression and copy the
    # result (trigger "="). Plugin `id` is `calculator`; declares
    # `requires_dms >= 1.4.0`, satisfied by the pinned DMS above. SHA-pinned.
    dms-calculator = {
      url = "github:rochacbruno/DankCalculator/73073d051d08254633f28f89d2609344c8289813";
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
      url = "github:AvengeMedia/dms-plugins/f4583449f12920e0a2f16808b00a860c27f0173d";
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
      url = "github:AvengeMedia/danksearch/e4be0825f06370d506e4755cfeae97247a18586f";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, ... }@flakeInputs:
    {
      # Main module export - import this in your flake
      # Call the modules function directly with hyprflake's inputs
      nixosModules.default = import ./modules { hyprflakeInputs = flakeInputs; };

      # Formatter for nix files
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

      checks.x86_64-linux =
        let pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in {
          dank-diff-pytest = pkgs.runCommand "dank-diff-pytest"
            { nativeBuildInputs = [ pkgs.python3 pkgs.python3Packages.pytest ]; } ''
            cp -r ${./modules/desktop/dank/capture} capture
            chmod -R u+w capture
            cd capture && python3 -m pytest tests/test_diff.py -q
            touch $out
          '';

          dank-seed-bats = pkgs.runCommand "dank-seed-bats"
            { nativeBuildInputs = [ pkgs.bats pkgs.coreutils ]; } ''
            cp -r ${./modules/desktop/dank/capture} capture
            chmod -R u+w capture
            cd capture && bats tests/seed.bats
            touch $out
          '';
        };
    };
}

