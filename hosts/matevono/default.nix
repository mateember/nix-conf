{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../modules/common.nix
    ./desktop.nix
    ./packages.nix
    ./virtualisation.nix
  ];

  # ---- Hardware & Lenovo Yoga 14IMH9 Quirks ---------------------------------
  hardware = {
    bluetooth.enable = true; # enables support for Bluetooth
    bluetooth.powerOnBoot = true;
    bluetooth.settings.General.Experimental = true;

    sane = {
      enable = true;
      extraBackends = [pkgs.sane-airscan];
      openFirewall = true;
    };

    xone.enable = true;
    xpadneo.enable = true;

    # External monitor brightness (DDC/CI)
    i2c.enable = true;

    firmware = [
      pkgs.sof-firmware
      (
        pkgs.runCommand "customedid.bin" {compressFirmware = false;} ''
          mkdir -p $out/lib/firmware/edid
          cp "${./assets/customedid.bin}" $out/lib/firmware/edid/customedid.bin
        ''
      )
    ];

    graphics = {
      enable = true;
      package = pkgs-unstable.mesa;
      package32 = pkgs-unstable.pkgsi686Linux.mesa;

      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-compute-runtime # OpenCL / Level-Zero support for Arc GPU
        libvdpau-va-gl
        vpl-gpu-rt
        intel-media-driver
        intel-vaapi-driver
        level-zero # Low-overhead hardware API
        openvino
      ];
    };
  };

  # ---- Flake & Cachix Settings ----------------------------------------------
  nix.settings = {
    substituters = [
      "https://cosmic.cachix.org/"
      "https://hyprland.cachix.org"
      "https://winapps.cachix.org/"
    ];
    trusted-substituters = [
      "https://hyprland.cachix.org"
    ];
    trusted-public-keys = [
      "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "winapps.cachix.org-1:HI82jWrXZsQRar/PChgIx1unmuEsiQMQq+zt05CD36g="
    ];
    download-buffer-size = 1024288000;
  };

  # ---- Boot & Kernel --------------------------------------------------------
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = with config.boot.kernelPackages; [xone v4l2loopback xpadneo acpi_call];
    blacklistedKernelModules = ["xpad"];
    initrd.kernelModules = ["i915"];
    # initrd.kernelModules = ["xe"]; # xe: re-enable once stable on Meteor Lake (see kernelParams)
    kernelParams = [
      "splash"
      "drm.edid_firmware=eDP-1:edid/customedid.bin"
      "drm_kms_helper.edid_firmware=eDP-1:edid/customedid.bin"
      "video=eDP-1:e"

      # 1. Switch from i915 to Xe
      # Disabled: xe on Meteor Lake causes "TLB invalidation fence timeout"
      # desktop freezes (0.5-1.5s). Re-enable (and initrd "xe") once xe is stable on MTL.
      # "i915.force_probe=!*"
      # "xe.force_probe=*"

      # 2. Disable PSR for both (Safe to keep both for transitions)
      "i915.enable_psr=0"
      # "xe.enable_psr=0"
      "iommu.passthrough=1"
    ];

    kernelModules = ["i2c-dev"];

    plymouth = {
      enable = true;
      theme = "darth_vader";
      themePackages = with pkgs; [
        # By default we would install all themes
        (adi1090x-plymouth-themes.override {
          selected_themes = ["darth_vader"];
        })
      ];
    };

    loader = {
      efi.efiSysMountPoint = "/boot/"; # ← use the same mount point here.

      limine = {
        enable = true;
        secureBoot.enable = true;
        enableEditor = false;
        maxGenerations = 15;
        extraEntries = ''
          /Windows
          protocol: efi_chainload
          path: boot():///EFI/Microsoft/Boot/bootmgfw.efi
        '';
        style = {
          wallpapers = [./assets/im1.png ./assets/im2.jpeg];
          wallpaperStyle = "stretched";
          interface.resolution = "2880x1800";
          graphicalTerminal = {
            font.scale = "3x3"; # This makes the font readable on 2.8K @ 14"
            margin = 100; # Centers the menu better on high-res screens
            marginGradient = 20;

            # Colors: Nord Palette
            background = "7f2e34CC";
            foreground = "d8dee9";
            palette = "2e3440;bf616a;a3be8c;ebcb8b;81a1c1;b48ead;88c0d0;d8dee9";

            # Bright variants for better contrast
            brightForeground = "eceff4";
            brightBackground = "3b4252";
          };
        };
      };
    };
  };

  # ---- Networking & Firewall ------------------------------------------------
  networking = {
    useDHCP = false;
    hostName = "matevono";
    networkmanager = {
      enable = true;
      wifi.backend = "wpa_supplicant";
      plugins = [pkgs.networkmanager-strongswan];
      dns = "systemd-resolved";
    };

    nftables.enable = true;
    firewall = {
      enable = true;
      allowedUDPPorts = [24642];
      allowedTCPPorts = [47984 47989 47990 48010 3389];

      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
        {
          from = 47998;
          to = 48000;
        }
      ];
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      trustedInterfaces = ["virbr0" "vnet3"];
    };
  };

  # ---- Systemd & Sleep Workarounds ------------------------------------------
  systemd = {
    services = {
      upower.serviceConfig = {
        ProtectSystem = lib.mkForce "no";
        PrivateTmp = lib.mkForce false;
      };
      # gnome-remote-desktop.wantedBy = ["graphical.target"];
      virtqemud.serviceConfig.TimeoutStopSec = "5s";
      virtnetworkd.serviceConfig.TimeoutStopSec = "5s";

      # Workaround: Sometimes xhci driver will become malfunctional after resuming from hibernate / suspend.
      #             This will cause (almost) all external devices stop working.
      #             A simple reset is enough to bring external devices alive :)
      #
      #             Note: to avoid unnecessary resets, we firstly check if integrated camera is presented
      #                   (Should always be there as it was built into machine!).
      #                   If not, just do the reset.
      workaround-reset-xhci-driver-after-resume-if-needed = {
        script = ''
          result=$(${pkgs.usbutils}/bin/lsusb | ${pkgs.gnugrep}/bin/grep Luxvisions || true)
          if [[ -z $result ]]; then
            ${pkgs.kmod}/bin/rmmod xhci_pci xhci_hcd
            ${pkgs.kmod}/bin/modprobe xhci_pci xhci_hcd
          fi
        '';
        after = [
          "suspend.target"
          "hibernate.target"
          "hybrid-sleep.target"
        ];
        wantedBy = [
          "suspend.target"
          "hibernate.target"
          "hybrid-sleep.target"
          "multi-user.target"
        ];
      };
    };

    # Workaround: Lenovo seems write bad acpi power management firmware. Without this config,
    #             suspend (to ram / disk) will simply reboot instead of power off. :(
    sleep.settings = {
      Sleep = {
        HibernateMode = "shutdown";
      };
    };
  };

  # ---- Locale & Console -----------------------------------------------------
  i18n.supportedLocales = [
    "C.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
    "hu_HU.UTF-8/UTF-8"
  ];
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true; # use xkb.options in tty.
  };

  # ---- Users ----------------------------------------------------------------
  users = {
    groups.libvirtd.members = ["root"];
    users.mate = {
      extraGroups = [
        "mate"
        "flatpak"
        "disk"
        "dialout"
        "qemu"
        "kvm"
        "libvirtd"
        "fuse"
        "i2c"
        "sshd"
        "users"
        "networkmanager"
        "wheel"
        "audio"
        "video"
        "render"
        "tty"
        "libvirt"
        "docker"
        "podman"
        "plugdev"
        "adbusers"
      ];
      shell = pkgs.bash;
    };
  };

  # ---- Laptop Power & System Services ---------------------------------------
  services = {
    pulseaudio.enable = false;
    power-profiles-daemon.enable = false;
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        PLATFORM_PROFILE_ON_AC = "performance";
        PLATFORM_PROFILE_ON_BAT = "low-power";
        MEM_SLEEP_ON_AC = "s2idle";
        MEM_SLEEP_ON_BAT = "s2idle";
        PCIE_ASPM_ON_AC = "performance";
        PCIE_ASPM_ON_BAT = "powersave";
        SOUND_POWER_SAVE_ON_AC = "0";
        SOUND_POWER_SAVE_ON_BAT = "1";
        SOUND_POWER_SAVE_CONTROLLER = "Y";
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 100;
        # Optional: force energy-saving bias for both core types
        RUNTIME_PM_ON_BAT = "auto";
        USB_AUTOSUSPEND = 1;
      };
    };
    upower = {
      enable = true;
      percentageLow = 15;
      percentageCritical = 10;
      percentageAction = 4; # This is the "Save Me" threshold
      criticalPowerAction = "Hibernate";
    };

    fwupd.enable = true;
    hardware.bolt.enable = true;
    thermald.enable = true;

    resolved = {
      enable = true;
      settings = {
        Resolve = {
          FallbackDNS = ["1.1.1.1" "8.8.8.8"];
          DNSSEC = "allow-downgrade";
        };
      };
    };

    usbmuxd.enable = true;

    syncthing = {
      enable = true;
      openDefaultPorts = true;
      user = "mate";
      dataDir = "/home/mate/";
      configDir = "/home/mate/.config/syncthing";
    };

    tailscale.useRoutingFeatures = "both";

    printing = {
      enable = true;
      drivers = [pkgs.epson-escpr];
    };
  };

  environment.etc."strongswan.conf".text = ''
    charon-nm {
      plugins {
        include ${pkgs.strongswan}/etc/strongswan.d/charon/*.conf
      }
      # Megadjuk a Nix Store-ban lévő plugin könyvtárat
      plugin_dir = ${pkgs.strongswan}/lib/ipsec/plugins
    }
  '';

  # ---- Sudo & Security Wrappers ---------------------------------------------
  security = {
    rtkit.enable = true;

    sudo = {
      enable = true;
      extraRules = [
        {
          commands = [
            {
              command = "${pkgs.systemd}/bin/systemctl suspend";
              options = ["NOPASSWD"];
            }
            {
              command = "/run/current-system/sw/bin/tlp";
              options = ["NOPASSWD"];
            }
            {
              command = "/run/current-system/sw/bin/tlp-stat";
              options = ["NOPASSWD"];
            }
            {
              command = "${pkgs.systemd}/bin/reboot";
              options = ["NOPASSWD"];
            }
            {
              command = "${pkgs.systemd}/bin/poweroff";
              options = ["NOPASSWD"];
            }
            {
              command = "/run/current-system/sw/bin/tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004\\:00/conservation_mode";
              options = ["NOPASSWD"];
            }
            {
              command = "/run/current-system/sw/bin/tee /sys/firmware/acpi/platform_profile";
              options = ["NOPASSWD"];
            }
            {
              command = "/run/current-system/sw/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference";
              options = ["NOPASSWD"];
            }
            {
              command = "/home/mate/dotfiles/scripts/tlpmodes.sh";
              options = ["NOPASSWD"];
            }
            {
              command = "/home/mate/scripts/winapps/bin/winapps";
              options = ["NOPASSWD"];
            }
          ];
          users = ["mate"];
          groups = ["wheel"];
        }
      ];
      extraConfig = with pkgs; ''
        Defaults:picloud secure_path="${lib.makeBinPath [
          systemd
        ]}:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
      '';
    };
    wrappers.sunshine = {
      owner = "root";
      group = "root";
      capabilities = "cap_sys_admin+p";
      source = "${pkgs.sunshine}/bin/sunshine";
    };
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
