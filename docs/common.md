# Shared Module (`modules/common.nix`)

`modules/common.nix` is imported by both `matevono` and `homelab` to provide baseline system configuration.

## Nix & Store Management

- Enables `nix-command` and `flakes` experimental features.
- Enables `auto-optimise-store`, `keep-outputs`, `keep-derivations`, `cores = 0`, and `max-jobs = "auto"`.
- Grants `mate` `allowed-users` access.
- Enables weekly garbage collection (`--delete-older-than 7d` by default; `homelab` overrides this to `14d`).
- Allows unfree packages (`nixpkgs.config.allowUnfree = true`).

## Kernel & Network Tuning

- Sets `boot.consoleLogLevel = 3` and `boot.loader.efi.canTouchEfiVariables = true`.
- Loads `tcp_bbr` and configures TCP BBR congestion control (`bbr`), `fq` qdisc, and 1 GiB max socket buffers (`rmem_max`/`wmem_max`).

## Locale, User & VPN

- Time zone: `Europe/Budapest`.
- Default locale: `en_US.UTF-8`; XKB keyboard layout: `hu`.
- Defines the `mate` user (`uid`/group `mate` with `gid = 1000`).
- Enables `services.tailscale` with `openFirewall = true`.
- Enables `programs.fish`.

## `nix-ld` & Shared CLI Packages

- Enables `programs.nix-ld` populated with common graphics, Wayland/X11, audio, compression, and C/C++ runtime libraries from `pkgs-unstable`.
- Provides a `python` wrapper script in `environment.systemPackages` that exports `LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH` before invoking `python3`.
- Installs shared CLI utilities on all hosts: `alejandra`, `vim`, `wget`, `git`, `lazygit`, `starship`, `zoxide`, `btop`, `killall`, `rclone`, `unzip`, `lshw`, `dmidecode`, and `gcc`.
