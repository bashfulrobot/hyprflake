# modules/desktop/dank/capture/default.nix
#
# Pure builder for the DMS settings-capture feature (full-file model). Given the
# Nix-rendered `mergedBase` (hyprflake defaults + stylix theme for this host),
# the captured `overrides` (the committed profile, theme-stripped), the
# `stylixKeys` to strip on capture, and the consumer's absolute `repoPath`,
# returns the packages to put on PATH and the activation command that seeds a
# writable, complete settings.json.
{ pkgs, lib, mergedBase, overrides, stylixKeys, repoPath }:
let
  jsonFmt = pkgs.formats.json { };
  mergedBaseFile = jsonFmt.generate "dank-merged-base.json" mergedBase;
  overridesFile = jsonFmt.generate "dank-overrides.json" overrides;
  stylixKeysFile = jsonFmt.generate "dank-stylix-keys.json" stylixKeys;

  dankTool = pkgs.writeShellApplication {
    name = "dank-settings-tool";
    runtimeInputs = [ pkgs.python3 ];
    text = ''exec python3 ${./diff.py} "$@"'';
  };

  dankSeed = pkgs.writeShellApplication {
    name = "dank-seed";
    runtimeInputs = [ dankTool pkgs.coreutils ];
    text = builtins.readFile ./seed.sh;
  };

  subst = text:
    builtins.replaceStrings
      [ "@repoPath@" "@stylixKeysFile@" "@mergedBaseFile@" "@overridesFile@" ]
      [ repoPath "${stylixKeysFile}" "${mergedBaseFile}" "${overridesFile}" ]
      text;

  # The user-facing CLIs. Each gets dank-settings-tool (which carries python3)
  # and coreutils; none shell out to bare python3 directly anymore.
  mkCli = name: src: pkgs.writeShellApplication {
    inherit name;
    runtimeInputs = [ dankTool pkgs.coreutils ];
    text = subst (builtins.readFile src);
  };

  dankCapture = mkCli "dank-capture" ./dank-capture.sh;
  dankDiscard = mkCli "dank-discard" ./dank-discard.sh;
  dankDiff = mkCli "dank-diff" ./dank-diff.sh;
in
{
  packages = [ dankTool dankSeed dankCapture dankDiscard dankDiff ];

  seedCommand = lib.concatStringsSep " " [
    "${dankSeed}/bin/dank-seed"
    "${mergedBaseFile}"
    "${overridesFile}"
    ''"$HOME/.config/DankMaterialShell/settings.json"''
    ''"$HOME/.local/state/DankMaterialShell/.dank-seed.sha256"''
  ];
}
