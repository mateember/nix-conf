# Host: `homelab`

`hosts/homelab/` configures the home server on `nixpkgs` (`nixos-26.05`).

## Files

- `default.nix` — Boot, firewall, packages, user/system systemd services, and DDNS/SSL timers.
- `services.nix` — Docker, VS Code Server, Fail2ban, CUPS/Avahi, Nginx reverse proxy, and Samba.
- `csumpi-backup.nix` — Automated daily off-site backup pull over Tailscale.
- `hardware-configuration.nix` — ext4 `/` and `/mnt/khdd`, vfat `/boot`, 8 GiB swapfile, AMD microcode.
- `configs/docker-compose.yaml` — Containerized media, cloud, and dashboard stack.
- `configs/dashy_conf.yml` — Dashy homepage configuration.

## System & Custom Units (`default.nix`)

- **Boot & GC**: GRUB EFI (`useOSProber = true`), `v4l2loopback`, TPM2 disabled, and 14-day Nix store garbage collection (`--delete-older-than 14d`).
- **Firewall**: Opens TCP `443`, `61208`, `631`, `26000`, `16000`, `10809`, `3260`, `12049`, `10445` and UDP `67`, `68`, `69`, `4011`, `26910-26912`.
- **User `mate`**: Uses `fish`, `linger = true`, and belongs to `networkmanager`, `wheel`, `docker`, and `www-data` (`gid = 33`).
- **Systemd User Services/Timers** (for `mate`):
  - `kshare_home` — Serves `/home/mate` over HTTP (`ghfs` on port `8181`).
  - `rclone-sync` — Daily timer syncing `GDrive101:/onyx` to `BMEOffice:/onyx`.
  - `glances-manual` — Runs Glances web monitor on port `61208`.
- **Systemd System Services/Timers**:
  - `dynadotdns` — Runs `/home/mate/randomfiles/ddclient/update.sh` every 5 minutes to update Dynadot DDNS for `hl.kmate.org`.
  - `dynadotcert` — Monthly timer running `/home/mate/randomfiles/scripts/certcurl.sh` for SSL cert updates.
  - `set_fb_blank_1` — Blanks framebuffer `/sys/class/graphics/fb0/blank` at boot.

## Network & Storage Services (`services.nix`)

- **Core**: Enables Docker, `vscode-server`, `fail2ban`, and `logind` (`HandleLidSwitch = "ignore"`).
- **Printing**: CUPS listening on `*:631` with web interface, shared printers, Tailscale `ServerAlias` (`homelab.tailba7efc.ts.net`, `*.ts.net`), and Epson/Gutenprint drivers, advertised via Avahi AirPrint.
- **Nginx Reverse Proxy**: Enforces TLS (`/var/ssl/fullchain.pem`, `/var/ssl/privkey.key`), per-IP connection limits (`limit_conn addr`), and drops matching bad user-agents/referers (`444`):
  - `nextcloud.kmate.org` -> `127.0.0.1:11000` (WebSockets enabled, `5G` max body).
  - `hl.kmate.org`:
    - `/` -> `127.0.0.1:8888` (Dashy)
    - `/jellyfin` -> `127.0.0.1:8096`
    - `/seerr` -> `127.0.0.1:5055` (rewrites and sub-filters `/seerr` subpath)
    - `/films` -> `127.0.0.1:7777` (`12G` max body)
- **Samba**: Shares `/mnt/khdd` as `public` (with `samba-wsdd`), restricted to `192.168.0.*`, `192.168.1.*`, and `127.0.0.1`.

## Off-Site Backups (`csumpi-backup.nix`)

- `csumpi-backup-pull` runs daily at `05:00` (`Europe/Budapest`) via `systemd.timers`.
- Pulls `/var/backup/csumpi/` from `ubuntu@oraclevpn` (Tailscale) over SSH (`/root/.ssh/csumpi-backup`) using `rsync --link-dest` into `/var/lib/csumpi-backup/<timestamp>`.
- Verifies that `db/data-*.db.gz` exists before promoting the snapshot and retains the newest 8 snapshots.

## Docker Stack (`configs/docker-compose.yaml`)

Defines services for `syncthing` (`8384`), `openspeedtest` (`3000`/`3001`), `qbittorrent` (`8080`), `iventoy` (host network), `dashy` (`8888`), `jellyfin` (`8096` with `/dev/dri/renderD128`), `prowlarr` (`9696`), `sonarr` (`8989`), `radarr` (`7878`), `byparr` (`8191`), `bazarr` (`6767`), `seerr` (`5055`), and `nextcloud-aio-mastercontainer` (`8090`, Apache on `127.0.0.1:11000`).
