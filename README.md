# Noether
Configuration for Noether

## TODOs
### Config
- [ ] Convert setup.sh into disko

### Instance
- [ ] Change default password

# Disk Partitioning and Replaying a Config
Boot from an a live iso (see [[./iso/README.md]])
and clone this repository.

```sh
# 1. Partition disks + assemble RAID
nix run github:nix-community/disko -- --mode format ./disko.nix

# 2. bcache + LUKS + LVM (one-time)
bash post-disko.sh

# 3. Paste UUIDs from install.sh output into nixos.nix
LUKS_UUID=$(blkid -s UUID -o value /dev/bcache0)
MDADM_UUID=$(mdadm --detail /dev/md0 | awk '/UUID/{print $3}')

sed -i "s|luksUUID  = \"<bcache0-luks-uuid>\"|luksUUID  = \"${LUKS_UUID}\"|" hosts/nas/configuration.nix
sed -i "s|mdadmUUID = \"<md0-uuid>\"|mdadmUUID = \"${MDADM_UUID}\"|" hosts/nas/configuration.nix

# 4. Mount everything
nix run github:nix-community/disko -- --mode mount ./disko.nix

# 5. Install
nixos-install --root /mnt --flake .#yourHost
```

