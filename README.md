# Noether
Configuration for Noether

## Reboot?
```sh
head -n -2 .ssh/known_hosts > .ssh/known_hosts
```

## TODOs
### Config
- [ ] Convert setup.sh into disko

### Instance
- [ ] Change default password

## Disk Partitioning and Replaying a Config
Boot from an a live iso (see [[./iso/README.md]])
and `cp -r /opt/Noether . && cd Noether`.

```sh
# 1. Partition disks + assemble RAID
sudo nix run github:nix-community/disko -- \
    --mode format ./hosts/nas/disko.nix

# 2. bcache + LUKS + LVM (one-time)
sudo bash ./scripts/post-disko.sh

# 3. Paste UUIDs from install.sh output into nixos.nix
LUKS_UUID=$(blkid -s UUID -o value /dev/bcache0)
MDADM_UUID=$(sudo mdadm --detail /dev/md0 | awk '/UUID/{print $3}')

sed -i "s|luksUUID  = \"<bcache0-luks-uuid>\"|luksUUID  = \"${LUKS_UUID}\"|" hosts/nas/configuration.nix
sed -i "s|mdadmUUID = \"<md0-uuid>\"|mdadmUUID = \"${MDADM_UUID}\"|" hosts/nas/configuration.nix

# 4. Mount everything
sudo nix run github:nix-community/disko -- \
    --mode mount ./hosts/nas/disko.nix

# 4a. Generate hardware config (optional)
nixos-generate-config --root /mnt --show-hardware-config > ./hosts/nas/hardware-configuration.nix
git add ./hosts/nas/hardware-configuration.nix
# then you must uncomment this file from flake.nix
# and comment disko instead.

# 5. Install
sudo cp -r ./ /mnt/etc/nixos
cd !$
sudo nixos-install --impure --root /mnt --flake .#nas
```
