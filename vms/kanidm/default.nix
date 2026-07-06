{ config, ... }:
{
  microvm = {
    vcpu = 2;
    mem  = 1024;
    hypervisor = "qemu";
    vsock.cid = 3;

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

  services.openssh = {
    enable = true;
    listenAddresses = [
      { addr = "0.0.0.0"; port = 22; }          # keep normal networking if you have any
      { addr = "vsock"; port = 22; }             # ssh over vsock, if your openssh build supports it
    ];
  };

  system.stateVersion = "26.05";
}
