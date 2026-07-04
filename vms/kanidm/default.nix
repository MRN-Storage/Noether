{ config, ... }:
{
  microvm = {
    vcpu = 2;
    mem  = 1024;
    hypervisor = "qemu";

    interfaces = [{
      type = "tap";
      id   = "vm-kanidm";              # must match the bridge entry on the host
      mac  = "02:00:00:00:00:01";
    }];

    volumes = [{
      image      = "/var/lib/microvms/kanidm/data.img"; # persistent, survives rebuilds
      mountPoint = "/var/lib/kanidm";
      size       = 4096; # MB
    }];
  };

  networking.hostName = "kanidm-vm";
  networking.useNetworkd = true;
  systemd.network.networks."10-eth0" = {
    matchConfig.Name = "eth0";
    address = [ "10.100.0.2/24" ];
    gateway = [ "10.100.0.1" ];
  };

  imports = [ ../../modules/kanidm.nix ];

  system.stateVersion = "26.05";
}
