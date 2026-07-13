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

  # NIXPKGS_DMS controls the nixpkgs dms-shell version the curl stub reports.
  cat >"$TMP/bin/curl" <<EOF
#!/bin/sh
for a in "\$@"; do url="\$a"; done
case "\$url" in
  *dms-shell/package.nix*)
    printf '{"content":"%s"}' "\$(printf 'version = "%s";' "\${NIXPKGS_DMS:-1.5.0}" | base64 -w0)" ;;
  *DankMaterialShell*releases/latest*) printf '{"tag_name":"v1.5.0"}' ;;
  *HyprlandService.qml*) printf '{"content":""}' ;;
  *hyprland/package.nix*) printf '{"content":"%s"}' "\$(printf 'version = "0.50.0";' | base64 -w0)" ;;
  *dms-emoji-launcher*commits/HEAD*) printf '{"sha":"8ff394e"}' ;;
  *voxtype*releases/latest*) printf '{"tag_name":"v0.8.0"}' ;;
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
