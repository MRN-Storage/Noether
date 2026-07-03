#!/usr/bin/env bash
set -euo pipefail

### =========================
### DEVICE VARIABLES
### =========================
NVME_NAME="nvme0n1"
NVME_DISK="/dev/${NVME_NAME}"
NVME_CACHE_PART="${NVME_DISK}p3"

RAID_DISK1="/dev/sda1"
RAID_DISK2="/dev/sdb1"
MD_NAME="md0"
MD_DEVICE="/dev/${MD_NAME}"
BCACHE_DEVICE="/dev/bcache0"
CRYPT_NAME="cryptdata"
CRYPT_DEVICE="/dev/mapper/cryptdata"

POOL_NAME="pool0"
VG_NAME="vgdata"

LV_IMMICH="immich"
LV_SHARED="shared"
LV_BACKUP="backup"

MNT="/mnt"

### =========================
### (OPTIONAL) WIPE OLD STATE
### =========================

# WARNING: only use if rebuilding from scratch
# wipefs -a "${MD_DEVICE}" || true
# wipefs -a "${NVME_CACHE_PART}" || true

mdadm -S ${MD_NAME}
mdadm --zero-superblock ${RAID_DISK1}
mdadm --zero-superblock ${RAID_DISK2}

### =========================
### CREATE RAID1
### =========================

mdadm --create "${MD_DEVICE}" \
  --level=1 \
  --raid-devices=2 \
  --metadata=1.2 \
  "${RAID_DISK1}" "${RAID_DISK2}"

# monitor sync
cat /proc/mdstat

### =========================
### CREATE BCACHE (CLEAN METHOD)
### =========================

# Your working command (important part)
make-bcache -B "${MD_DEVICE}" \
  -C "${NVME_CACHE_PART}" \
  --wipe-bcache

### =========================
### VERIFY BCACHE DEVICE
### =========================

lsblk -o NAME,TYPE,SIZE,MOUNTPOINTS | grep -E "bcache|md0|nvme"

sleep 5
### =========================
### VERIFY CACHE STATE
### =========================

cat /sys/block/md0/bcache/state || true

ls /sys/fs/bcache || true

echo "bcache setup complete - ready for LUKS"

### =========================
### 1. LUKS ENCRYPTION
### =========================

echo "==> LUKS format on bcache device"
cryptsetup luksFormat "${BCACHE_DEVICE}"

echo "==> Opening LUKS container"
cryptsetup open "${BCACHE_DEVICE}" "${CRYPT_NAME}"

### =========================
### 2. LVM SETUP
### =========================

echo "==> Creating physical volume"
pvcreate "${CRYPT_DEVICE}"

echo "==> Creating volume group"
vgcreate "${VG_NAME}" "${CRYPT_DEVICE}"

echo "==> Creating logical volumes"

modprobe dm_thin_pool

lvcreate -l 90%FREE --type thin-pool --thinpool ${POOL_NAME} ${VG_NAME}
lvcreate -V 2T --thin-pool "${VG_NAME}/${POOL_NAME}" -n "${LV_IMMICH}"
lvcreate -V 2T --thin-pool "${VG_NAME}/${POOL_NAME}" -n "${LV_SHARED}"

### =========================
### 3. FILESYSTEMS
### =========================

echo "==> Creating ext4 filesystems"
mkfs.ext4 -L "${LV_IMMICH}" "/dev/${VG_NAME}/${LV_IMMICH}"
mkfs.ext4 -L "${LV_SHARED}" "/dev/${VG_NAME}/${LV_SHARED}"

### =========================
### 4. MOUNT POINTS
### =========================

echo "==> Creating mount directories"

mount "${NVME_DISK}p2" "${MNT}"

mkdir -p "${MNT}/boot"
mkdir -p "${MNT}/data/immich"
mkdir -p "${MNT}/data/shared"

echo "==> Mounting filesystems"

mount "${NVME_DISK}p1" "${MNT}/boot/"

mount "/dev/${VG_NAME}/${LV_IMMICH}" "${MNT}/data/immich"
mount "/dev/${VG_NAME}/${LV_SHARED}" "${MNT}/data/shared"

### =========================
### 5. VERIFY STATE
### =========================

echo "==> Final verification"
lsblk -f
df -h
lvs
vgs
pvs

### =========================
### 6. NIXOS CONFIG HINTS
### =========================

echo ""
echo "==> Next manual step required in NixOS config:"
echo ""
echo "boot.initrd.luks.devices.cryptdata.device = \"/dev/disk/by-uuid/<UUID>\";"
echo "boot.initrd.lvm.enable = true;"
echo ""
echo "fileSystems.\"/data/immich\" = { device = \"/dev/vgdata/immich\"; fsType = \"ext4\"; };"
echo "fileSystems.\"/data/shared\" = { device = \"/dev/vgdata/shared\"; fsType = \"ext4\"; };"
echo "fileSystems.\"/data/backup\" = { device = \"/dev/vgdata/backup\"; fsType = \"ext4\"; };"
echo ""
echo "Run: blkid | grep bcache0 to get LUKS UUID"
