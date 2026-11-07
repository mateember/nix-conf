{
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: {
  nixpkgs.config.allowInsecurePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "ventoy"
    ];

  programs = {
    fish.package = pkgs-unstable.fish;
    zsh.enable = true;
    fuse.userAllowOther = true;

    steam = {
      enable = true;
      remotePlay.openFirewall = true;
    };

    nm-applet.enable = false;
    xfconf.enable = true;
    dconf.enable = true;

    nautilus-open-any-terminal = {
      enable = true;
      terminal = "kitty";
    };

    thunar = {
      enable = true;
      plugins = with pkgs-unstable; [
        thunar-archive-plugin
        thunar-vcs-plugin
        thunar-media-tags-plugin
      ];
    };
  };

  documentation.dev.enable = true;

  environment.systemPackages =
    (with pkgs; [
      # --- Core CLI & System Utilities ---
      nano
      curl
      which
      file
      tree
      ripgrep
      fd
      fzf
      lsof
      rar
      e2fsprogs
      ventoy

      # --- Hardware Diagnostics, Monitoring & Low-level ---
      pciutils
      usbutils
      acpi
      lm_sensors
      ddcutil
      edid-decode
      efibootmgr
      v4l-utils
      libva-utils

      # --- Networking, Security & Polkit ---
      socat
      netcat-openbsd
      dig
      strongswan
      networkmanager-strongswan
      polkit_gnome
      libsecret

      # --- Audio, Video & Codecs ---
      alsa-utils
      pavucontrol
      pamixer
      playerctl
      vlc
      jellyfin-ffmpeg
      sox

      # --- Desktop & GUI Integration (KDE / GNOME / Hyprland) ---
      nautilus
      nautilus-python
      gnome-tweaks
      evince
      snixembed
      libnotify
      mutter
      gjs
      libsixel
      kdePackages.dolphin
      kdePackages.plasma-integration
      kdePackages.qtstyleplugin-kvantum
      kdePackages.kdecoration
      kdePackages.kwallet
      kdePackages.kwalletmanager
      kdePackages.kwallet-pam
      kdePackages.extra-cmake-modules
      sddm-sugar-dark
      fuse
      sshfs-fuse
      icu
      taler-sync
      appimage-run

      # --- Development Tools, Compilers & Libraries ---
      nix-prefetch-git
      gnumake
      cmake
      clang
      llvm
      lld
      gdb
      valgrind
      flex
      bison
      elfutils
      tinycc
      libxml2
      uv
      gfortran
      (octaveFull.withPackages (opkgs: with opkgs; [symbolic control io signal]))
      texliveFull
      xterm
      man-pages
      man-pages-posix

      # --- SDR & Radio ---
      rtl-sdr
    ])
    ++ (with pkgs-unstable; [
      # --- Terminals & CLI Utilities ---
      kitty
      ghostty
      kdePackages.konsole
      bat
      tldr
      bc
      geekbench

      # --- Wayland, Desktop & Qt Theming ---
      wl-clipboard-rs
      xwayland-satellite
      qt6Packages.qt6ct
      kdePackages.kirigami
      kdePackages.okular

      # --- Applications, Browsers & Remote Access ---
      firefox
      github-desktop
      freerdp
      mangohud

      # --- Mobile Device Tools (Apple & Android) ---
      android-tools
      libimobiledevice
      idevicerestore
      ifuse
    ]);
}
