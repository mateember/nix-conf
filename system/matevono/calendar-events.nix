# Calendar events for the shell's calendar popup (Quickshell, config/quickshell/modules/Clock.qml).
# `hcs-calendar-events FROM TO` runs ~/.config/quickshell/scripts/calendar-events.py with Python +
# PyGObject and the Evolution Data Server typelibs. It reads the calendars GNOME Calendar / GNOME
# Online Accounts set up (Nextcloud CalDAV, Google, webcal) from EDS and prints JSON; no passwords.
{
  lib,
  pkgs,
  ...
}: let
  python = pkgs.python3.withPackages (p: [p.pygobject3]);
  typelibs = with pkgs; [
    evolution-data-server # EDataServer, ECal, Camel
    libical # ICalGLib
    glib # GLib, GObject, Gio
    gobject-introspection # libxml2 typelib
    libsoup_3
    json-glib
  ];
  hcs-calendar-events = pkgs.writeShellScriptBin "hcs-calendar-events" ''
    export GI_TYPELIB_PATH=${lib.makeSearchPath "lib/girepository-1.0" typelibs}''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}
    exec ${python}/bin/python3 "''${HCS_CALENDAR_SCRIPT:-$HOME/.config/quickshell/scripts/calendar-events.py}" "$@"
  '';
in {
  environment.systemPackages = [hcs-calendar-events];
}
