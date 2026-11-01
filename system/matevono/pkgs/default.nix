{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  # hyprland,
  winapps,
  inputs,
  ...
}: {
  #disabledModules = ["programs/wayland/hyprland.nix"];

  imports = [
    # ./overlays/howdy.nix
    #"${inputs.nixpkgs-unstable}/nixos/modules/programs/wayland/hyprland.nix"
    ./nixld.nix
  ];

  nixpkgs.config.allowInsecurePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "ventoy"
    ];

  #Chaotic AUR
  chaotic.mesa-git.enable = false;
  chaotic.mesa-git.fallbackSpecialisation = false;

  programs = {
    fish.enable = true;
    fish.package = pkgs-unstable.fish;
    zsh.enable = true;
    fuse.userAllowOther = true;
    niri = {
      package = pkgs-unstable.niri;
      enable = false;
      useNautilus = true;
    };
    gtklock = {
      enable = false;
      modules = with pkgs-unstable; [gtklock-playerctl-module gtklock-powerbar-module];
      package = pkgs-unstable.gtklock;
    };
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
    };
    nm-applet.enable = false;
    hyprland = {
      enable = true;
      xwayland.enable = true;
      # package = hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      # portalPackage = hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      package = pkgs-unstable.hyprland;
      portalPackage = pkgs-unstable.xdg-desktop-portal-hyprland;
    };
    virt-manager.enable = true;
    # steam.extraCompatPackages = [pkgs.proton-ge-bin];
    xfconf.enable = true;
    dconf.enable = true;
    nautilus-open-any-terminal = {
      enable = true;
      terminal = "kitty";
    };
    thunar = {
      enable = true;
      plugins = with pkgs-unstable; [thunar-archive-plugin thunar-vcs-plugin thunar-media-tags-plugin];
    };
  };

  stylix.enable = false;
  # System packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages =
    (with pkgs; [
      # --- Core CLI & System Utilities ---
      vim
      nano
      wget
      curl
      which
      file
      tree
      ripgrep
      fd
      fzf
      zoxide
      starship
      btop
      killall
      lsof
      rclone
      unzip
      rar
      ventoy

      # --- Hardware Diagnostics, Monitoring & Low-level ---
      pciutils
      usbutils
      lshw
      dmidecode
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

      # --- Virtualization, Containers & Windows Emulation ---
      qemu
      gnome-boxes
      virt-viewer
      virtio-win
      spice
      spice-gtk
      spice-protocol
      win-spice
      winapps.packages."${pkgs.stdenv.hostPlatform.system}".winapps
      winapps.packages."${pkgs.stdenv.hostPlatform.system}".winapps-launcher # optional
      podman-compose
      podman-tui
      dive
      appimage-run

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
      #(callPackage ./sddm-bluish {}).sddm-bluish
      #(callPackage ./sddm-sugarcandy {}).sddm-sugarcandy
      fuse
      sshfs-fuse
      icu
      taler-sync

      # --- Development Tools, Compilers & Libraries ---
      git
      lazygit
      nix-prefetch-git
      gcc
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
      # gnuradio
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
      #lact
      #kdePackages.polkit-kde-agent-1
      #alacritty

      # --- Applications, Browsers & Remote Access ---
      firefox
      github-desktop
      freerdp
      mangohud
      # jetbrains.clion
      # jetbrains.pycharm-professional

      # --- Mobile Device Tools (Apple & Android) ---
      android-tools
      libimobiledevice
      idevicerestore
      ifuse
    ]);

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-console
    gnome-connections
    epiphany # web browser
    geary # email reader. Up to 24.05. Starting from 24.11 the package name is just geary.
    evince # document viewer
  ];
  documentation.dev.enable = true;
}
