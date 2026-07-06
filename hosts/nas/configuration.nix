{ config, pkgs, ... }:
{
  networking.hostName = "nas";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader (systemd-boot on the NVMe ESP)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Berlin"; # adjust to your timezone

  # RAID array must be assembled in the initrd before bcache/LUKS/LVM
  boot.swraid.enable = true;
  boot.swraid.mdadmConf = ''
    MAILADDR root
    ARRAY /dev/md0 level=raid1 num-devices=2 metadata=1.2
  '';
  # Get md0 UUID: mdadm --detail /dev/md0 | grep UUID

  boot.kernelModules = [ "dm_thin_pool" ];

  boot.initrd.availableKernelModules = [
    "nvme" "ahci" "sd_mod"       # storage controllers
    "md_mod" "raid1"             # RAID1 / md assembly
    "bcache"                     # bcache backing + cache registration
    "dm_crypt" "dm_mod"          # LUKS / device-mapper
    "dm_thin_pool"               # LVM thin provisioning
    "usb_storage"
    "uas"      # if the device uses USB Attached SCSI
    "xhci_pci" # USB 3 controllers
    "ehci_pci" # USB 2 controllers if needed
  ];
  boot.initrd.systemd.extraBin = {
    thin_check = "${pkgs.thin-provisioning-tools}/bin/thin_check";
  };


  boot.initrd.services.lvm.enable = true;

  # disko generates fileSystems for / and /boot from disko.nix.
  # /data/* are on LVM/bcache/LUKS which disko cannot model, so declare them here.
  # fileSystems."/data/immich" = {
  #   device  = "/dev/vgdata/immich";
  #   fsType  = "ext4";
  #   options = [ "defaults" "nofail" ];
  # };

  # fileSystems."/data/shared" = {
  #   device  = "/dev/vgdata/shared";
  #   fsType  = "ext4";
  #   options = [ "defaults" "nofail" ];
  # };
  networking.firewall.allowedTCPPorts = [ 80 443 22 ];
  networking.networkmanager.enable = true;

  # Remote access without opening ports publicly (optional but recommended)
  services.tailscale.enable = true;

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICFLSh8+F3ZA0H6F8IBClfrMfDJIyYvt7Ytj3CeanonX ell@dirac"
    ];
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  security.sudo.extraRules = [
    {
      users = [ "admin" ];
      commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ];
    }
  ];

  environment.systemPackages = with pkgs; [ neovim curl wget vim git htop lvm2 tree mdadm bcache-tools cryptsetup ];

  system.stateVersion = "26.05"; # keep this pinned to the release you installed with
}
