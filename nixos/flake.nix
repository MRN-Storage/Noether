{
  description = "MRN-Noether";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.nas = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/nas/configuration.nix
        ./hosts/nas/hardware-configuration.nix
        ./modules/storage.nix
        ./modules/immich.nix
        ./modules/copyparty.nix
        ./modules/kanidm.nix
        ./modules/proxy.nix
      ];
    };
  };
}
