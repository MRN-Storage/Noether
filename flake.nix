{
  description = "MRN-Noether";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    disko = {
      url = "github:MRN-Storage/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, microvm, ... }: {

    nixosConfigurations.kanidm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        microvm.nixosModules.microvm
        ./vms/kanidm/default.nix
      ];
    };
    
    nixosConfigurations.nas = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        microvm.nixosModules.host
        ./hosts/nas/configuration.nix
        ./hosts/nas/hardware-configuration.nix
        ./hosts/nas/disko.nix
        ./modules/microvm-host.nix
        ./modules/proxy.nix
        # ./modules/storage.nix
        # ./modules/immich.nix
        # ./modules/copyparty.nix
        # ./modules/copyparty-sso.nix
        
        {
            microvm.vms.kanidm.config = {
              imports = [ ./vms/kanidm/default.nix ];
            };
        }
      ];
    };
  };
}
