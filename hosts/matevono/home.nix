{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: {
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
      quickshell
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
