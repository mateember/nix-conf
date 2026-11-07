{
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: {
  # Flake and Nix settings
  nix = {
    settings = {
      auto-optimise-store = true;
      cores = 0;
      max-jobs = "auto";
      allowed-users = ["mate"];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = lib.mkDefault "--delete-older-than 7d";
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };

  nixpkgs.config.allowUnfree = true;

  # Shared kernel & TCP BBR network tuning
  boot = {
    consoleLogLevel = 3;
    kernelModules = ["tcp_bbr"];
    kernel.sysctl = {
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.default_qdisc" = "fq";
      "net.core.wmem_max" = 1073741824;
      "net.core.rmem_max" = 1073741824;
      "net.ipv4.tcp_rmem" = "4096 87380 1073741824";
      "net.ipv4.tcp_wmem" = "4096 87380 1073741824";
    };
    loader.efi.canTouchEfiVariables = true;
  };

  # Time zone & locale settings
  time.timeZone = "Europe/Budapest";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb.layout = "hu";

  # Base user group & account
  users = {
    groups.mate = {
      name = "mate";
      gid = 1000;
    };
    users.mate = {
      isNormalUser = true;
    };
  };

  # Tailscale mesh VPN
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  programs.fish.enable = true;

  # nix-ld for running unpatched dynamic binaries
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs-unstable; [
      SDL
      SDL2
      SDL2_image
      SDL2_mixer
      SDL2_ttf
      SDL_image
      SDL_mixer
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      bzip2
      cairo
      cups
      curl
      curlWithGnuTls
      dbus
      dbus-glib
      desktop-file-utils
      e2fsprogs
      expat
      flac
      fontconfig
      freeglut
      freetype
      fribidi
      fuse
      fuse3
      gdk-pixbuf
      glew_1_10
      glib
      gmp
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-ugly
      gst_all_1.gstreamer
      # gtk2
      harfbuzz
      icu
      keyutils.lib
      libGL
      libGLU
      libcaca
      libcanberra
      libcap
      libclang.lib
      libdbusmenu
      libdrm
      libgcrypt
      libgpg-error
      libidn
      libjack2
      libjpeg
      libmikmod
      libogg
      libpng
      libpulseaudio
      librsvg
      libsamplerate
      libthai
      libtheora
      libtiff
      libudev0-shim
      libusb1
      libuuid
      libvdpau
      libvorbis
      libvpx
      libxcrypt-legacy
      libxkbcommon
      libxml2
      mesa
      nspr
      nss
      openssl
      p11-kit
      pango
      pixman
      python3
      speex
      stdenv.cc.cc
      stdenv.cc.cc.lib
      zlib
      libglvnd
      egl-wayland
      tbb
      udev
      vulkan-loader
      wayland
      libice
      libsm
      libx11
      libxscrnsaver
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxft
      libxi
      libxinerama
      libxmu
      libxrandr
      libxrender
      libxt
      libxtst
      libxxf86vm
      libpciaccess
      libxcb
      libxcb-util
      libxcb-image
      libxcb-keysyms
      libxcb-render-util
      libxcb-wm
      xkeyboard-config
      xz
    ];
  };

  # Common CLI packages present on all hosts
  environment.systemPackages = with pkgs; [
    alejandra
    vim
    wget
    git
    lazygit
    starship
    zoxide
    btop
    killall
    rclone
    unzip
    lshw
    dmidecode
    gcc
    (pkgs.writeShellScriptBin "python" ''
      export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH
      exec ${pkgs.python3}/bin/python "$@"
    '')
  ];
}
