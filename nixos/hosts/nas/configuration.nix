{ config, pkgs, ... }:
let
  # Fill in after running install.sh, then run the sed commands below
  luksUUID  = "<bcache0-luks-uuid>";  # blkid -s UUID -o value /dev/bcache0
  mdadmUUID = "<md0-uuid>";           # mdadm --detail /dev/md0 | grep UUID
in
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
    ARRAY /dev/md0 level=raid1 num-devices=2 metadata=1.2 UUID=${mdadmUUID}
  '';
  # Get md0 UUID: mdadm --detail /dev/md0 | grep UUID

  boot.kernelModules = [ "dm_thin_pool" ];

  boot.initrd.availableKernelModules = [
    "nvme" "ahci" "sd_mod"       # storage controllers
    "md_mod" "raid1"             # RAID1 / md assembly
    "bcache"                     # bcache backing + cache registration
    "dm_crypt" "dm_mod"          # LUKS / device-mapper
    "dm_thin_pool"               # LVM thin provisioning
  ];
  boot.initrd.systemd.extraBin = {
  thin_check = "${pkgs.thin-provisioning-tools}/bin/thin_check";
  };
  # LUKS on top of the bcache device (bcache0 = cached md0)
  # hardware-configuration.nix will generate this block with the real UUID â€”
  # the entry below is illustrative; confirm/merge with the generated file.
  # /boot and / are mounted by disko-generated fileSystems — not declared here.
  # Fill in UUID after first install: blkid -s UUID -o value /dev/bcache0
  boot.initrd.luks.devices."cryptdata" = {
    device = "/dev/disk/by-uuid/${luksUUID}";
    allowDiscards = false; # bcache handles caching; leave TRIM off on LUKS
  };

  boot.initrd.services.lvm.enable = true;

  # disko generates fileSystems for / and /boot from disko.nix.
  # /data/* are on LVM/bcache/LUKS which disko cannot model, so declare them here.
  fileSystems."/data/immich" = {
    device  = "/dev/vgdata/immich";
    fsType  = "ext4";
    options = [ "defaults" "nofail" ];
  };

  fileSystems."/data/shared" = {
    device  = "/dev/vgdata/shared";
    fsType  = "ext4";
    options = [ "defaults" "nofail" ];
  };
  boot.initrd.systemPackages = [ pkgs.thin-provisioning-tools ];
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
