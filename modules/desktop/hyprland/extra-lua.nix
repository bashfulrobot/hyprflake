# hyprflake.hyprland.extraLua: typed replacement for the old conf.d runtime loader.
# Downstream modules (and hyprflake's own snappy-switcher) declare Lua snippets here
# instead of dropping files into ~/.config/hypr/conf.d.
{ config, lib, ... }:
let
  extraLua = config.hyprflake.hyprland.extraLua;
  # Mirror home-manager's name -> module-name mapping (`/` -> `.`,
  # drop a trailing `.lua`) so `require(...)` matches the written path.
  # lib.lessThan is the same comparator home-manager sorts with.
  luaModuleName = name: lib.replaceStrings [ "/" ] [ "." ] (lib.removeSuffix ".lua" name);
  moduleNames = lib.sort lib.lessThan (map luaModuleName (lib.attrNames extraLua));
in
{
  # The option is declared here, in the hyprland module's sharedModule.
  # Setters (snappy-switcher, downstream consumers) must therefore import
  # the hyprland module too; in practice every module ships as one bundle
  # via modules/default.nix, so the option is always present.
  options.hyprflake.hyprland.extraLua = lib.mkOption {
    type = with lib.types; attrsOf (either path lines);
    default = { };
    example = lib.literalExpression ''
      {
        "morgen-windowrule" = '''
          hl.window_rule({ name = "morgen-tile", match = { class = "^([Mm]orgen)$" }, tile = true })
        ''';
        "lib.helpers" = ./helpers.lua;
      }
    '';
    description = ''
      Additional Lua files loaded into the generated `hyprland.lua`
      (only effective with `configType = "lua"`). Each attribute name is
      a Lua module name written under `$XDG_CONFIG_HOME/hypr`; a dot in
      the name becomes a directory separator, so `lib.helpers` writes
      `lib/helpers.lua`. Values are either a path to a Lua file or an
      inline Lua string of `hl.*` calls.

      Files are written by home-manager's `extraLuaFiles` with
      `autoLoad = false`; hyprflake emits the `require(...)` calls at the
      end of `hyprland.lua`, so these modules load after the base config
      and win on bind, rule, and monitor conflicts. This replaces the
      removed `~/.config/hypr/conf.d/*.lua` runtime loader.
    '';
  };

  config = lib.mkIf (extraLua != { }) {
    # Attribute names become both a filesystem path (under
    # $XDG_CONFIG_HOME/hypr) and a Lua module name embedded verbatim in
    # the require() list below. Constrain them to a safe charset so a
    # name carrying a quote, backslash, or newline cannot break out of
    # the generated Lua string literal (it would fail the build here
    # instead). Slash and dot are allowed because they map to directory
    # separators in the written path.
    assertions = lib.mapAttrsToList
      (name: _: {
        assertion = builtins.match "[A-Za-z0-9._/-]+" name != null;
        message = ''
          hyprflake.hyprland.extraLua: attribute name "${name}" is invalid.
          Names become Lua module names and file paths, so they may only
          contain letters, digits, dot, underscore, slash, or hyphen.
        '';
      })
      extraLua;

    wayland.windowManager.hyprland.extraLuaFiles = lib.mapAttrs
      (_name: content: {
        inherit content;
        # hyprflake requires these at the end of extraConfig (below),
        # not at the top, to preserve load-last precedence.
        autoLoad = false;
      })
      extraLua;

    wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
      -- ===== hyprflake.hyprland.extraLua loader =====
      -- Files declared via hyprflake.hyprland.extraLua are written by
      -- home-manager (extraLuaFiles, autoLoad = false) and required here,
      -- at the end of the config, so they load last and win on
      -- bind/rule/monitor conflicts. pcall keeps one broken module from
      -- killing the whole config; the error lands in hyprland's log.
      -- Uses require() like home-manager's own autoLoad path (not the old
      -- dofile), so on `hyprctl reload` reload semantics match upstream's
      -- require model. Replaces the old conf.d glob.
      do
        -- Read XDG_CONFIG_HOME at runtime (with the build-time
        -- config.xdg.configHome as the fallback) to match home-manager's
        -- own autoLoad require path, which seeds package.path the same
        -- way and honors a relocated config dir. Setting this env in the
        -- running compositor already implies session code execution as
        -- the user, so it is not a new trust boundary.
        local xdg = os.getenv("XDG_CONFIG_HOME") or "${config.xdg.configHome}"
        package.path = xdg .. "/hypr/?.lua;" .. xdg .. "/hypr/?/init.lua;" .. package.path
        for _, name in ipairs({ ${lib.concatMapStringsSep ", " (n: "\"${n}\"") moduleNames} }) do
          local ok, err = pcall(require, name)
          if not ok then
            io.stderr:write(string.format("[hyprflake] error loading extraLua %s: %s\n", name, err))
          end
        end
      end
    '';
  };
}
