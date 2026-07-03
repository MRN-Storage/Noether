{ config, pkgs, ... }:

{
  networking.hostName = "nas";

  # Bootloader (systemd-boot on the NVMe ESP)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Berlin"; # adjust to your timezone

  # RAID array must be assembled in the initrd before bcache/LUKS/LVM
  boot.swraid.enable = true;
  boot.swraid.mdadmConf = ''
    MAILADDR root
  '';

  # bcache must be available in the initrd
  boot.initrd.availableKernelModules = [ "bcache" ];

  # LUKS on top of the bcache device (bcache0 = cached md0)
  # hardware-configuration.nix will generate this block with the real UUID â€”
  # the entry below is illustrative; confirm/merge with the generated file.
  boot.initrd.luks.devices."md0_crypt" = {
    device = "/dev/bcache0";   # or by UUID: "/dev/disk/by-uuid/<uuid-of-bcache0>"
    allowDiscards = true;      # optional; enable if bcache writeback + TRIM is desired
  };

  boot.initrd.services.lvm.enable = true;  # already added by hardware-configuration.nix

  networking.firewall.allowedTCPPorts = [ 80 443 22 ];
  networking.networkmanager.enable = true;

  # Remote access without opening ports publicly (optional but recommended)
  services.tailscale.enable = true;

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDs68sW1qgiIPhXAB2U3hTazPNZ3SrYZlN7w7OEQTbgO ell@lovelace"
    ];
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  environment.systemPackages = with pkgs; [ neovim curl wget vim git htop lvm2 mdadm bcache-tools cryptsetup ];

  system.stateVersion = "26.05"; # keep this pinned to the release you installed with
}
