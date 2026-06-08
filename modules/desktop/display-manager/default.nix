{ config, lib, pkgs, ... }:

let
  cfg = config.hyprflake.desktop.displayManager;
  kbd = config.hyprflake.desktop.keyboard;

  # The greeter runs its own throwaway Hyprland instance for the login screen.
  # Inject the keyboard layout so the password field matches the user's layout.
  # This is hyprlang config for the ephemeral greeter compositor only, consumed
  # via the greeter's `-C` flag. The project's Lua-only rule applies to the main
  # session config, not this disposable greeter config.
  #
  # kbd.layout/variant are emitted verbatim into this config. They are
  # build-time NixOS option strings set by the system builder (not runtime
  # user input), so this crosses no privilege boundary; keep them to xkb tokens.
  greeterKbConfig = ''
    input {
        kb_layout = ${kbd.layout}
    ${lib.optionalString (kbd.variant != "") "    kb_variant = ${kbd.variant}\n"}}
  '';
in
{
  # The DankGreeter NixOS module (programs.dank-material-shell.greeter.*) is
  # imported in modules/default.nix, where hyprflakeInputs is a direct argument.
  # Importing it here would recurse (hyprflakeInputs arrives via _module.args,
  # which is unavailable during imports resolution). This module only flips the
  # greeter options in config below.

  options.hyprflake.desktop.displayManager = {
    enable = lib.mkEnableOption "display manager. Note: also propagates keyboard layout from hyprflake.desktop.keyboard" // { default = true; };

    backend = lib.mkOption {
      type = lib.types.enum [ "gdm" "dms-greeter" ];
      default = "gdm";
      description = ''
        Which display manager to use.

        - "gdm": GNOME Display Manager (the historical default; carries the
          GDM 50 / gnome-session workarounds in docs/workarounds.md).
        - "dms-greeter": DankMaterialShell's greetd-based greeter, themed from
          the same Stylix-controlled DMS config as the shell.

        Both code paths stay in the tree, so switching back is a one-line flip
        plus rebuild. The keyring PAM unlock hook (modules/system/keyring)
        follows this selection.
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # ----- GDM backend -------------------------------------------------------
    (lib.mkIf (cfg.backend == "gdm") {
      services = {
        # GDM with Wayland (GNOME 50+ is Wayland-only; the wayland option was
        # removed upstream, so we no longer set it explicitly).
        displayManager = {
          gdm.enable = true;

          # Set Hyprland as default session
          defaultSession =
            if config.programs.hyprland.withUWSM or false
            then "hyprland-uwsm"
            else "hyprland";
        };

        # X server configuration for keymap (GDM greeter only).
        xserver = {
          enable = true;

          xkb = {
            inherit (kbd) layout variant;
          };

          excludePackages = [ pkgs.xterm ];
        };
      };

      # GDM 50's greeter Exec=gnome-session, but nixpkgs only adds gnome-session
      # to the display-manager service PATH — not the gdm-greeter user's PATH.
      # Without this, the greeter exits with "Unable to run session" and the
      # login screen is blank. Drop once nixpkgs grows the systemPackages entry.
      environment.systemPackages = [ pkgs.gnome-session ];

      # GDM 50's greeter session is gnome-session, which calls gsm_session_fill
      # → find_valid_session_keyfile to locate gnome-login.session. That walks
      # XDG_DATA_DIRS. nixpkgs adds ${sessionData.desktops}/share to system-wide
      # XDG_DATA_DIRS but NOT gdm or gnome-session — so the greeter can find
      # hyprland.desktop (wayland-sessions/) but not gnome-login.session
      # (gnome-session/sessions/). Result: greeter logs "Failed to fill session"
      # on every retry and the login screen is blank.
      environment.sessionVariables.XDG_DATA_DIRS = [
        "${pkgs.gdm}/share"
        "${pkgs.gnome-session}/share"
      ];
    })

    # ----- DankGreeter (dms-greeter) backend ---------------------------------
    (lib.mkIf (cfg.backend == "dms-greeter") {
      assertions = [
        {
          assertion = config.hyprflake.user.username != null;
          message = ''
            hyprflake.desktop.displayManager.backend = "dms-greeter" needs
            hyprflake.user.username set so the greeter can sync the user's DMS
            config (configHome). Set hyprflake.user.username = "<you>".
          '';
        }
        {
          # configHome reads users.users.<name>.home (an attrset the consumer
          # owns; the hyprflake.user module only declares the option). Guard the
          # lookup so an undeclared/typo'd username fails with guidance instead
          # of a bare "attribute '<name>' missing".
          assertion =
            config.hyprflake.user.username == null
            || builtins.hasAttr config.hyprflake.user.username config.users.users;
          message = ''
            hyprflake.desktop.displayManager.backend = "dms-greeter" reads the
            home of hyprflake.user.username (${toString config.hyprflake.user.username})
            from users.users, but that user is not declared. Declare
            users.users.${toString config.hyprflake.user.username} (the primary
            user) so the greeter can resolve its home directory.
          '';
        }
      ];

      # Auto-unlock at the greeter rides on the keyring module's greetd PAM
      # hook. If the keyring module is off, the greeter still works but the
      # login keyring will not unlock; warn rather than fail so a deliberate
      # external keyring setup is still allowed.
      warnings = lib.optional (!config.hyprflake.system.keyring.enable)
        ''hyprflake.desktop.displayManager.backend = "dms-greeter" with hyprflake.system.keyring disabled: the greeter login will not auto-unlock GNOME Keyring.'';

      # greetd-based DankGreeter. The session compositor (Hyprland) and its
      # wayland session are registered at the system level by the hyprland
      # module (programs.hyprland.enable), which the greeter requires.
      programs.dank-material-shell.greeter = {
        enable = true;
        compositor.name = "hyprland";

        # Inject the user's keyboard layout into the greeter's login compositor.
        compositor.customConfig = greeterKbConfig;

        # Copy the user's DMS config into the greeter so the login screen
        # inherits the Stylix-driven theme (DMS exports dms-colors.json). The
        # greeter copies these at greetd preStart into /var/lib/dms-greeter,
        # which is writable state, not the read-only store. Sourced from the
        # user's declared home so non-standard homes (impermanence, homed,
        # users.users.<name>.home overrides) still resolve correctly; a hardcoded
        # /home/<name> would silently miss and leave the greeter unthemed.
        configHome = config.users.users.${config.hyprflake.user.username}.home;
      };
    })
  ]);
}
