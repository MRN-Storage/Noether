#!/usr/bin/env bash
# install.sh — one-time setup for bcache + LUKS + LVM
# Run after: nix run github:nix-community/disko -- --mode format ./disko.nix
# Run before: nix run github:nix-community/disko -- --mode mount ./disko.nix
set -euo pipefail

NVME_CACHE="/dev/nvme0n1p3"
RAID_DEV="/dev/md0"
BCACHE_DEV="/dev/bcache0"
CRYPT_NAME="cryptdata"
CRYPT_DEV="/dev/mapper/${CRYPT_NAME}"
VG_NAME="vgdata"
POOL_NAME="pool0"

# ============================================================
# 1. bcache — backing device: md0, cache device: nvme0n1p3
# ============================================================
echo "==> Setting up bcache"
modprobe bcache

make-bcache \
  --block 4k \
  --bucket 2M \
  --cache-mode writeback \
  -B "${RAID_DEV}" \
  -C "${NVME_CACHE}" \
  --wipe-bcache

# bcache superblocks are written; udev will register them
udevadm trigger
udevadm settle

# Wait for /dev/bcache0
echo "==> Waiting for /dev/bcache0..."
for i in $(seq 1 40); do
  [ -b "${BCACHE_DEV}" ] && break
  sleep 0.5
done
[ -b "${BCACHE_DEV}" ] || { echo "ERROR: ${BCACHE_DEV} never appeared"; exit 1; }

# ============================================================
# 2. LUKS on bcache0
# ============================================================
echo "==> LUKS format on ${BCACHE_DEV}"
cryptsetup luksFormat "${BCACHE_DEV}"

echo "==> Opening LUKS"
cryptsetup open "${BCACHE_DEV}" "${CRYPT_NAME}"

# ============================================================
# 3. LVM — PV, VG, thin pool, LVs
# ============================================================
echo "==> LVM setup"
modprobe dm_thin_pool
pvcreate "${CRYPT_DEV}"
vgcreate "${VG_NAME}" "${CRYPT_DEV}"

lvcreate -l 90%FREE --type thin-pool --thinpool "${POOL_NAME}" "${VG_NAME}"
lvcreate -V 2T --thin-pool "${VG_NAME}/${POOL_NAME}" -n immich
lvcreate -V 2T --thin-pool "${VG_NAME}/${POOL_NAME}" -n shared

# ============================================================
# 4. Filesystems
# ============================================================
echo "==> Creating filesystems"
mkfs.ext4 -L immich "/dev/${VG_NAME}/immich"
mkfs.ext4 -L shared "/dev/${VG_NAME}/shared"

# ============================================================
# 5. Print UUIDs needed for nixos.nix
# ============================================================
echo ""
echo "==> Paste these into nixos.nix:"
echo ""
echo "LUKS UUID (bcache0):"
blkid -s UUID -o value "${BCACHE_DEV}"
echo ""
echo "md0 UUID (for swraid.mdadmConf):"
mdadm --detail "${RAID_DEV}" | grep UUID | awk '{print $3}'
