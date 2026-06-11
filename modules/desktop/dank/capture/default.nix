# modules/desktop/dank/capture/default.nix
#
# Pure builder for the DMS settings-capture feature. Given the rendered
# `effective` settings, the `base` settings (defaults + consumer Nix, the diff
# baseline), and the consumer's absolute `repoPath`, returns the packages to put
# on PATH and the activation command that seeds settings.json.
{ pkgs, lib, effective, base, repoPath }:
let
  jsonFmt = pkgs.formats.json { };
  effectiveFile = jsonFmt.generate "dank-effective.json" effective;
  baseFile = jsonFmt.generate "dank-base.json" base;

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
      [ "@repoPath@" "@effectiveFile@" ]
      [ repoPath "${effectiveFile}" ]
      text;

  # runtimeInputs of a writeShellApplication only populate that app's own PATH,
  # not its callers, so a CLI that shells out to bare `python3` must list it
  # itself. Only dank-capture does (its changed-keys summary); discard/diff get
  # python3 transitively through dank-settings-tool and need not carry it.
  mkCli = name: extraInputs: src: pkgs.writeShellApplication {
    inherit name;
    runtimeInputs = [ dankTool pkgs.coreutils ] ++ extraInputs;
    text = subst (builtins.readFile src);
  };

  dankCapture = mkCli "dank-capture" [ pkgs.python3 ] ./dank-capture.sh;
  dankDiscard = mkCli "dank-discard" [ ] ./dank-discard.sh;
  dankDiff = mkCli "dank-diff" [ ] ./dank-diff.sh;
in
{
  packages = [ dankTool dankSeed dankCapture dankDiscard dankDiff ];

  seedCommand = lib.concatStringsSep " " [
    "${dankSeed}/bin/dank-seed"
    "${effectiveFile}"
    "${baseFile}"
    ''"$HOME/.config/DankMaterialShell/settings.json"''
    ''"$HOME/.config/DankMaterialShell/.dank-defaults.json"''
    ''"$HOME/.local/state/DankMaterialShell/.dank-seed.sha256"''
  ];
}
