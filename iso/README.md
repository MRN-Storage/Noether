# Generate the Iso

First get a private / public key pair with `ssh-keygen`,
be sure to include the `.key` suffix.

You need `nix` installed on your system. On arch you just do
```sh
pacman -S nix
```

Then build the the iso and flash it to a usb stick with something like this:
```sh
DISK="/dev/sdc"
sudo nix-build \
    -I nixpkgs=https://nixos.org/channels/nixos-26.05/nixexprs.tar.xz \
    '<nixpkgs/nixos>' \
    -A config.system.build.isoImage \
    -I nixos-config=./iso.nix
pushd ./result/iso
pv nixos-minimal-26.05.4028.80d591ed473c-x86_64-linux.iso | sudo tee $DISK > /dev/null
sync
popd
```

