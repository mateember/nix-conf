# Host: `matevono`

`hosts/matevono/` configures the Lenovo Yoga 14IMH9 (Intel Meteor Lake) laptop using `nixpkgs-unstable` and Home Manager.

## Files

- `default.nix` — Hardware, boot/Limine, networking/firewall, power management, sleep workarounds, sudo rules, and core services.
- `desktop.nix` — Hyprland (UWSM) + Quickshell runtime environment, COSMIC desktop/greeter, PipeWire, Howdy/KWallet PAM, portals, and fonts.
- `packages.nix` — System-wide CLI tools, diagnostics, compilers, browsers, and GUI applications.
- `virtualisation.nix` — Libvirt/QEMU/KVM, Docker, and WinApps packages.
- `home.nix` — Home Manager configuration for `mate`.
- `hardware-configuration.nix` — Btrfs subvolumes (`nixroot` -> `/`, `home` -> `/home`, `Games` -> `/home/mate/Games`), vfat `/boot`, 34 GiB swapfile + zramSwap, Intel microcode, and `rtl-sdr`.
- `assets/` — Custom display EDID (`customedid.bin`) and Limine wallpaper images (`im1.png`, `im2.jpeg`).

## Boot, Graphics & Hardware (`default.nix`)

- **Kernel & GPU**: Uses `linuxPackages_latest` with `i915` in initrd (`i915.enable_psr=0`, `iommu.passthrough=1`) instead of `xe` (avoiding Meteor Lake TLB invalidation fence timeouts). Loads `customedid.bin` for `eDP-1` and uses `pkgs-unstable.mesa` (64-bit + 32-bit) with Intel Arc compute/media packages (`intel-compute-runtime`, `vpl-gpu-rt`, `intel-media-driver`, `intel-vaapi-driver`, `level-zero`, `openvino`).
- **Extra Kernel Modules & Peripherals**: `xone` and `xpadneo` for Xbox controllers (`xpad` blacklisted), `v4l2loopback`, `acpi_call`, `i2c-dev` (DDC/CI monitor brightness), `sof-firmware`, Bluetooth (with experimental features), and SANE (`sane-airscan`).
- **Bootloader & Plymouth**: Limine with Secure Boot enabled, 15 max generations, Nord-themed `2880x1800` UI, a Windows EFI chainload entry, and `darth_vader` Plymouth boot splash.
- **Substituters**: Adds Cachix caches for COSMIC, Hyprland, and WinApps.

## Networking, Power & Workarounds (`default.nix`)

- **Networking**: NetworkManager (`wpa_supplicant`, `networkmanager-strongswan` with `/etc/strongswan.conf`) and `systemd-resolved` (DNSSEC `allow-downgrade`, fallback DNS `1.1.1.1`/`8.8.8.8`).
- **Firewall (`nftables`)**: Opens ports for KDE Connect (`1714-1764` TCP/UDP), Sunshine/Moonlight (`47984`, `47989`, `47990`, `48010` TCP; `47998-48000` UDP), `24642` UDP, and `3389` TCP; trusts `virbr0` and `vnet3`.
- **Power Management**: TLP (AC `performance` / battery `powersave` and `low-power` platform profile, `s2idle`, USB autosuspend) and UPower (hibernates at 4% battery). Enables `fwupd`, Thunderbolt `bolt`, `thermald`, `usbmuxd`, `syncthing`, Tailscale exit/subnet routing (`both`), and CUPS (`epson-escpr`).
- **Sleep/Resume Workarounds**:
  - Sets `HibernateMode = "shutdown"` to prevent ACPI reboot-on-hibernate bugs.
  - `workaround-reset-xhci-driver-after-resume-if-needed` checks `lsusb` for the integrated `Luxvisions` camera after resume and reloads `xhci_pci`/`xhci_hcd` if missing.
- **Security**: Passwordless `sudo` rules for `systemctl suspend`/`reboot`/`poweroff`, TLP controls, battery conservation/platform profile sysfs paths, and `winapps`; `cap_sys_admin+p` wrapper for `sunshine`.

## Desktop & Authentication (`desktop.nix`)

- **Sessions**: Enables Hyprland (`withUWSM = true`, `xwayland.enable = true`) and COSMIC desktop with `cosmic-greeter`. External dotfiles in `~/dotfiles` supply the Hyprland and Quickshell configs.
- **Audio & Portals**: PipeWire (ALSA 32-bit, PulseAudio compat, 32-sample quantum) and `xdg-desktop-portal` configured for Hyprland screen sharing, COSMIC file chooser, and KWallet secret storage.
- **Howdy & KWallet PAM**:
  - `linux-enable-ir-emitter` (`video2`) + `howdy` using the IR camera by-path device (`dark_threshold = 75`, `timeout = 3`).
  - Global Howdy PAM is disabled so login via `cosmic-greeter`/`greetd` still uses a password and unlocks KWallet (`pam_kwallet_init` runs via the `hyprland-kwallet-unlock` user service in Hyprland).
  - Howdy is enabled on `qs-lock-face`, `hyprlock`, `swaylock`, `sudo`, `su`, `polkit-1`, and `systemd-run0`; `qs-lock` remains password-only so typing a password never blocks on a face scan.
- **Session Services & Helpers**:
  - `polkit-gnome-authentication-agent-1` runs only outside Hyprland (`!XDG_CURRENT_DESKTOP=Hyprland`); Quickshell handles polkit in Hyprland.
  - `services.hypridle` is scoped to Hyprland with system/user profile PATHs.
  - `hcs-calendar-events` wraps `~/.config/quickshell/scripts/calendar-events.py` with PyGObject and Evolution Data Server GI typelibs (`evolution-data-server`, `gnome-online-accounts`).

## Packages, Virtualisation & Home Manager

- **`packages.nix`**: Installs `fish` (`pkgs-unstable`), `zsh`, Steam (with Remote Play firewall), `nautilus` with `nautilus-open-any-terminal` (`kitty`), hardware/networking diagnostics, C/C++/Python/`octaveFull`/`texliveFull` toolchains, `rtl-sdr`, browsers (`firefox`, `brave-origin`), terminals (`kitty`, `ghostty`, `konsole`), and Android/iOS tools. Allows insecure `ventoy`.
- **`virtualisation.nix`**: Enables `libvirtd` (QEMU/KVM, `virtiofsd`, `swtpm`), `virt-manager`, SPICE USB redirection, `docker` (with `btrfs` storage driver), `winapps`, and `winapps-launcher`.
- **`home.nix` (`stateVersion = "25.11"`)**: Configures `git` (with `gh` credential helper), `gh`, `java`, `nix-index`, `direnv`/`nix-direnv`, IDEs/editors (`neovim`, `vscode-fhs`, `zed-editor-fhs`, `arduino-ide`, `lmstudio`, `antigravity-cli`, `antigravity-hub`, `kiro-fhs`, `opencode-desktop`), `quickshell` + lock/idle tools (`hyprlock`, `swayidle`, `swaylock-effects`, `sunsetr`), `kdeconnect`, and a daily `bing-wallpaper` user timer calling `~/.scripts/bingpaper.sh`.
