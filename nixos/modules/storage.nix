{ ... }:

# The actual mount points for the LVM volumes created during install.
# Stack at boot time: mdadm(md0) â†’ bcache(/dev/bcache0) â†’ LUKS(md0_crypt) â†’ LVM(vgdata) â†’ LVs
# fileSystems for root/boot and the LUKS/RAID devices already come from
# hardware-configuration.nix â€” this file just owns the data-volume mount options.
{
  fileSystems."/data/immich" = {
    device = "/dev/vgdata/immich";
    fsType = "ext4";
  };

  fileSystems."/data/shared" = {
    device = "/dev/vgdata/shared";
    fsType = "ext4";
  };

  fileSystems."/data/backup" = {
    device = "/dev/vgdata/backup";
    fsType = "ext4";
  };
}
