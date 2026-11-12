# NixOS Flake Documentation

This repository contains the NixOS flake configuration for `matevono` (laptop) and `homelab` (home server).

## Structure

```text
.
├── flake.nix                  # Flake inputs and nixosConfigurations
├── flake.lock
├── AGENTS.md                  # Instructions for AI coding agents
├── docs/                      # Project documentation
│   ├── common.md              # Shared module (modules/common.nix)
│   ├── matevono.md            # Laptop host (hosts/matevono/)
│   └── homelab.md             # Server host (hosts/homelab/)
├── modules/
│   └── common.nix             # Shared system settings, nix-ld, Tailscale, CLI tools
└── hosts/
    ├── matevono/              # Laptop configuration + Home Manager
    └── homelab/               # Server configuration, services, backups, Docker configs
```

## Flake Inputs & Hosts

Defined in `flake.nix` for `x86_64-linux`:

| Input | Source | Purpose |
| --- | --- | --- |
| `nixpkgs` | `NixOS/nixpkgs/nixos-26.05` | Base package set for `homelab` |
| `nixpkgs-unstable` | `NixOS/nixpkgs/nixos-unstable` | Base system for `matevono`, Home Manager, and `pkgs-unstable` overlays |
| `home-manager` | `nix-community/home-manager` | User environment management for `mate` on `matevono` |
| `winapps` | `winapps-org/winapps` | Windows app integration packages on `matevono` |
| `vscode-server` | `nix-community/nixos-vscode-server` | Remote VS Code server support on `homelab` |

### `nixosConfigurations`

- **`matevono`**: Built with `nixpkgs-unstable`, imports `hosts/matevono/` and `home-manager` (`hosts/matevono/home.nix`). See [matevono.md](matevono.md).
- **`homelab`**: Built with `nixpkgs` (26.05) + `pkgs-unstable` via `specialArgs`, imports `vscode-server` and `hosts/homelab/`. See [homelab.md](homelab.md).

## Common Commands

```bash
# Rebuild and switch local host
sudo nixos-rebuild switch --flake .#matevono
sudo nixos-rebuild switch --flake .#homelab

# Dry-build without activating
nixos-rebuild dry-build --flake .#matevono

# Format Nix files
alejandra .

# Update flake inputs
nix flake update
```
