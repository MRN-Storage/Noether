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
sudo nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=./iso.nix
pushd ./results/iso
pv nixos-minimal-25.05.813814.ac62194c3917-x86_64-linux.iso | sudo tee $DISK > /dev/null
popd
```

