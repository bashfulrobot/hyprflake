#!/usr/bin/env python3
# calendar-takeover: fullscreen overlay for Google Calendar reminders.
# Launched by swaync's scripts hook; reads SWAYNC_* env vars.

# gtk4-layer-shell must be loaded before libwayland-client so its symbols win.
# GI_TYPELIB_PATH would otherwise cause gi to pull libwayland first through GTK.
# See https://github.com/wmww/gtk4-layer-shell/blob/main/linking.md
from ctypes import CDLL  # noqa: I001
CDLL("libgtk4-layer-shell.so")

import datetime  # noqa: E402
import html  # noqa: E402
import json  # noqa: E402
import os  # noqa: E402
import pathlib  # noqa: E402
import re  # noqa: E402
import sys  # noqa: E402

import gi  # noqa: E402

gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")

from gi.repository import Gdk, Gio, GLib, Gtk, Gtk4LayerShell as LayerShell  # noqa: E402

URL_RE = re.compile(r"https?://[^\s<>\"']+")


def _maybe_log():
    if os.environ.get("CALENDAR_TAKEOVER_DEBUG") != "1":
        return
    try:
        log_path = pathlib.Path.home() / ".cache" / "calendar-takeover.log"
        log_path.parent.mkdir(parents=True, exist_ok=True)
        # Dump every SWAYNC_* env var - hints included - so the user can diff
        # notifications from different Google accounts / Chrome profiles to
        # find a discriminating signal.
        swaync_vars = sorted(
            (k, v) for k, v in os.environ.items() if k.startswith("SWAYNC_")
        )
        with log_path.open("a", encoding="utf-8") as fh:
            fh.write(f"--- {datetime.datetime.now().isoformat()} ---\n")
            for k, v in swaync_vars:
                fh.write(f"{k}={v!r}\n")
            fh.write("\n")
    except OSError:
        pass


def _load_css():
    css_path = os.environ.get("CALENDAR_TAKEOVER_CSS")
    if not css_path or not os.path.exists(css_path):
        return
    provider = Gtk.CssProvider()
    provider.load_from_path(css_path)
    display = Gdk.Display.get_default()
    if display is not None:
        Gtk.StyleContext.add_provider_for_display(
            display, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )


def _linkify(text):
    """Escape HTML and turn http(s) URLs into pango anchor tags."""
    parts = []
    last = 0
    for match in URL_RE.finditer(text):
        parts.append(html.escape(text[last:match.start()]))
        url = match.group(0)
        escaped = html.escape(url, quote=True)
        parts.append(f'<a href="{escaped}">{escaped}</a>')
        last = match.end()
    parts.append(html.escape(text[last:]))
    return "".join(parts)


def _first_url(text):
    match = URL_RE.search(text or "")
    return match.group(0) if match else None


def _copy_to_clipboard(text):
    display = Gdk.Display.get_default()
    if display is None:
        return False
    clipboard = display.get_clipboard()
    # Gdk.Clipboard.set accepts a GValue; PyGObject's set_text is the simplest path
    # but not all bindings expose it - fall back to ContentProvider.
    try:
        clipboard.set(text)
        return True
    except TypeError:
        pass
    provider = Gdk.ContentProvider.new_for_bytes(
        "text/plain;charset=utf-8", GLib.Bytes.new(text.encode("utf-8"))
    )
    clipboard.set_content(provider)
    return True


def _build_window(app):
    summary = os.environ.get("SWAYNC_SUMMARY") or "Calendar reminder"
    body = os.environ.get("SWAYNC_BODY") or ""
    dismiss_label = os.environ.get("CALENDAR_TAKEOVER_DISMISS") or "Dismiss"

    win = Gtk.ApplicationWindow(application=app)
    win.add_css_class("calendar-takeover")

    LayerShell.init_for_window(win)
    LayerShell.set_namespace(win, "calendar-takeover")
    LayerShell.set_layer(win, LayerShell.Layer.OVERLAY)
    for edge in (
        LayerShell.Edge.TOP,
        LayerShell.Edge.BOTTOM,
        LayerShell.Edge.LEFT,
        LayerShell.Edge.RIGHT,
    ):
        LayerShell.set_anchor(win, edge, True)
    LayerShell.set_exclusive_zone(win, -1)
    # ON_DEMAND takes keyboard focus when the user interacts with the surface
    # (click / tap). EXCLUSIVE was eating the first click to transfer focus,
    # forcing the user to double-click Dismiss.
    LayerShell.set_keyboard_mode(win, LayerShell.KeyboardMode.ON_DEMAND)

    outer = Gtk.Box(
        orientation=Gtk.Orientation.VERTICAL,
        halign=Gtk.Align.CENTER,
        valign=Gtk.Align.CENTER,
        spacing=24,
    )
    outer.add_css_class("content")

    summary_label = Gtk.Label(
        label=summary,
        wrap=True,
        justify=Gtk.Justification.CENTER,
        selectable=True,
    )
    summary_label.add_css_class("summary")
    outer.append(summary_label)

    if body:
        body_label = Gtk.Label(
            wrap=True,
            justify=Gtk.Justification.CENTER,
            selectable=True,
            use_markup=True,
        )
        body_label.set_markup(_linkify(body))
        body_label.add_css_class("body")
        # Default handler opens URI via Gio - explicit return False lets it run.
        body_label.connect("activate-link", lambda _lbl, _uri: False)
        outer.append(body_label)

    button_row = Gtk.Box(
        orientation=Gtk.Orientation.HORIZONTAL,
        halign=Gtk.Align.CENTER,
        spacing=16,
    )
    button_row.add_css_class("button-row")

    url = _first_url(body)
    if url:
        copy_btn = Gtk.Button(label="Copy link")
        copy_btn.add_css_class("copy")

        def _on_copy(btn):
            if _copy_to_clipboard(url):
                btn.set_label("Copied")
                btn.add_css_class("copied")

        copy_btn.connect("clicked", _on_copy)
        button_row.append(copy_btn)

    try:
        accounts = json.loads(os.environ.get("CALENDAR_TAKEOVER_ACCOUNTS") or "[]")
    except (json.JSONDecodeError, TypeError):
        accounts = []

    def _launch(target_url):
        Gio.AppInfo.launch_default_for_uri(target_url, None)
        app.quit()

    if accounts:
        # Linked [Account ▾] [Open Calendar] pair - one logical control.
        picker = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        picker.add_css_class("linked")
        picker.add_css_class("account-picker")

        model = Gtk.StringList.new([a.get("label", "") for a in accounts])
        dropdown = Gtk.DropDown(model=model)
        dropdown.set_selected(0)
        picker.append(dropdown)

        open_btn = Gtk.Button(label="Open Calendar")
        open_btn.add_css_class("open")

        def _on_open(_b):
            idx = dropdown.get_selected()
            if 0 <= idx < len(accounts):
                _launch(accounts[idx]["url"])

        open_btn.connect("clicked", _on_open)
        picker.append(open_btn)
        button_row.append(picker)
    else:
        fallback_url = (
            os.environ.get("CALENDAR_TAKEOVER_URL")
            or "https://accounts.google.com/AccountChooser"
            "?continue=https%3A%2F%2Fcalendar.google.com%2Fcalendar%2Fr%2Fday"
        )
        open_btn = Gtk.Button(label="Open Calendar")
        open_btn.add_css_class("open")
        open_btn.connect("clicked", lambda _b: _launch(fallback_url))
        button_row.append(open_btn)

    dismiss_btn = Gtk.Button(label=dismiss_label)
    dismiss_btn.add_css_class("dismiss")

    def _dismiss(*_):
        app.quit()
        return True

    dismiss_btn.connect("clicked", _dismiss)
    # Belt-and-suspenders: a direct gesture controller catches the release
    # event even if the button's internal click sequence mis-fires under
    # layer-shell focus transitions.
    gesture = Gtk.GestureClick.new()
    gesture.set_button(1)
    gesture.connect("released", lambda *_: _dismiss())
    dismiss_btn.add_controller(gesture)
    button_row.append(dismiss_btn)

    outer.append(button_row)

    win.set_child(outer)
    # Makes Enter activate Dismiss as the default action.
    win.set_default_widget(dismiss_btn)

    key_ctrl = Gtk.EventControllerKey.new()

    def _on_key(_c, keyval, _code, state):
        if keyval == Gdk.KEY_Escape:
            app.quit()
            return True
        # Ctrl+C copies the URL if one exists; otherwise let GTK handle selection copy.
        if url and keyval == Gdk.KEY_c and (state & Gdk.ModifierType.CONTROL_MASK):
            _copy_to_clipboard(url)
            return True
        return False

    key_ctrl.connect("key-pressed", _on_key)
    win.add_controller(key_ctrl)

    win.present()


def main():
    _maybe_log()

    app = Gtk.Application(
        application_id="dev.hyprflake.CalendarTakeover",
        flags=Gio.ApplicationFlags.NON_UNIQUE,
    )

    def _on_activate(a):
        _load_css()
        _build_window(a)

    app.connect("activate", _on_activate)
    return app.run([])


if __name__ == "__main__":
    sys.exit(main())
