# Agent Instructions

## Repository Overview

This repository is a multi-host NixOS flake ([flake.nix](flake.nix)) managing two `x86_64-linux` hosts:

- `matevono` (`hosts/matevono/`) — Lenovo Yoga 14IMH9 laptop running `nixos-unstable`, Hyprland (UWSM) + Quickshell, COSMIC desktop/greeter, and Home Manager.
- `homelab` (`hosts/homelab/`) — Home server running `nixos-26.05`, Nginx reverse proxy, CUPS/Avahi, Samba, Docker Compose services, and automated off-site backups.
- `modules/common.nix` — Shared NixOS configuration imported by all hosts.
- `docs/` — Project documentation describing what each host and module does.

## Working Guidelines

- **Git workflow**: Always commit your changes to git, or create a new branch if needed (for example, when working on a separate feature/fix or when the current branch already has unrelated work). Do not leave completed changes uncommitted unless the user explicitly asks not to commit.
- **Formatting**: Format modified `.nix` files with `alejandra`.
- **Verification**: After editing Nix files, validate evaluation/builds when possible (e.g., `nix flake check` or `nixos-rebuild dry-build --flake .#<host>`).
- **External dotfiles**: `matevono` desktop configs (Hyprland, Quickshell, lock screen) live in `~/dotfiles` and `~/hypr-cosmic-shell`, not in this repository. Keep system-level PAM stacks, portals, systemd user units, and runtime packages in `hosts/matevono/desktop.nix` aligned with those configs.
- **Documentation**: Keep `docs/` accurate to the active configuration. Document what modules and services currently do, and omit disabled or deprecated configurations.
