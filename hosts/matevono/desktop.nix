# Desktop environments (Hyprland + Quickshell shell, COSMIC, GNOME, Niri),
# audio (PipeWire), fonts, portals, and PAM/KWallet.
#
# Hyprland desktop with the Quickshell shell (COSMIC theme):
# The dotfiles (~/dotfiles/config/hypr, ~/dotfiles/config/quickshell) hold the configs;
# this module provides the session, PAM/portal/hardware bits and every runtime dependency.
# Developed in ~/hypr-cosmic-shell (flake.nix lists the same packages for testing there).
{
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: let
  # Calendar events for the shell's calendar popup (Quickshell, config/quickshell/modules/Clock.qml).
  # `hcs-calendar-events FROM TO` runs ~/.config/quickshell/scripts/calendar-events.py with Python +
  # PyGObject and the Evolution Data Server typelibs. It reads the calendars GNOME Calendar / GNOME
  # Online Accounts set up (Nextcloud CalDAV, Google, webcal) from EDS and prints JSON; no passwords.
  pythonCalendar = pkgs.python3.withPackages (p: [p.pygobject3]);
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
    exec ${pythonCalendar}/bin/python3 "''${HCS_CALENDAR_SCRIPT:-$HOME/.config/quickshell/scripts/calendar-events.py}" "$@"
  '';
in {
  # ---- Sessions -------------------------------------------------------------
  # UWSM-managed session ("Hyprland (UWSM)" in cosmic-greeter). UWSM starts
  # graphical-session.target, which xdg-desktop-portal needs (screen sharing, file pickers).
  # Hyprland reads ~/.config/hypr/hyprland.lua.
  programs = {
    hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
      package = pkgs-unstable.hyprland;
      portalPackage = pkgs-unstable.xdg-desktop-portal-hyprland;
    };

    niri = {
      package = pkgs-unstable.niri;
      enable = false;
      useNautilus = true;
    };
  };

  # ---- Display Manager, Desktops & PipeWire ---------------------------------
  services = {
    gnome = {
      evolution-data-server.enable = true;
      gnome-online-accounts.enable = true;
      glib-networking.enable = true;
      sushi.enable = true;
      gnome-keyring.enable = lib.mkForce false;
      gnome-browser-connector.enable = false;
      gnome-remote-desktop.enable = false;
    };

    flatpak.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      extraConfig.pipewire = {
        "default.clock.quantum" = 32;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 32;
      };
    };

    xserver.enable = true;
    desktopManager.plasma6.enable = false;
    desktopManager.gnome.enable = false;
    desktopManager.cosmic.enable = true;
    displayManager = {
      gdm.enable = false;
      cosmic-greeter.enable = true;
      autoLogin = {
        enable = false;
        user = "mate";
      };
    };

    getty.autologinUser = null;
    gvfs.enable = true;
    tumbler.enable = true;
  };

  # ---- Howdy Facial Authentication & IR Emitter -----------------------------
  services.linux-enable-ir-emitter = {
    enable = true;
    package = pkgs-unstable.linux-enable-ir-emitter;
    device = "video2";
  };

  services.howdy = {
    enable = true;
    package = pkgs-unstable.howdy;
    control = "sufficient";
    settings = {
      core = {
        abort_if_ssh = true;
        abort_if_lid_closed = true;
        detection_notice = false;
        timeout_notice = true;
      };
      video = {
        # Stable by-path link to the integrated IR camera (/dev/video2, 640x360 GREY)
        device_path = "/dev/v4l/by-path/pci-0000:00:14.0-usb-0:9:1.2-video-index0";
        frame_width = 640;
        frame_height = 360;
        max_height = 320;
        # Lower = stricter/more secure (scale 1-10, distance * 10; 3.5 is upstream default)
        certainty = 3.5;
        # 3s gives the camera time to wake from USB autosuspend without delaying password fallback
        timeout = 3;
        # Higher threshold (default 60) prevents false "too dark" skips in dark rooms where
        # only the face is IR-lit and the background is black, while still aborting at ~100% (closed shutter)
        dark_threshold = 75;
      };
    };
  };

  # ---- Lock Screen, Polkit & KWallet PAM ------------------------------------
  # Disable global Howdy PAM injection so initial login (cosmic-greeter/greetd/login)
  # still requires a password and properly unlocks KWallet via pam_kwallet5.
  security.pam.howdy = {
    enable = false;
    control = "sufficient";
  };

  # hyprlock authenticates through the `hyprlock` PAM service (without it, it falls back to `su`).
  security.pam.services = {
    # Quickshell lock screen (~/dotfiles/config/quickshell/lock). Two stacks run in parallel:
    # qs-lock is password only (pam_unix), so typing a password never waits for the face scan;
    # qs-lock-face adds Howdy in front of pam_unix.
    qs-lock = {};
    qs-lock-face.howdy.enable = true;

    hyprlock.howdy.enable = true;
    swaylock.howdy.enable = true;
    sudo.howdy.enable = true;
    su.howdy.enable = true;
    polkit-1.howdy.enable = true;
    systemd-run0.howdy.enable = true;

    # cosmic-greeter is implemented via greetd
    greetd.enableKwallet = true;
    # Fallbacks depending on cosmic-greeter's direct PAM service
    gdm.enableKwallet = true;
    gdm.kwallet.forceRun = true;
    cosmic-greeter.enableKwallet = true;
    cosmic-greeter.kwallet.forceRun = true;
    login.enableKwallet = true;
    login.kwallet.enable = true;
    cosmic-greeter.enableGnomeKeyring = true;
  };

  # The shell is the polkit agent in Hyprland. Keep polkit-gnome
  # (started with graphical-session.target) for the other desktops only.
  systemd.user.services = {
    "app-ibus-daemon@autostart" = {
      enable = false;
      unitConfig.ConditionPathExists = "/var/empty";
    };

    polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = ["graphical-session.target"];
      wants = ["graphical-session.target"];
      after = ["graphical-session.target"];
      unitConfig.ConditionEnvironment = "!XDG_CURRENT_DESKTOP=Hyprland";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

    # PAM (cosmic-greeter/greetd) stores the login password; pam_kwallet_init must run inside the
    # session to hand it to kwalletd. Its autostart entry has X-systemd-skip=true, so UWSM never
    # starts it: run it as a user service for Hyprland sessions instead.
    hyprland-kwallet-unlock = {
      description = "Unlock KWallet with the login password (Hyprland)";
      wantedBy = ["graphical-session.target"];
      after = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      unitConfig.ConditionEnvironment = "XDG_CURRENT_DESKTOP=Hyprland";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init";
      };
    };

    # hypridle runs as the user service from its package (services.hypridle below). The module sets
    # the unit's PATH to hyprland/hyprlock/procps only; hypridle.conf and hypr/scripts/lock.sh also
    # need qs, playerctl, busctl etc., so add the system and user profiles. Hyprland sessions only
    # (it used to be started by Hyprland's autostart; niri sessions don't use it).
    hypridle = {
      path = ["/etc/profiles/per-user/mate" "/run/current-system/sw"];
      unitConfig.ConditionEnvironment = "XDG_CURRENT_DESKTOP=Hyprland";
    };
  };

  # XDG autostart: UWSM runs XDG autostart entries in Hyprland. Hide the ones the shell replaces
  # (user entries in ~/.config/autostart override the system ones by file name):
  # polkit-gnome would take the polkit agent slot, nm-applet duplicates the shell's Wi-Fi menu.
  home-manager.users.mate.xdg.configFile = {
    "autostart/polkit-gnome-authentication-agent-1.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=PolicyKit Authentication Agent
      Exec=${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
      NoDisplay=true
      NotShowIn=Hyprland;
      AutostartCondition=GNOME3 unless-session gnome
    '';
  };

  # ---- Portals --------------------------------------------------------------
  # Hyprland portal for screen sharing, COSMIC's file chooser, KWallet for secrets (Flatpak apps).
  # Note: ~/.config/xdg-desktop-portal/hyprland-portals.conf overrides this file if it exists.
  xdg = {
    menus.enable = true;
    portal = {
      xdgOpenUsePortal = true;
      enable = true;
      extraPortals = [pkgs.kdePackages.xdg-desktop-portal-kde pkgs.xdg-desktop-portal-gtk];
      config.hyprland = {
        default = ["hyprland" "gtk"];
        "org.freedesktop.impl.portal.FileChooser" = ["cosmic"];
        "org.freedesktop.impl.portal.Secret" = ["kwallet"];
      };
    };
  };

  # ---- Environment Variables ------------------------------------------------
  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      COSMIC_DATA_CONTROL_ENABLED = "1";
      # Emoji list for the launcher's emoji picker (":" mode, SUPER period).
      HCS_EMOJI_FILE = "${pkgs.unicode-emoji}/share/unicode/emoji/emoji-test.txt";
    };
    variables = {
      QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct";
      EDITOR = "nvim";
      INTEL_DEBUG = "no32";
    };
    gnome.excludePackages = with pkgs; [
      gnome-tour
      gnome-console
      gnome-connections
      epiphany # web browser
      geary # email reader
      evince # document viewer
    ];
  };

  # ---- Fonts ----------------------------------------------------------------
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      corefonts
      nerd-fonts.fira-code
      cantarell-fonts
      roboto
      liberation_ttf
      openmoji-color
      material-symbols # shell icons
      fira-sans # shell UI font
      noto-fonts-color-emoji # emoji picker
    ];

    fontconfig = {
      hinting.autohint = true;
      defaultFonts = {
        emoji = ["OpenMoji Color"];
      };
    };
  };

  # ---- Shell Runtime Dependencies -------------------------------------------
  # Idle daemon as a systemd user service (started by graphical-session.target via UWSM).
  services.hypridle.enable = true;

  # quickshell itself is in home.nix (pkgs-unstable).
  environment.systemPackages =
    [hcs-calendar-events]
    ++ (with pkgs; [
      # Hyprland tools (hypridle comes from services.hypridle)
      hyprsunset
      hyprshot
      hyprpicker # color picker (SUPER SHIFT P)
      grim
      slurp
      swappy
      wf-recorder
      wl-screenrec
      # used by the shell
      playerctl
      brightnessctl
      ddcutil
      cliphist
      wl-clipboard
      wtype # emoji picker types into the focused window
      libqalculate # launcher calculator (qalc)
      libnotify # notify-send (low battery warnings)
      jq
      curl
      # apps opened from the bar popups
      pavucontrol
      networkmanagerapplet # nm-connection-editor
      gnome-calendar
      kdePackages.kdeconnect-kde # kdeconnect-indicator (tray)
      # icon theme used by the shell (QS_ICON_THEME=Pop, set in hypr/conf/environment.lua)
      pop-icon-theme
    ]);
}
