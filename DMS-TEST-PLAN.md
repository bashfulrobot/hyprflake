# DankMaterialShell runtime test plan (Task 10)

Walk this after `sudo nixos-rebuild switch --flake .#<host>` on the branch pin.
Each item: **do** the action, check the **expected** result, tick the box.
Items marked **(laptop)** only apply to a battery/backlight machine
(donkeykong); skip on the desktop (qbert).

Idle timers below are the defaults (nixerator sets no override): lock at
**5 min**, displays off at **6 min**, suspend at **10 min**.

---

## 0. First boot sanity

- [ ] Session logs in to Hyprland without dropping to a TTY or a black screen.
- [ ] `systemctl --user status dms.service` shows **active (running)**.
- [ ] The DMS bar is visible (top or bottom edge), not waybar.
- [ ] `pgrep -a dms` and `pgrep -a quickshell` each return a process.
- [ ] No waybar/swaync/swayosd/hyprpaper processes linger:
      `pgrep -a 'waybar|swaync|swayosd|hyprpaper'` returns nothing.

If `dms.service` failed: `journalctl --user -u dms.service -b --no-pager | tail -50`.

---

## 1. Shell surfaces (keybinds)

`SUPER` is the mod key.

- [ ] **SUPER+Space** — app launcher (spotlight) opens; typing filters; Enter launches.
- [ ] **SUPER+N** — notification center toggles open/closed.
- [ ] **SUPER+P** — power menu opens (lock / logout / suspend / reboot / shutdown).
- [ ] **SUPER+C** — clipboard history opens and shows recent copies.
- [ ] **SUPER+I** — control center opens; **a network/Wi-Fi section is present**
      and lists networks. (This is the one IPC target not verified headless;
      if it opens to the wrong pane, note which pane it lands on.)
- [ ] **Bluetooth** — the control center has a Bluetooth section that can
      **scan, pair, and connect** a device (needs a pairing agent, not just an
      on/off toggle). If pairing works here, `blueman` can be removed from
      `hyprland/default.nix` (see the spec's post-merge cleanup). If there is no
      working pair/agent flow, keep `blueman` and launch `blueman-manager`.
- [ ] **SUPER+RETURN** and **SUPER+T** — both open the terminal (kitty).
- [ ] **SUPER+E** — Nautilus opens.
- [ ] **SUPER+B** — default browser opens.
- [ ] **SUPER+L** — screen locks immediately (DMS locker, not hyprlock).
      Unlock with your password.

If any bind does nothing, confirm `dms` is on PATH in a terminal:
`dms ipc spotlight toggle` should toggle the launcher by hand.

---

## 2. Cheat-sheet (the rewritten shortcuts viewer)

- [ ] **SUPER+/** opens an HTML page in the default browser.
- [ ] Colors and font match the current Stylix scheme (not unstyled white).
- [ ] The list includes the core binds above.
- [ ] **The list includes nixerator's `conf.d` binds** — confirm these appear:
      `SUPER+W`, `SUPER+O`, `SUPER+M`, `SUPER+D` (workspace toggles) and the
      `SUPER+SHIFT+W/O/M/D` move variants. Their presence proves the page is
      rendered from live `hyprctl binds`, not a static list.

If the page is empty or stale: run `hypr-shortcuts` from a terminal and read
any error; check `hyprctl binds -j | head`.

---

## 3. Volume / brightness / mute OSD

- [ ] **XF86AudioRaiseVolume / LowerVolume** — DMS volume OSD appears and the
      level moves; holding the key repeats smoothly.
- [ ] **XF86AudioMute** — toggles mute; OSD reflects it.
- [ ] **XF86AudioMicMute** — toggles mic mute.
- [ ] Volume keys still work **while the screen is locked** (binds are `locked`).
- [ ] **(laptop) XF86MonBrightnessUp / Down** — internal panel brightness moves;
      OSD appears; holding repeats. (logind path, no group needed.)

If volume keys do nothing: `dms ipc audio increment 3` by hand. If that works,
the keysym mapping is the issue, not DMS.

---

## 4. Media keys

With something playing (any MPRIS source — browser, spotify, ncspot):

- [ ] **XF86AudioPlay / Pause** — toggles playback (`playerctl play-pause`).
- [ ] **XF86AudioNext / Prev** — skips tracks.

---

## 5. Idle ladder — the hard requirement

This is the behavior that was broken under hypridle. Do not disable any step if
it misbehaves; capture findings instead.

Leave the machine completely untouched (no mouse jiggle) and watch the clock:

- [ ] **~5 min** — session locks automatically.
- [ ] **~6 min** — **displays turn off (DPMS).** Screen goes truly black /
      backlight off, not just the lock wallpaper.
- [ ] **Wake** — a key press or mouse move turns the displays back on cleanly,
      no garbled output, no need to switch TTY.
- [ ] **~10 min** — machine suspends.
- [ ] **Resume** — on wake from suspend, the session is **locked** (you land on
      the password prompt, never on an unlocked desktop).

If screen-off does NOT blank, or blanks but won't wake:
1. Note exactly which: never blanks / blanks but no wake / wakes garbled.
2. `hyprctl monitors` before and during idle — does `dpmsStatus` flip to off?
3. Confirm both are set: `hyprctl getoption misc:key_press_enables_dpms` and
   `misc:mouse_move_enables_dpms` (expect `int: 1`).
4. `journalctl --user -u dms.service -b --no-pager | grep -i 'monitor\|dpms\|idle'`.
Paste those back and I'll diagnose — do not turn dpmsTimeout to 0.

---

## 6. Stylix theming

- [ ] DMS bar/menus use the base16 colors of your scheme (compare against a
      terminal or another themed app).
- [ ] Fonts in DMS match `style.fonts.sansSerif` (Inter by default).
- [ ] The wallpaper is the Stylix image (`style.wallpaper`), set by DMS.
- [ ] No matugen "auto color from wallpaper" drift — the palette stays the
      declared scheme even though DMS normally derives color from the wallpaper
      (`enableDynamicTheming = false` should prevent this).

---

## 7. External monitor brightness (laptop + external display only)

- [ ] **(laptop+DDC)** Brightness keys also dim/brighten an external monitor
      over i2c. `hardware.i2c.enable` is set by the dank module.

If the external monitor doesn't respond: add yourself to the `i2c` group
(`users.users.<you>.extraGroups = [ "i2c" ];`), rebuild, re-log. Report back
and I'll wire that into hyprflake if it's needed.

---

## 8. Rollback drill (proves the one-line revert)

- [ ] `cd ~/git/nixerator && git revert <pin commit> && sudo nixos-rebuild switch --flake .#<host>`
      (or revert `flake.nix` + `nix flake update hyprflake`).
- [ ] After rebuild + re-login, the **waybar** shell returns and DMS is gone.
- [ ] Re-apply the pin to go back to DMS once you've confirmed rollback works.

---

## Result summary

Record per section: PASS / FAIL / N-A, and paste any diagnostic output for
failures (especially section 5). Anything that fails is mine to fix on the
branch before this merges to main.
