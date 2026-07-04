# disko.nix — disk layout
# bcache is set up in initrd (see nixos.nix); disko handles everything else.

{ ... }:
{
  disko.devices = {

    # ============================================================
    # NVMe: system disk (boot + root + bcache cache partition)
    # ============================================================
    disk.nvme = {
      type   = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {

          boot = {
            name = "boot";
            size = "4G";
            type = "EF00";
            content = {
              type         = "filesystem";
              format       = "vfat";
              mountpoint   = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };

          root = {
            name = "root";
            size = "64G";
            content = {
              type       = "filesystem";
              format     = "ext4";
              mountpoint = "/";
            };
          };

          # p3 — bcache SSD cache tier; formatted by initrd postDeviceCommands
          bcache_cache = {
            name = "bcache_cache";
            size = "100%";
            # no content block — owned by bcache
          };
        };
      };
    };

    # ============================================================
    # HDDs — RAID1 members
    # ============================================================
    disk.sda = {
      type   = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions.raid = {
          name = "sda_raid";
          size = "100%";
          content = { type = "mdraid"; name = "md0"; };
        };
      };
    };

    disk.sdb = {
      type   = "disk";
      device = "/dev/sdb";
      content = {
        type = "gpt";
        partitions.raid = {
          name = "sdb_raid";
          size = "100%";
          content = { type = "mdraid"; name = "md0"; };
        };
      };
    };

    # ============================================================
    # RAID1 — md0
    # bcache sits on top of md0; LUKS sits on top of bcache0.
    # disko opens LUKS here for the LVM PV declaration, but the actual
    # device path is overridden in nixos.nix via boot.initrd.luks.
    # ============================================================
    mdadm.md0 = {
      type  = "mdadm";
      level = 1;
      mdadmExtraOptions = [ "--bitmap=internal" ];
    };

    # ============================================================
    # LVM VG — vgdata (on /dev/mapper/cryptdata)
    # Thin pool (pool0) is created via an activation script in nixos.nix.
    # ============================================================
    lvm_vg.vgdata = {
      type = "lvm_vg";
      lvs = {
        immich = {
          size = "2T";
          content = {
            type       = "filesystem";
            format     = "ext4";
            extraArgs  = [ "-L" "immich" ];
            mountpoint = "/data/immich";
          };
        };

        shared = {
          size = "2T";
          content = {
            type       = "filesystem";
            format     = "ext4";
            extraArgs  = [ "-L" "shared" ];
            mountpoint = "/data/shared";
          };
        };
      };
    };
  };
}