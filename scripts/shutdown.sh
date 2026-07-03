#!/usr/bin/env bash
set -euo pipefail

### =========================
### VARIABLES
### =========================
NVME_NAME="nvme0n1"
MD_NAME="md0"
VG_NAME="vgdata"
CRYPT_NAME="cryptdata"

BCACHE_DEVICE="/dev/bcache0"
MD_DEVICE="/dev/md0"

### =========================
### 1. UNMOUNT FILESYSTEMS
### =========================

echo "==> Unmounting filesystems"

umount -R /mnt/data 2>/dev/null || true
umount /mnt 2>/dev/null || true

### =========================
### 2. DEACTIVATE LVM
### =========================

echo "==> Deactivating LVM"
lvchange -an ${VG_NAME} 2>/dev/null || true
vgchange -an ${VG_NAME} 2>/dev/null || true

### =========================
### 3. CLOSE LUKS (IMPORTANT ORDER STEP)
### =========================

echo "==> Closing LUKS container"

if [ -e /dev/mapper/${CRYPT_NAME} ]; then
  cryptsetup close ${CRYPT_NAME} || true
fi

### =========================
### 4. DETACH BCACHE CLEANLY
### =========================

echo "==> Detaching bcache"

if [ -e /sys/block/bcache0/bcache/detach ]; then
  echo 1 >"/sys/block/${MD_NAME}/bcache/stop" || true
fi

if [ -e /sys/block/bcache0/bcache/stop ]; then
  echo 1 >"/sys/block/${NVME_NAME}/${NVME_NAME}p3/bcache/set/stop" || true
fi

### =========================
### 5. STOP MDADM ARRAY
### =========================

echo "==> Stopping mdadm array"

mdadm --stop ${MD_DEVICE} 2>/dev/null || true

### =========================
### 6. OPTIONAL: WIPE KERNEL CACHES (SAFE RESET)
### =========================

sync
blockdev --flushbufs ${MD_DEVICE} 2>/dev/null || true

echo "==> Shutdown complete"
