# Noether
Configuration for Noether

## Reboot?
```sh
head -n -2 .ssh/known_hosts > .ssh/known_hosts
```

## TODOs
### Config
- [x] all mounts into `disko.nix` (did something different)
- [ ] tailscale?
- [ ] kvm via nix
    - [ ] research
    - [ ] kanidm
    - [ ] immich
    - [ ] copyparty
    - [ ] outward proxy
    - [ ] internal proxy
- [ ] local auth via kanidm
- [ ] integrate sso via kanidm

### Instance
- [ ] Change default password
    - [ ] root password
    - [ ] disk encryption

## Further Ideas
- [ ] Prepare access VPS
- [ ] CI / CD
- [ ] User sign-up procedure
    - [ ] Usage monitoring


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

## Keyfile on Boot Stick
```sh
# 1. Write random key to USB stick (replace /dev/sdX with your USB)
sudo dd if=/dev/urandom of=/dev/sdX bs=512 count=8

# 2. Add USB as a LUKS key
sudo cryptsetup luksAddKey /dev/bcache0 /dev/sdc --new-keyfile-size 4096

# 3. Find the stable by-id path for your USB
ls -l /dev/disk/by-id/ | grep usb
# Paste the result into keyFile in configuration.nix
```
