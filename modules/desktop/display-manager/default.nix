{ config, lib, ... }:

let
  cfg = config.hyprflake.desktop.displayManager;
  kbd = config.hyprflake.desktop.keyboard;
  username = config.hyprflake.user.username;

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
  # hyprflake's login manager is DankMaterialShell's greetd-based greeter. GDM
  # was removed in favour of it (DMS-first): the login screen and the shell now
  # share one Stylix-driven theme, and the GDM 50 / gnome-session workaround
  # stack is gone. Rollback is the backup/pre-dank-baseline branch or a previous
  # NixOS generation, not an in-tree toggle.
  #
  # The DankGreeter NixOS module (programs.dank-material-shell.greeter.*) is
  # imported in modules/default.nix, where hyprflakeInputs is a direct argument.
  # Importing it here would recurse (hyprflakeInputs arrives via _module.args,
  # which is unavailable during imports resolution). This module configures the
  # greeter in config below.

  options.hyprflake.desktop.displayManager.enable =
    lib.mkEnableOption "the DankGreeter (greetd) login manager; also propagates keyboard layout from hyprflake.desktop.keyboard to the greeter" // { default = true; };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = username != null;
        message = ''
          hyprflake.desktop.displayManager is enabled but
          hyprflake.user.username is unset. The DankGreeter needs it to sync the
          user's DMS config to the login screen (configHome). Set
          hyprflake.user.username = "<you>", or set displayManager.enable = false
          to run your own login manager.
        '';
      }
      {
        # configHome reads users.users.<name>.home (an attrset the consumer
        # owns; the hyprflake.user module only declares the option). Guard the
        # lookup so an undeclared/typo'd username fails with guidance instead of
        # a bare "attribute '<name>' missing".
        assertion = username == null || builtins.hasAttr username config.users.users;
        message = ''
          hyprflake.desktop.displayManager reads the home of
          hyprflake.user.username (${toString username}) from users.users, but
          that user is not declared. Declare users.users.${toString username}
          (the primary user) so the greeter can resolve its home directory.
        '';
      }
    ];

    # Auto-unlock at the greeter rides on the keyring module's greetd PAM hook.
    # If the keyring module is off, the greeter still works but the login keyring
    # will not unlock; warn rather than fail so a deliberate external keyring
    # setup is still allowed.
    warnings = lib.optional (!config.hyprflake.system.keyring.enable)
      ''hyprflake.desktop.displayManager is enabled with hyprflake.system.keyring disabled: the greeter login will not auto-unlock GNOME Keyring.'';

    # greetd-based DankGreeter. The session compositor (Hyprland) and its wayland
    # session are registered at the system level by the hyprland module
    # (programs.hyprland.enable), which the greeter requires.
    programs.dank-material-shell.greeter = {
      enable = true;
      compositor.name = "hyprland";

      # Inject the user's keyboard layout into the greeter's login compositor.
      compositor.customConfig = greeterKbConfig;

      # Copy the user's DMS config into the greeter so the login screen inherits
      # the Stylix-driven theme (DMS exports dms-colors.json). The greeter copies
      # these at greetd preStart into /var/lib/dms-greeter, which is writable
      # state, not the read-only store. Sourced from the user's declared home so
      # non-standard homes (impermanence, homed, users.users.<name>.home
      # overrides) still resolve correctly; a hardcoded /home/<name> would
      # silently miss and leave the greeter unthemed. Guarded on username so a
      # null value fails via the assertion above, not a string-coercion error.
      configHome = lib.mkIf (username != null) config.users.users.${username}.home;
    };
  };
}
