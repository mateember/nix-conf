# Hyprland desktop with the Quickshell shell (COSMIC theme).
# The dotfiles (~/dotfiles/config/hypr, ~/dotfiles/config/quickshell) hold the configs;
# this module provides the session, PAM/portal/hardware bits and every runtime dependency.
# Developed in ~/hypr-cosmic-shell (flake.nix lists the same packages for testing there).
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [./calendar-events.nix]; # calendar events in the shell's clock popup

  # ---- Session -------------------------------------------------------------
  # UWSM-managed session ("Hyprland (UWSM)" in cosmic-greeter). UWSM starts
  # graphical-session.target, which xdg-desktop-portal needs (screen sharing, file pickers).
  # Hyprland reads ~/.config/hypr/hyprland.lua.
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  # ---- Lock screen ---------------------------------------------------------
  # hyprlock authenticates through the `hyprlock` PAM service (without it, it falls back to `su`).
  security.pam.services.hyprlock = {};

  # ---- Polkit --------------------------------------------------------------
  # The shell is the polkit agent in Hyprland. Keep polkit-gnome (defined in configuration.nix,
  # started with graphical-session.target) for the other desktops only.
  systemd.user.services.polkit-gnome-authentication-agent-1.unitConfig.ConditionEnvironment = "!XDG_CURRENT_DESKTOP=Hyprland";

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

  # ---- KWallet -------------------------------------------------------------
  # PAM (cosmic-greeter/greetd) stores the login password; pam_kwallet_init must run inside the
  # session to hand it to kwalletd. Its autostart entry has X-systemd-skip=true, so UWSM never
  # starts it: run it as a user service for Hyprland sessions instead.
  systemd.user.services.hyprland-kwallet-unlock = {
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

  # ---- Portals -------------------------------------------------------------
  # Hyprland portal for screen sharing, COSMIC's file chooser, KWallet for secrets (Flatpak apps).
  # Note: ~/.config/xdg-desktop-portal/hyprland-portals.conf overrides this file if it exists.
  xdg.portal.config.hyprland = {
    default = ["hyprland" "gtk"];
    "org.freedesktop.impl.portal.FileChooser" = ["cosmic"];
    "org.freedesktop.impl.portal.Secret" = ["kwallet"];
  };

  # ---- External monitor brightness (DDC/CI) ---------------------------------
  hardware.i2c.enable = true;
  users.users.mate.extraGroups = ["i2c"];

  # ---- Shell runtime dependencies ---------------------------------------------
  # quickshell itself is in home/pkgs (pkgs-unstable).
  environment.systemPackages = with pkgs; [
    # Hyprland tools
    hypridle
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
  ];

  fonts.packages = with pkgs; [
    material-symbols # shell icons
    fira-sans # shell UI font
    noto-fonts-color-emoji # emoji picker
    # nerd-fonts.jetbrains-mono is already in configuration.nix
  ];

  # Emoji list for the launcher's emoji picker (":" mode, SUPER period).
  environment.sessionVariables.HCS_EMOJI_FILE = "${pkgs.unicode-emoji}/share/unicode/emoji/emoji-test.txt";
}
