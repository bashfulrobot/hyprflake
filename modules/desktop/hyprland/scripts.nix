# Helper scripts shipped on PATH by the hyprland module.
{ pkgs }:
{
  hypr-equalize-windows = pkgs.writeShellApplication {
    name = "hypr-equalize-windows";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      active=$(hyprctl activewindow -j)
      active_addr=$(echo "$active" | jq -r '.address')
      ws_id=$(echo "$active" | jq -r '.workspace.id')

      addrs=$(hyprctl clients -j | jq -r --argjson ws "$ws_id" \
        '.[] | select(.workspace.id == $ws) | .address')

      batch=""
      for addr in $addrs; do
        batch+="dispatch focuswindow address:$addr; dispatch splitratio exact 1.0; "
      done

      hyprctl --batch "$batch dispatch focuswindow address:$active_addr"
    '';
  };

  hypr-record-region = pkgs.writeShellApplication {
    name = "hypr-record-region";
    runtimeInputs = [
      pkgs.wf-recorder
      pkgs.slurp
      pkgs.coreutils
      pkgs.libnotify
    ];
    text = ''
      if pgrep -x wf-recorder > /dev/null; then
        pkill wf-recorder
        notify-send -i media-record -u normal "Recording stopped" "Saved to ~/Videos"
      else
        mkdir -p "$HOME/Videos"
        outfile="$HOME/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4"
        notify-send -i media-record -u critical "Recording started" "CTRL ALT R to stop"
        wf-recorder -g "$(slurp)" -f "$outfile"
      fi
    '';
  };

  # tv-workspace: present a deck on an external HDMI TV, then flip to mirroring
  # with one key (SUPER+SHIFT+T = "TV" + "Toggle").
  #
  #   Present  external monitor is its own output with workspace 10 pinned to
  #            it (SUPER+0 reaches it) — deck on the big screen, laptop free.
  #   Mirror   external monitor mirrors the laptop panel — audience sees your
  #            actual screen, for a live walk-through.
  #
  # Fully STATELESS: no config file. It detects the internal panel
  # (eDP/LVDS/DSI connector) and the external output live from `hyprctl
  # monitors`, and reads the current Present/Mirror state from the external's
  # `mirrorOf` field. With no external display connected it is a benign no-op,
  # so there is nothing to set up and nothing to clean up on unplug — Hyprland
  # reclaims workspace 10 onto the laptop by itself. Everything is applied at
  # runtime via `hyprctl eval 'hl.*'` (this Hyprland runs the Lua config
  # parser, where `hyprctl keyword`/`dispatch` are inert), so `tv-workspace
  # reset` (hyprctl reload) or a logout fully restores this declarative config.
  tv-workspace = pkgs.writeShellApplication {
    name = "tv-workspace";
    runtimeInputs = [
      pkgs.jq
      pkgs.libnotify
    ];
    text = ''
      WS=10                 # the workspace SUPER+0 reaches

      # Route through the notification daemon (DMS) so the toast lands in the
      # DMS notification center, consistent with hypr-record-region.
      notify() {
        notify-send -i video-display -u normal "TV workspace" "$*" || true
        printf '%s\n' "$*"
      }

      cmd="''${1:-toggle}"

      if [ "$cmd" = "reset" ]; then
        hyprctl reload
        notify "TV: reset to declarative monitor config."
        exit 0
      fi

      mons=$(hyprctl monitors -j)   # enabled monitors only

      # Internal panel = embedded connector; fall back to monitor id 0.
      internal=$(echo "$mons" | jq -r \
        'first(.[] | select(.name | test("^(eDP|LVDS|DSI)-")) | .name) // empty')
      if [ -z "$internal" ]; then
        internal=$(echo "$mons" | jq -r 'first(.[] | select(.id == 0) | .name) // empty')
      fi

      # External (TV) = first enabled monitor that isn't the internal panel.
      external=$(echo "$mons" | jq -r --arg int "$internal" \
        'first(.[] | select(.name != $int) | .name) // empty')

      if [ -z "$external" ]; then
        notify "TV: no external display connected."
        exit 0
      fi

      # This Hyprland uses the Lua config parser (configType = "lua"), under
      # which `hyprctl keyword` and raw `hyprctl dispatch <name>` do NOT work
      # ("keyword can't work with non-legacy parsers. Use eval."). The runtime
      # equivalents go through `hyprctl eval 'hl.<fn>(...)'`: hl.monitor and
      # hl.workspace_rule apply config keywords directly, while a dispatcher
      # must be wrapped as hl.dispatch(hl.dsp.<x>(...)) to actually fire — a
      # bare hl.dsp.* call only builds a dispatcher object and is a no-op.
      apply_present() {
        # External becomes its own (non-mirror) output; ws10 is pinned to it.
        hyprctl eval "hl.monitor({output=\"$external\", mode=\"preferred\", position=\"auto\", scale=1})"
        hyprctl eval "hl.workspace_rule({workspace=\"$WS\", monitor=\"$external\", default=true})"
        # Surface ws10 on the TV, then hand focus back to the laptop's current
        # workspace so the panel stays usable ("deck on the big screen,
        # laptop free"). Hyprland keeps ws10 shown on the TV once focused.
        back=$(hyprctl monitors -j | jq -r 'first(.[] | select(.focused) | .activeWorkspace.id) // 1')
        hyprctl eval "hl.dispatch(hl.dsp.focus({workspace=$WS}))"
        hyprctl eval "hl.dispatch(hl.dsp.focus({workspace=$back}))"
      }
      apply_mirror() {
        hyprctl eval "hl.monitor({output=\"$external\", mode=\"preferred\", position=\"auto\", scale=1, mirror=\"$internal\"})"
      }

      # Current state read live from the external output's mirrorOf field.
      mof=$(echo "$mons" | jq -r --arg n "$external" \
        '(.[] | select(.name == $n) | .mirrorOf) // "none"')

      case "$cmd" in
        present) apply_present; notify "TV → workspace $WS (deck on the big screen)." ;;
        mirror)  apply_mirror;  notify "TV → mirroring the laptop." ;;
        toggle)
          if [ "$mof" = "none" ]; then
            apply_mirror; notify "TV → mirroring the laptop."
          else
            apply_present; notify "TV → workspace $WS (deck on the big screen)."
          fi
          ;;
        *)
          echo "usage: tv-workspace [toggle|present|mirror|reset]" >&2
          exit 1
          ;;
      esac
    '';
  };

  # hypr-screenshot: one place for the hyprshot + satty pipeline the
  # screenshot binds share.
  #   region  select a region, annotate in satty (copy-on-save via wl-copy)
  #   output  capture the focused output, annotate in satty
  #   clip    select a region straight to the clipboard, no annotation
  hypr-screenshot = pkgs.writeShellApplication {
    name = "hypr-screenshot";
    runtimeInputs = [
      pkgs.hyprshot
      pkgs.satty
      pkgs.wl-clipboard
    ];
    text = ''
      mode="''${1:-region}"

      annotate() {
        hyprshot -m "$1" --raw | satty -f - --copy-command wl-copy
      }

      case "$mode" in
        region) annotate region ;;
        output) annotate output ;;
        clip)   hyprshot -m region --clipboard-only ;;
        *)
          echo "usage: hypr-screenshot [region|output|clip]" >&2
          exit 1
          ;;
      esac
    '';
  };

  # hypr-browser: open the user's default browser (SUPER+B). Launches the
  # desktop entry xdg-settings reports, which opens a plain new window;
  # falls back to xdg-open when no default is set or the launch fails.
  hypr-browser = pkgs.writeShellApplication {
    name = "hypr-browser";
    runtimeInputs = [
      pkgs.gtk3
      pkgs.xdg-utils
    ];
    text = ''
      entry="$(xdg-settings get default-web-browser 2>/dev/null || true)"
      if [ -n "$entry" ] && gtk-launch "$entry" 2>/dev/null; then
        exit 0
      fi
      exec xdg-open https://
    '';
  };
}
