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
      # Pinned to the v1.5.0 release tag. This input provides the DMS
      # home-manager module (modules/desktop/dank) and the greeter nixosModule
      # (modules/default.nix). The dms-shell *package* now comes from nixpkgs
      # (`pkgs.dms-shell`), which has caught up to v1.5.0 and carries the
      # Lua-config dispatch fix that once forced consuming the package from
      # here. Bump this pin with `just bump dank-material-shell` when a newer
      # DMS release is out; the hyprflake-updates timer flags that.
      url = "github:AvengeMedia/DankMaterialShell/v1.5.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DankMaterialShell launcher plugin: emoji + unicode picker (trigger ":e").
    # Replaces the dropped rofimoji as a DMS-native plugin. Not a flake.
    dms-emoji-launcher = {
      url = "github:devnullvoid/dms-emoji-launcher/8ff394e3ddfcb2fd755ed2e7b4c6f01f3e26e596";
      flake = false;
    };

    # DankMaterialShell bar widget: open PRs you authored and issues assigned
    # to you, polled from GitHub via the `gh` CLI. Wired as a `githubNotifier`
    # plugin and placed in the bar's right cluster (modules/desktop/dank). The
    # plugin's `id` is `githubNotifier`, which must match its attr name there so
    # DMS resolves the widget. SHA-pinned like the rest, not the moving branch;
    # bump deliberately.
    dms-github-notifier = {
      url = "github:psyreactor/dms-githubNotifier/b1af35656f2ea6fac8d2b75e8fa54d62a1fc1fd5";
      flake = false;
    };

    # DankMaterialShell launcher plugin: run a shell command from the launcher
    # (trigger ">"). Plugin `id` is `commandRunner`. SHA-pinned; bump
    # deliberately.
    dms-command-runner = {
      url = "github:devnullvoid/dms-command-runner/5c2cab404335ceb96c60cf9e97a9682994209cd4";
      flake = false;
    };

    # DankMaterialShell launcher plugin: evaluate a math expression and copy the
    # result (trigger "="). Plugin `id` is `calculator`; declares
    # `requires_dms >= 1.4.0`, satisfied by the pinned DMS above. SHA-pinned.
    dms-calculator = {
      url = "github:rochacbruno/DankCalculator/1db5865419a40a33171a475855a59e0b8bf7187f";
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
      url = "github:AvengeMedia/dms-plugins/e8c36175a1a8ee4718df5d8ef60d105add94f33e";
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
      url = "github:AvengeMedia/danksearch/4b4905e2ef3454230fb648d2139f3139b742b0eb";
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

          update-checks-resolve-bats = pkgs.runCommand "update-checks-resolve-bats"
            { nativeBuildInputs = [ pkgs.bats pkgs.coreutils pkgs.jq ]; } ''
            cp -r ${./modules/desktop/update-checks} uc
            chmod -R u+w uc
            cd uc && bats tests/resolve-latest.bats
            touch $out
          '';

          update-checks-bump-bats = pkgs.runCommand "update-checks-bump-bats"
            { nativeBuildInputs = [ pkgs.bats pkgs.coreutils pkgs.gnugrep pkgs.gawk ]; } ''
            cp -r ${./modules/desktop/update-checks} uc
            chmod -R u+w uc
            cd uc && bats tests/bump-input.bats
            touch $out
          '';

          update-checks-notifier-bats = pkgs.runCommand "update-checks-notifier-bats"
            { nativeBuildInputs = [ pkgs.bats pkgs.coreutils pkgs.gnugrep pkgs.jq ]; } ''
            cp -r ${./modules/desktop/update-checks} uc
            chmod -R u+w uc
            cd uc && bats tests/notifier.bats
            touch $out
          '';
        };
    };
}

