{
  pkgs,
  winapps,
  ...
}: {
  programs.virt-manager.enable = true;

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        vhostUserPackages = [pkgs.virtiofsd];
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
    containers.enable = true;
    podman = {
      enable = false;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };

    docker = {
      enable = true;
      storageDriver = "btrfs";
      daemon.settings = {
        #ipv6 = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    qemu
    gnome-boxes
    virt-viewer
    virtio-win
    spice
    spice-gtk
    spice-protocol
    win-spice
    winapps.packages."${pkgs.stdenv.hostPlatform.system}".winapps
    winapps.packages."${pkgs.stdenv.hostPlatform.system}".winapps-launcher
    podman-compose
    podman-tui
    dive
  ];
}
