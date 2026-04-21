#!/usr/bin/env python3
# calendar-takeover: fullscreen overlay for Google Calendar reminders.
# Launched by swaync's scripts hook; reads SWAYNC_* env vars.

import datetime
import os
import pathlib
import sys

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")

from gi.repository import Gdk, Gio, Gtk, Gtk4LayerShell as LayerShell  # noqa: E402


def _maybe_log():
    if os.environ.get("CALENDAR_TAKEOVER_DEBUG") != "1":
        return
    try:
        log_path = pathlib.Path.home() / ".cache" / "calendar-takeover.log"
        log_path.parent.mkdir(parents=True, exist_ok=True)
        with log_path.open("a", encoding="utf-8") as fh:
            fh.write(
                f"{datetime.datetime.now().isoformat()} "
                f"app={os.environ.get('SWAYNC_APP_NAME')!r} "
                f"summary={os.environ.get('SWAYNC_SUMMARY')!r} "
                f"body={os.environ.get('SWAYNC_BODY')!r}\n"
            )
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
    LayerShell.set_keyboard_mode(win, LayerShell.KeyboardMode.EXCLUSIVE)

    outer = Gtk.Box(
        orientation=Gtk.Orientation.VERTICAL,
        halign=Gtk.Align.CENTER,
        valign=Gtk.Align.CENTER,
        spacing=32,
    )
    outer.add_css_class("content")

    summary_label = Gtk.Label(label=summary, wrap=True, justify=Gtk.Justification.CENTER)
    summary_label.add_css_class("summary")
    outer.append(summary_label)

    if body:
        body_label = Gtk.Label(label=body, wrap=True, justify=Gtk.Justification.CENTER)
        body_label.add_css_class("body")
        outer.append(body_label)

    btn = Gtk.Button(label=dismiss_label)
    btn.add_css_class("dismiss")
    btn.set_halign(Gtk.Align.CENTER)
    btn.connect("clicked", lambda _b: app.quit())
    outer.append(btn)

    win.set_child(outer)

    key_ctrl = Gtk.EventControllerKey.new()

    def _on_key(_c, keyval, _code, _state):
        if keyval in (Gdk.KEY_Escape, Gdk.KEY_Return, Gdk.KEY_KP_Enter):
            app.quit()
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
