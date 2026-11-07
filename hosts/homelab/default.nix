{pkgs, ...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../modules/common.nix
    ./services.nix
    ./csumpi-backup.nix
  ];

  nix.gc.options = "--delete-older-than 14d";

  # ---- Bootloader & Kernel --------------------------------------------------
  boot = {
    initrd.systemd.tpm2.enable = false;
    kernelModules = ["v4l2loopback"];
    kernelParams = [];
    loader = {
      efi.efiSysMountPoint = "/boot";
      grub = {
        efiSupport = true;
        useOSProber = true;
        device = "nodev";
      };
    };
  };

  # ---- Networking & Firewall ------------------------------------------------
  networking = {
    hostName = "homelab";
    networkmanager.enable = true;

    firewall = {
      enable = true;
      allowPing = true;
      trustedInterfaces = [];
      allowedTCPPorts = [443 61208 631 26000 16000 10809 3260 12049 10445];
      allowedUDPPorts = [67 68 69 4011];
      allowedTCPPortRanges = [];
      allowedUDPPortRanges = [
        {
          from = 26910;
          to = 26912;
        }
      ];
    };
  };

  # ---- Locale & Console -----------------------------------------------------
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "hu_HU.UTF-8";
    LC_IDENTIFICATION = "hu_HU.UTF-8";
    LC_MEASUREMENT = "hu_HU.UTF-8";
    LC_MONETARY = "hu_HU.UTF-8";
    LC_NAME = "hu_HU.UTF-8";
    LC_NUMERIC = "hu_HU.UTF-8";
    LC_PAPER = "hu_HU.UTF-8";
    LC_TELEPHONE = "hu_HU.UTF-8";
    LC_TIME = "hu_HU.UTF-8";
  };

  services.xserver.xkb.variant = "";
  console.keyMap = "hu";

  # ---- Users ----------------------------------------------------------------
  users = {
    groups.www-data.gid = 33;
    users.mate = {
      description = "Máté Tamás Kiss";
      extraGroups = ["networkmanager" "wheel" "docker" "www-data"];
      shell = pkgs.fish;
      linger = true;
      packages = [];
    };
  };

  security.tpm2.enable = false;

  # ---- Programs & Packages --------------------------------------------------
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  environment.systemPackages = with pkgs; [
    neovim
    fish
    fastfetch
    speedtest-cli
    zellij
    tmux
    bat
    gh
    trash-cli
    wirelesstools
    glances
    ddclient
    iw
    steamcmd
    distrobox
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
  ];

  # ---- Systemd Units, Services & Timers -------------------------------------
  systemd.units."dev-tpmrm0.device".enable = false;
  systemd = {
    tpm2.enable = false;
    user = {
      timers = {
        "rclone-sync" = {
          wantedBy = ["timers.target"];
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
          };
        };
      };
      services = {
        "kshare_home" = {
          enable = true;
          after = ["network.target"];
          wantedBy = ["default.target"];
          description = "Http File server";
          serviceConfig = {
            Type = "simple";
            ExecStart = ''/home/mate/goserver/ghfs -l 8181 -r /home/mate --global-upload --global-mkdir --global-delete --global-archive'';
          };
        };

        "rclone-sync" = {
          enable = true;
          description = "rclone Sync Gdrive to Onedrive";
          after = ["network-online.target"];
          wantedBy = ["network-online.target"];

          serviceConfig = {
            Type = "oneshot";
            ExecStart = ''
              ${pkgs.rclone}/bin/rclone sync GDrive101:/onyx BMEOffice:/onyx  -v '';
            Environment = ["PATH=/run/wrappers/bin/:$PATH"];
          };
        };

        "glances-manual" = {
          description = "Glances manual";
          enable = true;
          after = ["multi-user.target" "network.target"];
          serviceConfig = {
            Type = "simple";
            ExecStart = ''/run/current-system/sw/bin/glances --port 61208 --webserver --disable-plugin gpu'';
          };
          wantedBy = ["default.target"];
        };
      };
    };

    services = {
      "dynadotdns" = {
        enable = true;
        after = ["network.target"];
        description = "Update Dynadot DDNS for hl.kmate.org";
        wantedBy = ["default.target"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = " /home/mate/randomfiles/ddclient/update.sh";
        };
      };

      "dynadotcert" = {
        description = "Update Dynadot SSL certificate";
        wantedBy = ["default.target"];
        after = ["network.target"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "/run/current-system/sw/bin/bash /home/mate/randomfiles/scripts/certcurl.sh";
        };
      };

      "set_fb_blank_1" = {
        description = "Set framebuffer blank state to 1";
        enable = true;
        after = ["multi-user.target"];
        script = "echo 1 > /sys/class/graphics/fb0/blank";
        wantedBy = ["multi-user.target"];
      };
    };

    timers = {
      "dynadotdns" = {
        description = "Run Dynadot DDNS updater every 5 minutes";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "1min";
          OnUnitActiveSec = "5min";
          Persistent = true;
        };
      };
      "dynadotcert" = {
        description = "Monthly Dynadot SSL certificate update";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "monthly";
          Persistent = true;
        };
      };
    };
  };

  system.stateVersion = "24.11"; # Did you read the comment?
}
