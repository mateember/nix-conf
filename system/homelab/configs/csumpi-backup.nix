# Off-site copy of the csumpikak.hu backups (the Ubuntu server's /var/backup/csumpi:
# daily PocketBase database copies + a mirror of all uploads, made there at 03:30 by
# csumpi-backup.timer, see docs/DEPLOY.md in the csumpisite repo).
#
# Every day at 05:00 this pulls that folder over SSH into a new dated snapshot and keeps
# the newest `keep` snapshots. Snapshots use rsync --link-dest: each one is a complete,
# browsable copy, but files that didn't change since the previous snapshot are hard
# links, so 8 snapshots take about the space of one plus the daily changes.
#
# One-time setup on the homelab (as root):
#   ssh-keygen -t ed25519 -N "" -C "homelab csumpi backup" -f /root/.ssh/csumpi-backup
#   cat /root/.ssh/csumpi-backup.pub   → append to /home/ubuntu/.ssh/authorized_keys on the server
# The server user needs passwordless sudo for rsync (Ubuntu's default `ubuntu` user has it),
# because /var/backup/csumpi is readable by the `csumpi` user only.
# Run once by hand:  sudo systemctl start csumpi-backup-pull && journalctl -u csumpi-backup-pull -n 20
{pkgs, ...}: let
  remote = "ubuntu@oraclevpn"; # the server's Tailscale (MagicDNS) name
  remoteDir = "/var/backup/csumpi/";
  backupDir = "/var/lib/csumpi-backup"; # root-only; not the public Samba share
  sshKey = "/root/.ssh/csumpi-backup";
  keep = 8;
in {
  systemd.services.csumpi-backup-pull = {
    description = "Pull the csumpikak.hu backup into a dated snapshot";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    path = with pkgs; [rsync openssh coreutils findutils];
    serviceConfig = {
      Type = "oneshot";
      Nice = 10;
      IOSchedulingClass = "idle";
      UMask = "0077";
    };
    script = ''
      set -euo pipefail
      dest=${backupDir}
      install -d -m 0700 "$dest"

      stamp=$(date +%Y-%m-%d_%H%M%S)
      # newest finished snapshot, for --link-dest (unchanged files become hard links)
      latest=$(find "$dest" -mindepth 1 -maxdepth 1 -type d -name '20*' | sort | tail -n 1)
      # a half-finished copy from an earlier failed run is thrown away
      rm -rf "$dest"/.incomplete-*
      tmp="$dest/.incomplete-$stamp"

      rsync -a --delete --numeric-ids \
        ''${latest:+--link-dest="$latest"} \
        --rsync-path="sudo -n rsync" \
        -e "ssh -i ${sshKey} -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=$dest/.known_hosts" \
        "${remote}:${remoteDir}" "$tmp/"

      # refuse to keep a copy without any database backup in it
      if ! ls "$tmp"/db/data-*.db.gz >/dev/null 2>&1; then
        echo "no database backup in the pulled copy, keeping the previous snapshots" >&2
        rm -rf "$tmp"
        exit 1
      fi
      mv "$tmp" "$dest/$stamp"

      # keep the newest ${toString keep} snapshots
      find "$dest" -mindepth 1 -maxdepth 1 -type d -name '20*' | sort | head -n -${toString keep} | xargs -r rm -rf

      echo "snapshot $dest/$stamp: $(du -sh "$dest/$stamp" | cut -f1) ($(ls "$dest/$stamp"/db | tail -n 1)); $(find "$dest" -mindepth 1 -maxdepth 1 -type d -name '20*' | wc -l) kept"
    '';
  };

  systemd.timers.csumpi-backup-pull = {
    description = "Daily pull of the csumpikak.hu backup";
    wantedBy = ["timers.target"];
    timerConfig = {
      # after the server's own backup at 03:30 Budapest time (this machine's TZ)
      OnCalendar = "*-*-* 05:00:00";
      Persistent = true;
      RandomizedDelaySec = "10min";
    };
  };
}
