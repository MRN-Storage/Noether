# disko.nix — disk layout
# bcache is set up in initrd (see nixos.nix); disko handles everything else.

{ ... }:
{
  disko.devices = {

    # ============================================================
    # NVMe: system disk (boot + root + lvm cache partition)
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

          cache = {
            name = "cache";
            size = "100%";
            content = {
              type = "luks";
              name = "cryptcache";

              keyFile = "/dev/disk/by-partlabel/CACHE-KEY";
              settings = {
                allowDiscards = true;
                keyFile = "/dev/disk/by-partlabel/CACHE-KEY";
              };
            };
          };
        };
      };
    };

    # ============================================================
    # HDDs: RAID1 members
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
    # VG0: Contains RAID1
    # ============================================================
    mdadm.md0 = {
      type  = "mdadm";
      level = 1;
      extraArgs = [  
        "--bitmap=internal"  
      ];

      content = {
        type = "luks";
        name = "cryptdata";

        keyFile = "/dev/disk/by-partlabel/DATA-KEY";
        settings = {
          allowDiscards = true;
          keyFile = "/dev/disk/by-partlabel/DATA-KEY";
        };

        content = {
          type = "lvm_pv";
          vg = "vg0";
        };
      };
    };

    lvm_vg.vg0 = {  
      type = "lvm_vg";  
      lvs = {  
        thinpool = {  
          size = "95%";  
          lvm_type = "thin-pool";
        };
      };
    };
  };
}