{ config, ... }:
{
  microvm.host.enable = true;

  # Host-only bridge — no physical NIC attached, so nothing on the LAN
  # can reach it except through the host itself (nginx).
  networking.bridges."br-vms".interfaces = [
    "vm-kanidm"   # tap device created for the kanidm microvm (see vms/kanidm)
  ];
  networking.interfaces."br-vms".ipv4.addresses = [
    { address = "10.100.0.1"; prefixLength = 24; }
  ];

  # Let the VM reach the internet for updates/NTP without exposing it inbound.
  networking.nat = {
    enable = true;
    internalInterfaces = [ "br-vms" ];
    externalInterface = "enp4s0"; # <-- set to your actual uplink NIC name
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  users.groups.kvm.members = [ "admin" ];
}
