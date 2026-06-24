{ config, lib, pkgs, ... }:

let
  kbd = config.hyprflake.desktop.keyboard;
  username = config.hyprflake.user.username;

  # The greeter copies the primary user's DMS config (theme, wallpaper) and
  # resolves their avatar from users.users.<name>.home. Both need a username
  # that is actually declared as a system user. Resolve that once; when it does
  # not hold the greeter still logs in, just with the default theme and no
  # avatar, so this degrades to a warning rather than a build failure.
  # The `username != null` disjunct is load-bearing: builtins.hasAttr throws on
  # a null name, so it has to short-circuit before the lookup.
  userDeclared = username != null && builtins.hasAttr username config.users.users;

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

    misc {
        # The greeter runs a throwaway Hyprland to host the login UI. For the
        # instant between that compositor coming up and the quickshell greeter
        # painting the Stylix wallpaper over it, Hyprland would otherwise show
        # its bundled default wallpaper (the share/hypr/wall*.png anime set),
        # logo, and splash text line. Suppress all three so that gap is a plain
        # background instead of a flash of an unrelated image and a stray phrase.
        # Mirrors the session compositor config in modules/desktop/hyprland.
        force_default_wallpaper = 0
        disable_hyprland_logo = true
        disable_splash_rendering = true
    }
  '';

  # A single Hyprland wayland-session entry that always launches via UWSM.
  #
  # The hyprland package ships two entries: the plain `hyprland.desktop`
  # (Exec=start-hyprland, no UWSM) and `hyprland-uwsm.desktop`. The plain one
  # bypasses UWSM, so `graphical-session.target` never activates and every
  # WantedBy= user service (dms, hyprpaper, hyprpolkitagent, voxtype, ...)
  # silently never starts — a bare compositor with no shell. The DankGreeter
  # session picker (quickshell GreeterContent.qml) scans the system
  # wayland-sessions dir, parses ONLY Name=/Exec= (it ignores NoDisplay=), and
  # with session memory off defaults to the FIRST entry it loads — which locale
  # collation orders as `hyprland.desktop`. So "just log in, no pick" lands on
  # the non-UWSM session. This is the known nixpkgs#484328 class of bug;
  # services.displayManager.defaultSession does not help here, and an empty
  # Name= would hide the entry from the greeter but UWSM rejects a Name-less
  # entry ("Key 'Name' is missing").
  #
  # Fix: launch via UWSM's executable form (`uwsm start ... Hyprland`) instead
  # of having the UWSM entry reference a desktop file, then shadow BOTH session
  # files with this identical entry. Same Name= → the greeter de-dupes to one
  # "Hyprland", and because both Execs route through UWSM there is no non-UWSM
  # session left to land on. The executable form drops the desktop-file
  # self-reference, so no hyprland rebuild is needed; the absolute uwsm path
  # mirrors nixpkgs#508309. hiPrio wins the system.path collision against the
  # hyprland package's own entries.
  uwsmHyprlandDesktop = pkgs.writeText "hyprland.desktop" ''
    [Desktop Entry]
    Name=Hyprland
    Comment=An intelligent dynamic tiling Wayland compositor
    Exec=${pkgs.uwsm}/bin/uwsm start -e -D Hyprland Hyprland
    TryExec=${pkgs.uwsm}/bin/uwsm
    Type=Application
    DesktopNames=Hyprland
    Keywords=tiling;wayland;compositor;
  '';
  uwsmOnlyHyprlandSessions = lib.hiPrio (
    pkgs.runCommandLocal "hyprland-uwsm-only-sessions" { } ''
      mkdir -p "$out/share/wayland-sessions"
      cp ${uwsmHyprlandDesktop} "$out/share/wayland-sessions/hyprland.desktop"
      cp ${uwsmHyprlandDesktop} "$out/share/wayland-sessions/hyprland-uwsm.desktop"
    ''
  );
in
{
  # hyprflake's login manager is DankMaterialShell's greetd-based greeter. GDM
  # was removed in favour of it (DMS-first): the login screen and the shell now
  # share one Stylix-driven theme, and the GDM 50 / gnome-session workaround
  # stack is gone. Rollback is the backup/pre-dank-baseline branch or a previous
  # NixOS generation, not an in-tree toggle.
  #
  # There is no enable option. A login manager is core infrastructure (like the
  # DMS shell itself): always needed, always present. A toggle would only be
  # warranted if hyprflake supported more than one. To run a different login
  # manager, override services.greetd / programs.dank-material-shell.greeter
  # directly, the way any other always-on component is replaced.
  #
  # The DankGreeter NixOS module (programs.dank-material-shell.greeter.*) is
  # imported in modules/default.nix, where hyprflakeInputs is a direct argument.
  # Importing it here would recurse (hyprflakeInputs arrives via _module.args,
  # which is unavailable during imports resolution). This module configures the
  # greeter in config below.

  imports = [
    # The greeter used to live behind hyprflake.desktop.displayManager.enable.
    # That option is gone (the login manager is core, always-on), so give
    # consumers a clear eval error instead of the bare "option does not exist".
    # mkRemovedOptionModule throws whenever the option is still set, with either
    # value: `= true` was a no-op (already the behaviour), and `= false` asked
    # for no DM, which can no longer be honoured, so both should fail loudly and
    # point at the fix.
    (lib.mkRemovedOptionModule [ "hyprflake" "desktop" "displayManager" "enable" ] ''
      hyprflake.desktop.displayManager.enable has been removed. The DankGreeter
      (greetd) login manager is now core infrastructure, always enabled, like the
      DankMaterialShell shell itself. Drop this option from your configuration. To
      run a different login manager, override services.greetd or
      programs.dank-material-shell.greeter directly. To roll back to GDM, use the
      backup/pre-dank-baseline branch or boot a previous NixOS generation.
    '')
  ];

  config = {
    # kbd.layout/variant are interpolated verbatim into the greeter's hyprlang
    # compositor config (greeterKbConfig). They are build-time NixOS options set
    # by the system builder, not runtime user input, so this is defence in depth
    # rather than a live attacker path: constrain them to xkb tokens (letters,
    # digits, comma for multi-layout, underscore, hyphen) so a stray newline or
    # brace can never inject a compositor directive even if these options later
    # move to a less-trusted source.
    assertions = [
      {
        assertion = builtins.match "[a-zA-Z0-9,_-]*" kbd.layout != null;
        message = "hyprflake.desktop.keyboard.layout must be xkb tokens ([a-zA-Z0-9,_-]); got ${builtins.toJSON kbd.layout}.";
      }
      {
        assertion = builtins.match "[a-zA-Z0-9,_-]*" kbd.variant != null;
        message = "hyprflake.desktop.keyboard.variant must be xkb tokens ([a-zA-Z0-9,_-]) or empty; got ${builtins.toJSON kbd.variant}.";
      }
    ];

    # Auto-unlock at the greeter rides on the keyring module's greetd PAM hook.
    # If the keyring module is off, the greeter still works but the login keyring
    # will not unlock; warn rather than fail so a deliberate external keyring
    # setup is still allowed. A second warning covers the theming/avatar path:
    # without a declared primary user the greeter cannot find that user's DMS
    # config or face icon, so it falls back to the default look.
    warnings =
      (lib.optional (!config.hyprflake.system.keyring.enable)
        ''hyprflake.system.keyring is disabled, so the DankGreeter login will not auto-unlock GNOME Keyring through the greetd PAM hook. If you manage a keyring elsewhere this is expected; otherwise enable hyprflake.system.keyring.'')
      ++ (lib.optional (!userDeclared)
        ''hyprflake.user.username is unset or names a user not declared in users.users; the DankGreeter login screen will use the default theme and no avatar instead of the primary user's Stylix DMS theme and photo. Set hyprflake.user.username to your declared primary user to theme the greeter.'');

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
      # silently miss and leave the greeter unthemed. Guarded on a declared user
      # so a null or typo'd username degrades to the default theme (and the
      # warning above) instead of a string-coercion or missing-attr eval error.
      configHome = lib.mkIf userDeclared config.users.users.${username}.home;
    };

    # Provide a single, always-UWSM Hyprland session to the greeter. Both
    # wayland-session files are shadowed (see uwsmOnlyHyprlandSessions above) so
    # every "Hyprland" the DankGreeter picker can show — and the one it defaults
    # to with no pick — launches via UWSM, activating graphical-session.target
    # and the user services that hang off it (dms, hyprpaper, voxtype, ...).
    environment.systemPackages = [ uwsmOnlyHyprlandSessions ];

    # Belt-and-suspenders: stop DankGreeter from remembering and replaying a
    # last-selected session. It records the last session in
    # /var/lib/dms-greeter/.local/state/memory.json (rememberLastSession defaults
    # true). With the shadow above every entry is UWSM, so this no longer matters
    # for correctness; disabling it just keeps the picker stateless. greetd
    # propagates its service environment to the greeter (same mechanism as the
    # TZDIR/LOCALE_ARCHIVE it already sets), and this env var takes precedence
    # over the greeter's settings.json. Last-USER memory is a separate flag
    # (DMS_GREET_REMEMBER_LAST_USER) and is unaffected. See docs/uwsm-session.md.
    systemd.services.greetd.environment.DMS_GREET_REMEMBER_LAST_SESSION = "false";
  };
}
