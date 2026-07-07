{ config, pkgs, ... }:
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

  environment.systemPackages = [ pkgs.openssl pkgs.kanidm ];

  services.kanidm.enableClient = true;

  networking.hostName = "kanidm-vm";
  networking.useNetworkd = true;
  systemd.network.networks."10-eth0" = {
    matchConfig.Name = "eth0";
    address = [ "10.100.0.2/24" ];
    gateway = [ "10.100.0.1" ];
  };

  # SSH-Zugriff
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJcaxcyE3YI7QYwFeux/qmmH1bQ5BpYWh51ZydZfhcB admin@nas"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  imports = [ ../../modules/kanidm.nix ];

  system.stateVersion = "26.05";
}
