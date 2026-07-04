{
  description = "MRN-Noether";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, ... }: {
    nixosConfigurations.nas = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./hosts/nas/configuration.nix
        # ./hosts/nas/hardware-configuration.nix
        ./hosts/nas/disko.nix
        # ./modules/storage.nix
        # ./modules/immich.nix
        # ./modules/copyparty.nix
        # ./modules/kanidm.nix
        # ./modules/proxy.nix
      ];
    };
  };
}
