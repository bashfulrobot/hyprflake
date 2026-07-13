setup() {
  TMP="$(mktemp -d)"; export TMP
  export XDG_STATE_HOME="$TMP/state"
  mkdir -p "$TMP/bin"

  # Bake the tokens the Nix build would substitute: pinned DMS 1.5.0.
  sed -e 's/@@DMS_VERSION@@/1.5.0/' \
      -e 's/@@HYPR_VERSION@@/0.50.0/' \
      -e 's/@@EMOJI_REV@@/8ff394e/' \
      -e 's/@@VOXTYPE_VERSION@@/0.8.0/' \
      "$BATS_TEST_DIRNAME/../hyprflake-updates.sh" >"$TMP/notifier.sh"

  # Each endpoint the stub answers is parameterized by an env var so a test can
  # make exactly one upstream look newer than the baked token and leave the rest
  # matching (silent). Defaults equal the baked tokens, so with no overrides the
  # only actionable message is the nixpkgs dms-shell one (driven by NIXPKGS_DMS).
  cat >"$TMP/bin/curl" <<EOF
#!/bin/sh
for a in "\$@"; do url="\$a"; done
case "\$url" in
  *dms-shell/package.nix*)
    printf '{"content":"%s"}' "\$(printf 'version = "%s";' "\${NIXPKGS_DMS:-1.5.0}" | base64 -w0)" ;;
  *DankMaterialShell*releases/latest*) printf '{"tag_name":"%s"}' "\${DMS_LATEST:-v1.5.0}" ;;
  *hyprland/package.nix*) printf '{"content":"%s"}' "\$(printf 'version = "%s";' "\${HYPR_LATEST:-0.50.0}" | base64 -w0)" ;;
  *dms-emoji-launcher*commits/HEAD*) printf '{"sha":"%s"}' "\${EMOJI_HEAD:-8ff394e}" ;;
  *voxtype*releases/latest*) printf '{"tag_name":"%s"}' "\${VOX_LATEST:-v0.8.0}" ;;
  *) printf '{}' ;;
esac
EOF
  chmod +x "$TMP/bin/curl"
  export PATH="$TMP/bin:$PATH"
}
teardown() { rm -rf "$TMP"; }

@test "fires 'drop the override' when nixpkgs dms-shell >= pinned" {
  NIXPKGS_DMS=1.5.0 run bash "$TMP/notifier.sh" --oneline
  [ "$status" -eq 0 ]
  grep -q 'pkgs.dms-shell' "$XDG_STATE_HOME/hyprflake/updates.txt"
}

@test "silent when nixpkgs dms-shell still behind pinned" {
  NIXPKGS_DMS=1.4.6 run bash "$TMP/notifier.sh" --oneline
  [ "$status" -eq 0 ]
  ! grep -q 'pkgs.dms-shell' "$XDG_STATE_HOME/hyprflake/updates.txt" 2>/dev/null || false
}

@test "does not emit the old unconditional 'drop the master pin' text" {
  NIXPKGS_DMS=1.5.0 run bash "$TMP/notifier.sh"
  ! printf '%s' "$output" | grep -q 'drop the hyprflake master pin'
}

@test "DMS release message names 'just bump dank-material-shell'" {
  NIXPKGS_DMS=1.4.6 DMS_LATEST=v1.6.0 run bash "$TMP/notifier.sh"
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -q 'just bump dank-material-shell'
}

@test "Hyprland message names 'just update-input nixpkgs'" {
  NIXPKGS_DMS=1.4.6 HYPR_LATEST=0.99.0 run bash "$TMP/notifier.sh"
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -q 'just update-input nixpkgs'
}

@test "emoji message names 'just bump dms-emoji-launcher'" {
  NIXPKGS_DMS=1.4.6 EMOJI_HEAD=deadbeefdeadbeef run bash "$TMP/notifier.sh"
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -q 'just bump dms-emoji-launcher'
}

@test "Voxtype message names 'just update-input voxtype'" {
  NIXPKGS_DMS=1.4.6 VOX_LATEST=v0.9.0 run bash "$TMP/notifier.sh"
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -q 'just update-input voxtype'
}
