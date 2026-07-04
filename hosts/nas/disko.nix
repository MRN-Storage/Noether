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

          # p3 — bcache SSD cache tier
          bcache_cache = {
            name = "bcache_cache";
            size = "100%";
            content = {
              type = "bcache";
              role = "cache";
              # cacheMode can be "writeback" | "writethrough" | "writearound"
              cacheMode = "writeback";
            };
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
    # md0 is used as a bcache backing device, exposing /dev/bcache0.
    # LUKS sits on top of bcache0.
    # ============================================================
    mdadm.md0 = {
      type  = "mdadm";
      level = 1;
      content = {
        type  = "bcache";
        role  = "backing";
        # References the cache partition registered above
        cacheName = "bcache_cache";
        content = {
          type = "luks";
          name = "cryptdata";

          settings = {
            allowDiscards = false;
          };

          extraOpenArgs = [
            "--key-file=/dev/disk/by-id/usb-USB_Flash_Disk_SCY0000000039178-0:0"
            "--keyfile-size=4096"
          ];

          content = {
            type       = "filesystem";
            format     = "ext4";
            mountpoint = "/data";
          };
        };
      };
    };
  };
}