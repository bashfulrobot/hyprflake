{ config, lib, pkgs, ... }:

# hyprctl-compat
#
# Hyprland's Lua config backend (0.55+) rewrites `hyprctl dispatch <X>`
# as a Lua eval of `hl.dispatch(<X>)`. Legacy hyprlang dispatch syntax
# (`workspace 1`, `dpms off`, `submap reset`, ...) becomes invalid Lua
# and the dispatch silently fails. Upstream rejected adding a
# backwards-compat shim (hyprwm/Hyprland#14255), so anything that
# shells out to `hyprctl dispatch ...` with legacy args is broken
# under Lua mode.
#
# This module installs a Python wrapper at `bin/hyprctl` (with
# `lib.hiPrio` so it shadows `pkgs.hyprland`'s binary in PATH). The
# wrapper translates a `dispatch` (or `--batch`-embedded dispatch)
# subcommand into the new lua form and execs the real hyprctl.
# Everything else passes through verbatim.
#
# Direct-IPC callers (DankMaterialShell via Quickshell, anything using
# hyprland-rs without a custom dispatch path) are NOT helped by this
# wrapper — they bypass the binary entirely. DMS solves it on its own
# side by emitting Lua-form `hl.dsp.*` dispatch; see docs/workarounds.md.
#
# Transition aid only. Remove this module once third-party tooling and
# user scripts have migrated to lua dispatch syntax.

let
  cfg = config.hyprflake.system.hyprctlCompat;

  wrapper = pkgs.runCommand "hyprctl-compat"
    {
      nativeBuildInputs = [ pkgs.makeWrapper ];
      src = ./hyprctl-compat.py;
    } ''
    mkdir -p $out/bin
    substitute $src $out/bin/hyprctl \
      --replace-fail "@hyprctl@" "${pkgs.hyprland}/bin/hyprctl"
    chmod +x $out/bin/hyprctl
    # Wrap so the embedded shebang resolves to a python3 in the closure.
    wrapProgram $out/bin/hyprctl \
      --prefix PATH : ${lib.makeBinPath [ pkgs.python3 ]}
  '';
in
{
  options.hyprflake.system.hyprctlCompat = {
    enable = lib.mkEnableOption "hyprctl wrapper that translates legacy dispatch syntax to lua" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    # hiPrio so this wrapper wins over pkgs.hyprland's hyprctl in
    # /run/current-system/sw/bin/ (priority 0 vs default 5).
    environment.systemPackages = [ (lib.hiPrio wrapper) ];
  };
}
