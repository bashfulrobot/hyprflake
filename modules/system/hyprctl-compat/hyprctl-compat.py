#!/usr/bin/env python3
"""hyprctl-compat: translate legacy `hyprctl dispatch X Y` to Lua form.

Hyprland's Lua config backend (0.55+) interprets `hyprctl dispatch <X>`
as a Lua `hl.dispatch(<X>)` eval, so the legacy hyprlang dispatch
arg syntax (`workspace 1`, `movetoworkspace name:foo`, `dpms off`, etc.)
fails to parse and the dispatch silently no-ops. Upstream Hyprland
rejected adding a backwards-compat shim
(github.com/hyprwm/Hyprland/discussions/14255).

This wrapper sits in front of nixpkgs' hyprctl, intercepts `dispatch`
and `--batch` subcommands containing legacy dispatch lines, and
rewrites them to the lua-call form before execv'ing the real binary.
Anything else passes through verbatim.

Intended as a transition aid while third-party tooling (waybar,
pyprland, user shell scripts) catches up. Remove this wrapper once
ecosystem migration is complete.
"""
from __future__ import annotations

import os
import re
import sys
from typing import Callable, Optional

REAL_HYPRCTL = "@hyprctl@"  # substituted at build time by the nix derivation


# ---------- lua emitters ---------------------------------------------------


def lua_str(s: str) -> str:
    """Quote a string as a Lua double-quoted literal."""
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def parse_workspace_arg(a: str) -> str:
    """Workspace identifiers: 1, name:foo, special:bar, e+1, +1, previous.

    Numeric -> Lua number. Everything else -> Lua string."""
    if a.startswith("name:"):
        return lua_str(a[len("name:"):])
    if a.startswith("special:") or a.startswith("special"):
        return lua_str(a)
    try:
        return str(int(a))
    except ValueError:
        return lua_str(a)


_DIRMAP = {"l": "left", "r": "right", "u": "up", "d": "down"}


def parse_direction(a: str) -> str:
    return _DIRMAP.get(a, a)


def _toggle_action(a: str) -> str:
    """on/off/toggle -> set/unset/toggle (Hyprland eTogglableAction names)."""
    return {"on": "set", "off": "unset", "toggle": "toggle"}.get(a, "toggle")


# ---------- dispatcher translation table -----------------------------------
#
# Each entry maps a legacy dispatcher name to a function that takes the
# remaining whitespace-split tokens and returns a single Lua expression
# (without an enclosing hl.dispatch — that's added by Hyprland itself).
# Return None or omit the entry to pass the original through unchanged
# (Hyprland will then emit its standard "your syntax might need to be
# updated" error so the user sees what's broken).

def _exec(tokens: list[str]) -> Optional[str]:
    return f"hl.dsp.exec_cmd({lua_str(' '.join(tokens))})" if tokens else None


def _execr(tokens: list[str]) -> Optional[str]:
    return f"hl.dsp.exec_raw({lua_str(' '.join(tokens))})" if tokens else None


def _killactive(tokens: list[str]) -> str:
    return "hl.dsp.window.close()"


def _closewindow(tokens: list[str]) -> str:
    if not tokens:
        return "hl.dsp.window.close()"
    return f"hl.dsp.window.close({{window={lua_str(' '.join(tokens))}}})"


def _forcekillactive(tokens: list[str]) -> str:
    return "hl.dsp.window.kill()"


def _killwindow(tokens: list[str]) -> str:
    if not tokens:
        return "hl.dsp.window.kill()"
    return f"hl.dsp.window.kill({{window={lua_str(' '.join(tokens))}}})"


def _togglefloating(tokens: list[str]) -> str:
    return 'hl.dsp.window.float({action="toggle"})'


def _setfloating(tokens: list[str]) -> str:
    return 'hl.dsp.window.float({action="set"})'


def _settiled(tokens: list[str]) -> str:
    return 'hl.dsp.window.float({action="unset"})'


def _workspace(tokens: list[str]) -> Optional[str]:
    if not tokens:
        return None
    return f"hl.dsp.focus({{workspace={parse_workspace_arg(' '.join(tokens))}}})"


def _movetoworkspace(tokens: list[str]) -> Optional[str]:
    if not tokens:
        return None
    return f"hl.dsp.window.move({{workspace={parse_workspace_arg(' '.join(tokens))}}})"


def _movetoworkspacesilent(tokens: list[str]) -> Optional[str]:
    if not tokens:
        return None
    return (
        f"hl.dsp.window.move({{workspace={parse_workspace_arg(' '.join(tokens))}"
        ", follow=false})"
    )


def _movewindow(tokens: list[str]) -> Optional[str]:
    if not tokens:
        return None
    first = tokens[0]
    if first in {"l", "r", "u", "d", "left", "right", "up", "down"}:
        return f'hl.dsp.window.move({{direction="{parse_direction(first)}"}})'
    if first.startswith("mon:"):
        return f"hl.dsp.window.move({{monitor={lua_str(first[len('mon:'):])}}})"
    # workspace selector (rare): treat as workspace move
    return f"hl.dsp.window.move({{workspace={parse_workspace_arg(' '.join(tokens))}}})"


def _movefocus(tokens: list[str]) -> Optional[str]:
    if not tokens:
        return None
    return f'hl.dsp.focus({{direction="{parse_direction(tokens[0])}"}})'


def _focusmonitor(tokens: list[str]) -> Optional[str]:
    if not tokens:
        return None
    return f"hl.dsp.focus({{monitor={lua_str(' '.join(tokens))}}})"


def _focuswindow(tokens: list[str]) -> Optional[str]:
    if not tokens:
        return None
    return f"hl.dsp.focus({{window={lua_str(' '.join(tokens))}}})"


def _focusworkspaceoncurrentmonitor(tokens: list[str]) -> Optional[str]:
    if not tokens:
        return None
    return (
        f"hl.dsp.focus({{workspace={parse_workspace_arg(' '.join(tokens))}"
        ", on_current_monitor=true})"
    )


def _togglespecialworkspace(tokens: list[str]) -> str:
    if tokens:
        return f"hl.dsp.workspace.toggle_special({lua_str(' '.join(tokens))})"
    return "hl.dsp.workspace.toggle_special()"


def _fullscreen(tokens: list[str]) -> str:
    # Legacy: `fullscreen` (no arg) toggles. `fullscreen 0` = real
    # fullscreen, `fullscreen 1` = maximize. Default both to toggle.
    if not tokens:
        return 'hl.dsp.window.fullscreen({mode="fullscreen", action="toggle"})'
    mode = "fullscreen" if tokens[0] == "0" else "maximized"
    return f'hl.dsp.window.fullscreen({{mode="{mode}", action="toggle"}})'


def _dpms(tokens: list[str]) -> str:
    if not tokens:
        return 'hl.dsp.dpms({action="toggle"})'
    action = _toggle_action(tokens[0])
    if len(tokens) > 1:
        return f'hl.dsp.dpms({{action="{action}", monitor={lua_str(" ".join(tokens[1:]))}}})'
    return f'hl.dsp.dpms({{action="{action}"}})'


def _submap(tokens: list[str]) -> str:
    if not tokens:
        return "hl.dsp.submap()"
    return f"hl.dsp.submap({lua_str(' '.join(tokens))})"


def _exit(tokens: list[str]) -> str:
    return "hl.dsp.exit()"


def _layoutmsg(tokens: list[str]) -> Optional[str]:
    if not tokens:
        return None
    return f"hl.dsp.layout({lua_str(' '.join(tokens))})"


def _pseudo(tokens: list[str]) -> str:
    return "hl.dsp.window.pseudo()"


def _pin(tokens: list[str]) -> str:
    return "hl.dsp.window.pin()"


def _centerwindow(tokens: list[str]) -> str:
    return "hl.dsp.window.center()"


def _swapwindow(tokens: list[str]) -> Optional[str]:
    if not tokens:
        return None
    return f'hl.dsp.window.swap({{direction="{parse_direction(tokens[0])}"}})'


def _bringactivetotop(tokens: list[str]) -> str:
    return "hl.dsp.window.bring_to_top()"


def _cyclenext(tokens: list[str]) -> str:
    return "hl.dsp.window.cycle_next()"


def _signal(tokens: list[str]) -> Optional[str]:
    if not tokens:
        return None
    try:
        return f"hl.dsp.window.signal({int(tokens[0])})"
    except ValueError:
        return None


TRANSLATORS: dict[str, Callable[[list[str]], Optional[str]]] = {
    "exec": _exec,
    "execr": _execr,
    "killactive": _killactive,
    "closewindow": _closewindow,
    "forcekillactive": _forcekillactive,
    "killwindow": _killwindow,
    "togglefloating": _togglefloating,
    "setfloating": _setfloating,
    "settiled": _settiled,
    "workspace": _workspace,
    "movetoworkspace": _movetoworkspace,
    "movetoworkspacesilent": _movetoworkspacesilent,
    "movewindow": _movewindow,
    "movefocus": _movefocus,
    "focusmonitor": _focusmonitor,
    "focuswindow": _focuswindow,
    "focusworkspaceoncurrentmonitor": _focusworkspaceoncurrentmonitor,
    "togglespecialworkspace": _togglespecialworkspace,
    "fullscreen": _fullscreen,
    "dpms": _dpms,
    "submap": _submap,
    "exit": _exit,
    "layoutmsg": _layoutmsg,
    "pseudo": _pseudo,
    "pin": _pin,
    "centerwindow": _centerwindow,
    "swapwindow": _swapwindow,
    "bringactivetotop": _bringactivetotop,
    "cyclenext": _cyclenext,
    "signal": _signal,
}


# ---------- core --------------------------------------------------------------


_HL_PREFIX_RE = re.compile(r"""^['"]?hl\.""")


def translate_dispatch_tokens(tokens: list[str]) -> Optional[str]:
    """Given the tokens after `dispatch`, return a Lua expression or None.

    None means: leave the original args alone (already-lua input, or an
    unknown legacy dispatcher — Hyprland will error out itself, which is
    the right signal that this wrapper needs extending)."""
    if not tokens:
        return None
    name = tokens[0]
    if _HL_PREFIX_RE.match(name):
        return None  # already lua-shaped, don't touch
    fn = TRANSLATORS.get(name)
    if fn is None:
        return None
    try:
        return fn(tokens[1:])
    except Exception:
        return None


def translate_batch_segment(seg: str) -> str:
    """Rewrite a single `--batch` segment if it's a legacy dispatch."""
    stripped = seg.strip()
    if not stripped:
        return seg
    parts = stripped.split()
    if parts[0] != "dispatch":
        return seg
    lua = translate_dispatch_tokens(parts[1:])
    if lua is None:
        return seg
    leading = seg[: len(seg) - len(seg.lstrip())]
    return f"{leading}dispatch {lua}"


def rewrite_argv(argv: list[str]) -> list[str]:
    """Walk argv looking for `dispatch` or `--batch`; rewrite in place."""
    out = list(argv)
    i = 0
    while i < len(out):
        tok = out[i]
        if tok == "--batch":
            if i + 1 < len(out):
                segs = out[i + 1].split(";")
                out[i + 1] = ";".join(translate_batch_segment(s) for s in segs)
                i += 2
                continue
        elif tok == "dispatch":
            # `dispatch` consumes the rest of argv as its arg vector.
            lua = translate_dispatch_tokens(out[i + 1:])
            if lua is not None:
                out = out[: i + 1] + [lua]
            break
        i += 1
    return out


def main() -> None:
    new_argv = rewrite_argv(sys.argv[1:])
    os.execv(REAL_HYPRCTL, [REAL_HYPRCTL, *new_argv])


if __name__ == "__main__":
    main()
