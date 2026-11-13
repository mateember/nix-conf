{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  t3code,
  ...
}: let
  # Wrap pre-built quickshell with qtmultimedia (native video/APNG wallpapers)
  # and qtimageformats (animated WebP decoding) without recompiling Quickshell.
  quickshellWithMedia = pkgs-unstable.symlinkJoin {
    name = "quickshell-with-media";
    paths = [pkgs-unstable.quickshell];
    nativeBuildInputs = [pkgs-unstable.makeWrapper];
    postBuild = ''
      for bin in $out/bin/qs $out/bin/quickshell; do
        [ -e "$bin" ] && wrapProgram "$bin" \
          --prefix QT_PLUGIN_PATH : "${pkgs-unstable.qt6.qtmultimedia}/lib/qt-6/plugins:${pkgs-unstable.qt6.qtimageformats}/lib/qt-6/plugins" \
          --prefix NIXPKGS_QT6_QML_IMPORT_PATH : "${pkgs-unstable.qt6.qtmultimedia}/lib/qt-6/qml"
      done
    '';
  };
in {
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = "mate";
    homeDirectory = "/home/mate";
    stateVersion = "25.11";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs = {
    git = {
      enable = true;
      settings = {
        credential.helper = lib.mkForce "gh";
      };
    };
    gh.enable = true;

    java = {
      enable = true;
      package = pkgs-unstable.jdk;
    };

    nix-index = {
      enable = true;
      enableFishIntegration = true;
    };

    fish.enable = false;

    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
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
      kiro-fhs
      opencode
      t3code.packages.x86_64-linux.t3code-nightly

      # --- Terminal, Multiplexer & Shell Tools ---
      zellij
      fastfetch
      just

      # --- Web Browsers ---
      # google-chrome
      # brave-origin

      # --- Media, Graphics & Streaming ---
      celluloid
      kdePackages.kolourpaint
      yt-dlp
      sunshine
      uxplay
      plantuml

      # --- Desktop UI, Shell & Window Management (Quickshell / Wayland) ---
      quickshellWithMedia
      qt6.qtdeclarative
      wl-clipboard
      brightnessctl
      cliphist
      distrobox
      python3

      # --- Screen Lock & Idle Management ---
      hyprlock
      swayidle
      swaylock-effects
      sunsetr

      # --- GNOME Extensions ---
      # gnomeExtensions.ddterm
      # gnomeExtensions.gsconnect
      # gnomeExtensions.desktop-icons-ng-ding

      # --- Web & Language Development Tooling ---
      nodejs
      yarn
      tree-sitter
    ]);

  services.kdeconnect.enable = true;
  services.blueman-applet.enable = false;

  # ---- Bing Daily Wallpaper Service & Timer ---------------------------------
  systemd.user = {
    services.bing-wallpaper = {
      Unit = {
        Description = "Download Bing Daily Wallpaper";
        After = ["network-online.target"];
        Wants = ["network-online.target"];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash ${config.home.homeDirectory}/.scripts/bingpaper.sh";
      };

      Install = {
        WantedBy = ["default.target"];
      };
    };

    timers.bing-wallpaper = {
      Unit = {
        Description = "Run Bing Wallpaper script daily";
      };

      Timer = {
        OnCalendar = "daily";
        Persistent = true;
        Unit = "bing-wallpaper.service";
      };

      Install = {
        WantedBy = ["timers.target"];
      };
    };
  };
}
