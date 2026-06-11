{ config, lib, pkgs, hyprflakeInputs, ... }:

let
  idle = config.hyprflake.desktop.idle;
  searchCfg = config.hyprflake.desktop.search;

  # Resolve a battery idle timeout: null means "track the AC value", any int
  # (including 0, which disables the step on battery) is used as-is. DMS gets a
  # concrete int either way. Extracted because the same fallback drives all
  # three battery timeouts below.
  batteryOr = batteryVal: acVal: if batteryVal != null then batteryVal else acVal;

  cfg = config.hyprflake.desktop.dank;
  jsonFmt = pkgs.formats.json { };

  # hyprflake's curated DMS defaults. Kept as a plain attrset here so it can
  # be emitted as a config definition with per-leaf mkDefault (see config
  # block) rather than as the option `default`, which is all-or-nothing.
  defaultSettings = {
    # Idle ladder. The AC settings read the hyprflake.desktop.idle
    # values; the battery settings read the battery* overrides, each
    # falling back to its AC counterpart when unset (batteryOr). Seconds;
    # 0 disables a given listener. DMS's DPMS step is *MonitorTimeout.
    acLockTimeout = idle.lockTimeout;
    batteryLockTimeout = batteryOr idle.batteryLockTimeout idle.lockTimeout;
    acMonitorTimeout = idle.dpmsTimeout;
    batteryMonitorTimeout = batteryOr idle.batteryDpmsTimeout idle.dpmsTimeout;
    acSuspendTimeout = idle.suspendTimeout;
    batterySuspendTimeout = batteryOr idle.batterySuspendTimeout idle.suspendTimeout;
    lockBeforeSuspend = true;
    loginctlLockIntegration = true;

    # Label each workspace pill in the bar with its Hyprland workspace
    # number (DMS default is icons/dots only).
    showWorkspaceIndex = true;

    # Bar layout. DMS reads barConfigs verbatim when present (its
    # migration only synthesises defaults when the key is absent —
    # SettingsStore.js), so we restate the default bar here and drop
    # the "weather" entry from the center section. Only the identity
    # and widget lists are pinned; every omitted styling field falls
    # back to its upstream `?? default` at the QML read site, so this
    # stays forward-compatible with DMS bar-styling changes.
    barConfigs = [
      {
        id = "default";
        name = "Main Bar";
        enabled = true;
        position = 0;
        screenPreferences = [ "all" ];
        showOnLastDisplay = true;

        # Clean, macOS-menu-bar look: drop the per-widget capsule
        # backgrounds. DMS draws a rounded BasePill behind every widget
        # by default; noBackground flips each pill's fill to transparent
        # and its radius to 0, so widgets render as plain text/icons.
        # The bar strip's own background (barConfig.transparency) is
        # independent and is left untouched.
        noBackground = true;

        # Nudge the panel text up a touch. Every bar widget sizes its
        # text via Theme.barTextSize(barThickness, fontScale, ...) =
        # round(12 * fontScale) at the default bar height, so 1.15
        # takes the ~12px default to 14px. Scales bar text only, not
        # popups/menus (those follow the global fontScale).
        fontScale = 1.15;

        # launcherButton (the app-launcher/menu button) dropped from
        # the leftmost position; left section starts at the workspaces.
        leftWidgets = [ "workspaceSwitcher" "focusedWindow" ];
        centerWidgets = [ "music" "clock" ];
        # Right cluster:
        # - battery: laptop-only. DMS has no separate power-profile
        #   widget — this widget IS the power-profile control (scroll to
        #   switch profiles, click for the battery/profile popout), so
        #   gating it on isLaptop drops both battery readout and the
        #   profile control on desktops. Its charge readout needs UPower,
        #   enabled alongside isLaptop in modules/system/power.
        # - idleInhibitor: click-toggle (coffee/motion icon) that blocks
        #   the idle/lock/DPMS ladder while active.
        # - privacyIndicator: macOS-style alert shown only while the mic,
        #   camera, or screen-share is active; invisible otherwise.
        # Both sit by the control-center button at the right end.
        # githubNotifier is the dms-github-notifier plugin widget,
        # resolved by its plugin id through PluginService; it sits at
        # the head of the right cluster next to the system tray.
        rightWidgets =
          [ "systemTray" "githubNotifier" "clipboard" "cpuUsage" "memUsage" "notificationButton" ]
          ++ lib.optional config.hyprflake.system.isLaptop "battery"
          ++ [ "idleInhibitor" "privacyIndicator" "controlCenterButton" ];
      }
    ];
  };

  effective = lib.recursiveUpdate cfg.settings cfg.capture.overrides;
  capture = import ./capture {
    inherit pkgs lib effective;
    base = cfg.settings;
    repoPath = cfg.capture.repoPath;
  };
in
{
  # DankMaterialShell desktop shell. Replaces the waybar stack (bar,
  # launcher, notifications, OSD, power menu) plus the lock screen and idle
  # daemon. Themed by the Stylix dank-material-shell target (enabled in
  # modules/desktop/stylix). Autostarts via its systemd user service.
  #
  # The shell is a core part of hyprflake and is always enabled — there is no
  # toggle. A toggle would only be warranted if hyprflake supported multiple
  # shells. The idle ladder it consumes (hyprflake.desktop.idle.*) is declared
  # in modules/system/power/idle.nix.

  # The shell itself is always-on, but the dsearch backend (below) gets a
  # toggle: unlike the shell, greeter, and switcher (UI surfaces the user is
  # looking at), it is a background daemon that walks the home directory and
  # holds fsnotify watches, so a consumer on a huge home or a constrained
  # laptop needs a first-class way to decline it. Defaults to on so the dank
  # ecosystem works out of the box.
  options = {
    hyprflake.desktop.search.enable =
      lib.mkEnableOption "the DankSearch (dsearch) indexed file-search backend for the DMS launcher" // { default = true; };

    hyprflake.desktop.dank.settings = lib.mkOption {
      inherit (jsonFmt) type;
      default = { };
      description = ''
        Effective DMS settings. hyprflake supplies curated defaults as a config
        definition with mkDefault on every leaf (see config block), so a
        consumer may override any individual key from pure Nix — including list
        fields like barConfigs, with no mkForce needed — while unset keys fall
        through. GUI captures (capture.overrides) merge on top last.
      '';
    };

    hyprflake.desktop.dank.capture = {
      enable = lib.mkEnableOption "GUI-editable, repo-backed DMS settings (writable settings.json + dank-capture round-trip)";

      group = lib.mkOption {
        type = lib.types.str;
        default = config.networking.hostName;
        defaultText = lib.literalExpression "config.networking.hostName";
        example = "workstations";
        description = ''
          Capture group identity. dank-capture reads and writes
          `<repoRoot>/<group>.json`, so every host sharing a group name shares
          one overrides file and a captured change propagates to the whole group
          on the next rebuild. The default — the hostname — isolates each host.
          Set the same value on several hosts to share a profile, or a custom
          name such as "laptops" to group a subset. Capture is last-write-wins
          (it writes the full delta, not a cross-host merge), so for a shared
          group use a tweak -> capture -> rebuild-everywhere flow rather than
          editing two GUIs independently.
        '';
      };

      repoRoot = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "/home/dustin/git/nixerator/dank-profiles";
        description = ''
          Absolute working-tree directory holding the per-group `<group>.json`
          files. dank-capture writes `<repoRoot>/<group>.json`. Required when
          capture.enable is true, unless repoPath is set directly.
        '';
      };

      overridesDir = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = lib.literalExpression "./dank-profiles";
        description = ''
          Nix path to the same directory as repoRoot, used to import the active
          group's overrides at eval time (typically a path literal like
          ./dank-profiles). When null, no overrides are imported and the group
          starts from hyprflake's defaults plus `settings`. The `<group>.json`
          file must be tracked in your flake's git tree to be visible.
        '';
      };

      repoPath = lib.mkOption {
        type = lib.types.str;
        default = if cfg.capture.repoRoot != "" then "${cfg.capture.repoRoot}/${cfg.capture.group}.json" else "";
        defaultText = lib.literalExpression ''"''${repoRoot}/''${group}.json"'';
        example = "/home/dustin/git/nixerator/dank-profiles/workstations.json";
        description = ''
          Absolute working-tree path where dank-capture writes the overrides
          delta. Defaults to `<repoRoot>/<group>.json`; set directly only to
          bypass the group/repoRoot convention. Required (directly or via
          repoRoot) when capture.enable is true.
        '';
      };

      overrides = lib.mkOption {
        inherit (jsonFmt) type;
        default =
          let
            d = cfg.capture.overridesDir;
            f = if d == null then null else d + "/${cfg.capture.group}.json";
          in
          if f != null && builtins.pathExists f then lib.importJSON f else { };
        defaultText = lib.literalExpression ''importJSON "''${overridesDir}/''${group}.json" when present, else { }'';
        description = ''
          GUI-captured override delta, merged last over settings. Defaults to the
          active group's file (`<overridesDir>/<group>.json`) imported at eval
          time when present. Set directly only to bypass the group convention.
        '';
      };
    };
  };

  config = {
    # hyprflake's curated DMS defaults. Emitted as a config definition with
    # mkDefault on every leaf (mapAttrsRecursive) rather than as the option
    # `default`: an option default is all-or-nothing (any consumer definition
    # replaces it wholesale), whereas per-leaf mkDefault lets a consumer
    # override individual keys (incl. barConfigs) from pure Nix while the rest
    # fall through, and lets capture.overrides layer on top.
    hyprflake.desktop.dank.settings = lib.mapAttrsRecursive (_: lib.mkDefault) defaultSettings;

    assertions = [
      {
        assertion = !cfg.capture.enable || (cfg.capture.repoPath != "" && lib.hasPrefix "/" cfg.capture.repoPath);
        message = "hyprflake.desktop.dank.capture.enable requires an ABSOLUTE working-tree write path: set capture.repoRoot (and optionally capture.group / capture.overridesDir), or set capture.repoPath directly. dank-capture resolves it at runtime, independent of CWD.";
      }
    ];

    # External-monitor brightness (DDC over I2C) needs the i2c-dev device.
    # Internal-panel brightness goes through logind and needs nothing extra.
    hardware.i2c.enable = true;

    home-manager.sharedModules = [
      hyprflakeInputs.dank-material-shell.homeModules.dank-material-shell
      # Bind `lib` from the home-manager module args so `lib.hm.dag` (the
      # home-manager-extended lib) resolves for home.activation; the bare
      # nixpkgs lib in the outer module scope has no `hm`. `config` stays
      # unbound here so it still refers to the NixOS config in the closure
      # (e.g. config.hyprflake.system.isLaptop below).
      ({ lib, ... }: {
        programs.dank-material-shell = {
          enable = true;

          # Shell built from the dank-material-shell flake input (DMS master /
          # 1.5-beta), not nixpkgs. nixpkgs' dms-shell (1.4.6) ships the
          # pre-Lua dispatch QML: HyprlandService.qml sends legacy
          # `dispatch workspace N` strings, which Hyprland's Lua config
          # evaluates as Lua and rejects, so clicking a workspace and picking
          # a window from the overview both silently fail. Master's
          # HyprlandService.qml emits `hl.dsp.*` Lua-form dispatch and fixes
          # it. The dispatch string is built in this shell package, so only it
          # needs to move; revert to pkgs.dms-shell once the fix is in a
          # tagged release. Quickshell stays on nixpkgs — the DMS flake no
          # longer ships it and points back at nixpkgs' build.
          package = hyprflakeInputs.dank-material-shell.packages.${pkgs.system}.dms-shell;

          # Add QtMultimedia to the quickshell runtime DMS launches. DMS gates
          # every system sound on AudioService.soundsAvailable, which resolves
          # to MultimediaService.available — a runtime probe that loads a QML
          # component importing QtMultimedia (Services/MultimediaProbe.qml).
          # nixpkgs' quickshell builds with qtbase/qtdeclarative/qtwayland/qtsvg
          # but not qtmultimedia, so wrapQtAppsHook never puts the QtMultimedia
          # QML module on the import path: the probe fails, soundsAvailable is
          # false, and DMS's already-enabled sounds (notification, volume,
          # plugged-in) never play. The session lock screen's video screensaver
          # (VideoScreensaverPlayer.qml) imports QtMultimedia too and was equally
          # dead before this.
          #
          # Override rather than fork to keep quickshell on nixpkgs per the
          # comment above. qt6.qtmultimedia uses its bundled ffmpeg backend on
          # NixOS, so the QML plugin and a working playback path land together.
          # Adding a buildInput changes quickshell's derivation, so this
          # recompiles quickshell instead of re-wrapping the cached build; the
          # result is published to cachix for the primary consumer. The
          # re-wrap alternative (hand-prepending qtmultimedia's qml/ and plugins/
          # dirs to the wrapper env) skips the recompile but reconstructs by hand
          # what wrapQtAppsHook already does and drops the package passthru, so
          # the override is the more maintainable call. The closure grows ~274MB
          # (measured) for qtmultimedia's media backends: ffmpeg is the default,
          # and the gstreamer plugin it also ships pulls gstreamer in too. The
          # playback path needs a backend either way.
          #
          # No eval-time guard is possible here: if a later nixpkgs bump changes
          # the qtmultimedia QML layout or DMS moves the probe, the build still
          # succeeds and sounds silently go quiet. Verify after a rebuild by
          # opening DMS Settings, Sounds (the "not available" warning is gone)
          # and confirming a notification and a volume change are audible. This
          # override does not reach the DankGreeter, which runs as a NixOS module
          # with its own stock quickshell and has no QtMultimedia surfaces.
          quickshell.package = pkgs.quickshell.overrideAttrs (old: {
            buildInputs = old.buildInputs ++ [ pkgs.qt6.qtmultimedia ];
          });

          # Autostart via the systemd user service (dms.service ->
          # `dms run --session`). Do NOT also exec-once from Hyprland.
          systemd.enable = true;

          # Stylix owns colors; turn off DMS's wallpaper-driven matugen so
          # the two color engines do not fight. Stylix's dank-material-shell
          # target (modules/desktop/stylix) pins currentThemeName="custom".
          enableDynamicTheming = false;

          # Backend for the bar cpuUsage/memUsage widgets: DMS reads metrics
          # from dgop, the dank-native monitor, added to the session as
          # pkgs.dgop (nixpkgs, no extra input). DMS-first: dgop over a
          # standalone tool. The DMS option already defaults to true; setting it
          # explicitly just keeps the backend pinned if that default flips.
          # Unlike the dsearch toggle above this needs none: dgop is an
          # on-demand CLI, no daemon, watches, or on-disk index.
          enableSystemMonitoring = true;

          # Write DankMaterialShell/plugin_settings.json. DMS only loads a
          # non-`desktop` plugin when getPluginSetting(id, "enabled", false)
          # is true (PluginService.qml `_onManifestParsed`), and that value
          # comes from plugin_settings.json. The DMS home module writes that
          # file only when managePluginSettings is set; its default
          # (hasPluginSettings) is false unless some plugin carries a non-empty
          # `settings` attr, which none of ours do. Without this the plugins
          # below symlink into place but never load: they sit dormant until
          # toggled by hand in the DMS Settings UI. Forcing it on emits
          # `{ <id> = { enabled = true; }; }` for every plugin here. The file
          # is a read-only store symlink, consistent with settings.json above;
          # plugins are managed declaratively, not toggled at runtime.
          managePluginSettings = true;

          # DMS launcher/widget/daemon plugins. Each attr name MUST equal the
          # plugin's own `id` (from its plugin.json): the DMS home module links
          # the src tree to ~/.config/DankMaterialShell/plugins/<attr>, and DMS
          # loads it by id (launcher triggers, bar widget components, daemon
          # services all key off the id). All sources are SHA-pinned flake
          # inputs, not installed at runtime.
          plugins = {
            # Emoji + unicode picker (trigger ":e" in spotlight). Replaces the
            # dropped rofimoji. SUPER+. opens spotlight pre-filled.
            emojiLauncher = {
              enable = true;
              src = hyprflakeInputs.dms-emoji-launcher;
            };

            # Bar widget: open PRs you authored and issues assigned to you,
            # polled from GitHub via the `gh` CLI every 60s. Added to the bar's
            # right cluster below. `gh` is put on the session PATH alongside
            # this module (home.packages); the widget still needs an
            # authenticated `gh` session (gh auth login) to show data, and
            # renders empty without one rather than breaking the bar.
            githubNotifier = {
              enable = true;
              src = hyprflakeInputs.dms-github-notifier;
            };

            # Launcher: run an arbitrary shell command from spotlight (trigger
            # ">"). This is a deliberate exposure decision, not a neutral
            # default: once loaded it runs whatever is typed with no further
            # prompt. DMS does not gate plugin process execution on the
            # `process` permission. The only permission it checks is
            # settings_write, and only to decide whether a plugin may persist
            # its own settings (PluginSettings.qml), not to gate code. There is
            # no consent prompt either, so marking a plugin enabled below is the
            # entire authorization decision, which is why the pins must be
            # reviewed as code on every bump. Acceptable here because this is a
            # single-user workstation and the launcher already starts arbitrary
            # apps; called out so a later reader does not assume it slipped in
            # unreviewed.
            commandRunner = {
              enable = true;
              src = hyprflakeInputs.dms-command-runner;
            };

            # Launcher: evaluate a math expression and copy the result
            # (trigger "=").
            calculator = {
              enable = true;
              src = hyprflakeInputs.dms-calculator;
            };

            # Daemon: run user scripts on system events (wallpaper/theme change,
            # battery thresholds, and so on). It executes configured scripts
            # even though its manifest declares no `process` permission (DMS
            # does not enforce permissions, see commandRunner above), so do not
            # trust the manifest's permission list when auditing what a plugin
            # can do. Inert with no hooks configured (every hook defaults to ""
            # and execution is guarded on non-empty), and none are set here.
            dankHooks = {
              enable = true;
              src = "${hyprflakeInputs.dms-plugins}/DankHooks";
            };
          }
          # Daemon: low-battery warning/critical notifications. It reads UPower
          # and only does anything on a host with a battery, so gate it on
          # isLaptop the same way the `battery` bar widget below is gated,
          # rather than installing a no-op daemon on desktops.
          // lib.optionalAttrs config.hyprflake.system.isLaptop {
            dankBatteryAlerts = {
              enable = true;
              src = "${hyprflakeInputs.dms-plugins}/DankBatteryAlerts";
            };
          };

          # When capture is OFF, write the effective settings as today's
          # read-only symlink. When ON, leave it empty so the DMS module skips
          # the symlink; the activation script below seeds a writable file.
          settings = lib.mkIf (!cfg.capture.enable) effective;
        };

        # The githubNotifier bar widget shells out to `gh` (gh auth status,
        # gh search prs/issues), defaulting to the bare `gh` on PATH. hyprflake
        # is a module library, so do not assume the consumer happens to ship
        # the GitHub CLI; provide it alongside the plugin that needs it.
        home.packages =
          [ pkgs.gh ]
          ++ lib.optionals cfg.capture.enable capture.packages;

        home.activation = lib.mkIf cfg.capture.enable {
          # Order after linkGeneration as well as writeBoundary: enabling capture
          # makes the DMS module stop managing settings.json, so on that first
          # rebuild linkGeneration removes the old read-only symlink. If the seed
          # ran before that removal it would see the stale symlink, hit the
          # guard's mismatch branch (no marker yet), preserve it, and then
          # linkGeneration would delete it — leaving no settings.json. Seeding
          # after the link step guarantees a clean absent->seed on the transition.
          dankSeedSettings = lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" ] capture.seedCommand;
        };
      })

      # DankSearch (dsearch): the dank-native indexed file-search backend the
      # DMS launcher auto-detects. DMS runs `command -v dsearch` and, when
      # present, execs `dsearch search --json` for launcher file search
      # (quickshell/Services/DSearchService.qml); without it the launcher shows
      # "File search requires dsearch". Enabling the module puts `dsearch` on
      # PATH and runs `dsearch serve` as a user service, so no DMS setting
      # selects the backend, it is detected (DMS-first: prefer the dank-native
      # search server over a standalone indexer). Gated on
      # hyprflake.desktop.search.enable (default true); set it false and the
      # launcher falls back to its built-in path walk. The module is imported
      # unconditionally because it is inert when programs.dsearch.enable is
      # false.
      hyprflakeInputs.danksearch.homeModules.default
      (_: {
        programs.dsearch = {
          inherit (searchCfg) enable;

          # Declarative config so dsearch does not write its own default
          # config.toml at first run (the home-manager module only writes the
          # file when `config != null`). index_path is left unset so it defaults
          # to XDG_CACHE_HOME/danksearch (writable state, never the Nix store);
          # only the user's home is indexed (system paths are out of scope).
          # `~` is expanded by dsearch at runtime, so this stays portable across
          # homes (impermanence, non-standard home dirs).
          #
          # Scope notes: index_all_files defaults to true upstream and is left
          # so, meaning every filename under the tree is indexed for name
          # search; text_extensions only governs which files have their
          # *contents* read for full-text search, it does not narrow the index.
          # exclude_hidden = true skips dotdirs, so ~/.config and other dotfiles
          # are not indexed; on NixOS those are mostly read-only store symlinks
          # managed declaratively, so the loss is small. merge_default_exclude_dirs
          # folds in the upstream skip list (.git, node_modules, target, caches).
          config = {
            index_paths = [
              {
                path = "~";
                max_depth = 6;
                exclude_hidden = true;
                merge_default_exclude_dirs = true;
              }
            ];
            text_extensions = [
              ".txt"
              ".md"
              ".org"
              ".nix"
              ".go"
              ".py"
              ".js"
              ".ts"
              ".jsx"
              ".tsx"
              ".json"
              ".yaml"
              ".yml"
              ".toml"
              ".html"
              ".css"
              ".scss"
              ".rs"
              ".c"
              ".cpp"
              ".h"
              ".hpp"
              ".java"
              ".kt"
              ".rb"
              ".php"
              ".sh"
              ".fish"
              ".lua"
            ];
          };
        };

        # Run the daemon socket-only and harden it. `dsearch serve` by default
        # also starts an UNAUTHENTICATED HTTP API on 127.0.0.1:43654: loopback,
        # so not reachable off-host, but readable by any other local user, who
        # could then query this user's indexed filenames and indexed file
        # contents. DMS never uses that port; the `dsearch` CLI it execs dials
        # the unix socket under XDG_RUNTIME_DIR (`/run/user/<uid>`, mode 0700,
        # owner-only), so `--socket` drops the HTTP listener with no functional
        # loss. The whole contribution is wrapped in mkIf (not just the leaf) so
        # the toggle-off case defines no phantom dsearch unit.
        systemd.user.services = lib.mkIf searchCfg.enable {
          dsearch.Service = {
            ExecStart = lib.mkForce "${lib.getExe hyprflakeInputs.danksearch.packages.${pkgs.system}.dsearch} serve --socket";

            # Defense in depth: the daemon continuously parses untrusted file
            # contents (text bodies, image EXIF) under the fsnotify watch, so
            # shrink the kernel attack surface. Filesystem access is left wide
            # (it must read all of $HOME and write the index under ~/.cache), and
            # the riskier syscall/address-family filters are deferred until the
            # service can be exercised live on nixerator.
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectKernelLogs = true;
            ProtectControlGroups = true;
            ProtectHostname = true;
            ProtectClock = true;
            RestrictSUIDSGID = true;
            RestrictRealtime = true;
            RestrictNamespaces = true;
            LockPersonality = true;
            SystemCallArchitectures = "native";

            # The Bleve index lives at XDG_CACHE_HOME/danksearch/index and is
            # created with the process umask (commonly 0755 dirs / 0644 files),
            # so on a permissive ~/.cache another local user could read indexed
            # filenames and text bodies straight off disk, undercutting the
            # socket-only daemon. Have systemd own the `danksearch` cache dir and
            # force it to 0700; the 0700 parent blocks other-user traversal into
            # the index regardless of the inner files' mode. The daemon's default
            # index path resolves to this same dir.
            CacheDirectory = "danksearch";
            CacheDirectoryMode = "0700";
          };
        };
      })
    ];
  };
}
