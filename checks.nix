# Flake checks. Imported from flake.nix as `checks.x86_64-linux`.
#
# `eval-nixos` is the guard that matters most: it builds a minimal NixOS system
# with `nixosModules.default` plus home-manager and forces the toplevel
# derivation path, so an option rename or removed upstream attribute (the DMS
# 2.x class of break) fails here instead of on the next rebuild. The lint
# checks mirror `just health`, so `nix flake check` is the single gate.
{ self, nixpkgs, home-manager }:

let
  system = "x86_64-linux";
  pkgs = nixpkgs.legacyPackages.${system};

  evalHost = nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      home-manager.nixosModules.home-manager
      self.nixosModules.default
      {
        nixpkgs.config.allowUnfree = true;
        system.stateVersion = "25.11";
        boot.loader.grub.enable = false;
        fileSystems."/" = { device = "none"; fsType = "tmpfs"; };
        hyprflake.user.username = "check";
        users.users.check.isNormalUser = true;
        home-manager.users.check.home.stateVersion = "25.11";
      }
    ];
  };

  # Copy a module dir into the sandbox and run a test command from inside it.
  suite = name: src: tools: cmd:
    pkgs.runCommand name { nativeBuildInputs = tools; } ''
      cp -r ${src} work
      chmod -R u+w work
      cd work && ${cmd}
      touch $out
    '';
in
{
  # Evaluates the full module set (NixOS + home-manager) and forces the
  # toplevel derivation path. No build happens, so this stays fast.
  eval-nixos = pkgs.runCommand "eval-nixos"
    { drvPath = builtins.unsafeDiscardStringContext evalHost.config.system.build.toplevel.drvPath; }
    ''
      echo "$drvPath" > $out
    '';

  statix = suite "statix" self [ pkgs.statix ] "statix check .";

  deadnix = suite "deadnix" self [ pkgs.deadnix ] "deadnix --fail .";

  shellcheck = suite "shellcheck" self [ pkgs.shellcheck pkgs.findutils ]
    "find . -name '*.sh' -print0 | xargs -0 shellcheck -x";

  dank-diff-pytest = suite "dank-diff-pytest" ./modules/desktop/dank/capture
    [ pkgs.python3 pkgs.python3Packages.pytest ]
    "python3 -m pytest tests/test_diff.py -q";

  dank-seed-bats = suite "dank-seed-bats" ./modules/desktop/dank/capture
    [ pkgs.bats pkgs.coreutils ] "bats tests/seed.bats";

  claudoist-top-bats = suite "claudoist-top-bats" ./modules/desktop/dank/plugins/claudoist
    [ pkgs.bats pkgs.bash pkgs.coreutils pkgs.jq pkgs.python3 ]
    "bats tests/claudoist-top.bats";

  update-checks-resolve-bats = suite "update-checks-resolve-bats" ./modules/desktop/update-checks
    [ pkgs.bats pkgs.coreutils pkgs.jq ] "bats tests/resolve-latest.bats";

  update-checks-bump-bats = suite "update-checks-bump-bats" ./modules/desktop/update-checks
    [ pkgs.bats pkgs.coreutils pkgs.gnugrep pkgs.gawk ] "bats tests/bump-input.bats";

  update-checks-notifier-bats = suite "update-checks-notifier-bats" ./modules/desktop/update-checks
    [ pkgs.bats pkgs.coreutils pkgs.gnugrep pkgs.jq ] "bats tests/notifier.bats";
}
