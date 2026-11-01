{
  config,
  pkgs,
  pkgs-unstable,
  hyprland,
  zen-browser,
  hyprdynamicmonitors,
  hyprshutdown,
  astal,
  nmrs,
  iloader,
  ...
}: {
  programs = {
    java.enable = true;
    java.package = pkgs-unstable.jdk;
    ags = {
      enable = false;
      # configDir = ../../../../config/ags;

      extraPackages = let
        # Create a shorthand for the astal libraries
        astalPkgs = astal.packages.${pkgs.stdenv.hostPlatform.system};
      in [
        # 1. Add the Astal Libraries individually
        astalPkgs.astal3
        astalPkgs.io
        astalPkgs.astal4
        astalPkgs.hyprland
        astalPkgs.wireplumber
        astalPkgs.battery
        astalPkgs.network
        astalPkgs.mpris
        astalPkgs.notifd

        # 2. Add normal packages using the standard pkgs prefix
        # (This is much safer than 'with pkgs;' when troubleshooting)
        pkgs.fzf
        pkgs.brightnessctl
        pkgs.libnotify
        pkgs.jq
        pkgs.curl
      ];
    };

    nix-index = {
      enable = true;
      enableFishIntegration = true;
    };
    fish.enable = false;
    direnv = {
      enable = true;
      enableBashIntegration = true; # see note on other shells below
      nix-direnv.enable = true;
      enableZshIntegration = true; # Optional, if you use Zsh sometimes
      enableFishIntegration = true; # This is TRUE by default if fish is enabled
    };
  };

  home.packages =
    (with pkgs; [
      # --- Desktop Utilities, Theming & GUI ---
      ranger
      trash-cli
      pwvucontrol
      zenity
      nwg-look
      wtype
      xkill
      xeyes
      mesa-demos
      kdePackages.gwenview
      # dunst
      # nwg-panel
      # wlogout  # replaced by the Quickshell power menu (hyprland-desktop.nix)
      # nmrs.packages.${pkgs.stdenv.hostPlatform.system}.default
      # hyprdynamicmonitors.packages.${pkgs.stdenv.hostPlatform.system}.default
      # iloader.packages.${pkgs.stdenv.hostPlatform.system}.default
      #ghostty.packages."${system}".default

      # --- Network & System Diagnostics ---
      ookla-speedtest
      arp-scan
      nitch
      jq

      # --- Development & Authentication ---
      git-credential-oauth
      pyenv
    ])
    ++ (with pkgs-unstable; [
      # --- Editors, IDEs & AI ---
      neovim
      vscode-fhs
      zed-editor-fhs
      arduino-ide
      lmstudio
      antigravity-cli
      antigravity-hub
      # kiro-cli

      # --- Terminal, Multiplexer & Shell Tools ---
      zellij
      fastfetch
      just

      # --- Web Browsers ---
      google-chrome
      brave-origin

      # --- Media, Graphics & Streaming ---
      celluloid
      kdePackages.kolourpaint
      yt-dlp
      sunshine
      uxplay
      plantuml
      # hpp2plantuml

      # --- Desktop UI, Shell & Window Management (Quickshell / Wayland) ---
      quickshell
      qt6.qtdeclarative
      wl-clipboard
      brightnessctl
      cliphist
      distrobox
      python3
      # nwg-panel

      # --- Screen Lock & Idle Management ---
      hyprlock
      swayidle
      swaylock-effects
      sunsetr
      # hyprcursor
      # rofi  # replaced by the Quickshell launcher
      # hyprsunset
      # hypridle
      # hyprshot
      # awww  # replaced by the Quickshell wallpaper slideshow
      # waybar  # replaced by the Quickshell bar

      # --- GNOME Extensions ---
      gnomeExtensions.ddterm
      gnomeExtensions.gsconnect
      gnomeExtensions.desktop-icons-ng-ding

      # --- Web & Language Development Tooling ---
      nodejs
      yarn
      tree-sitter
    ]);

  services.kdeconnect.enable = true;
  services.blueman-applet.enable = false;
}
