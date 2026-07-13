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
  # notifier stays silent.
  cat >"$TMP/bin/curl" <<EOF
#!/bin/sh
for a in "\$@"; do url="\$a"; done
case "\$url" in
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

@test "silent when everything matches the built versions" {
  run bash "$TMP/notifier.sh" --oneline
  [ "$status" -eq 0 ]
  [ ! -s "$XDG_STATE_HOME/hyprflake/updates.txt" ]
}

@test "does not emit the old unconditional 'drop the master pin' text" {
  run bash "$TMP/notifier.sh"
  ! printf '%s' "$output" | grep -q 'drop the hyprflake master pin'
}

@test "DMS release message names 'just bump dank-material-shell'" {
  DMS_LATEST=v1.6.0 run bash "$TMP/notifier.sh"
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -q 'just bump dank-material-shell'
}

@test "Hyprland message names 'just update-input nixpkgs'" {
  HYPR_LATEST=0.99.0 run bash "$TMP/notifier.sh"
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -q 'just update-input nixpkgs'
}

@test "emoji message names 'just bump dms-emoji-launcher'" {
  EMOJI_HEAD=deadbeefdeadbeef run bash "$TMP/notifier.sh"
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -q 'just bump dms-emoji-launcher'
}

@test "Voxtype message names 'just update-input voxtype'" {
  VOX_LATEST=v0.9.0 run bash "$TMP/notifier.sh"
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -q 'just update-input voxtype'
}
