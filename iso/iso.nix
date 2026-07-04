{config, pkgs, ...}:
{
  imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix> ];

  users.users.nixos.openssh.authorizedKeys.keyFiles = [
    ./nixiso.key.pub
  ];

  environment.etc."keyshare/key.pub".source = ./nixiso.key.pub;
  environment.etc."keyshare/key".source = ./nixiso.key;

  systemd.services.keyshare = {
    description = "Serve SSH keys via python http.server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 -m http.server 8000 --directory /etc/keyshare";
      Restart = "on-failure";
    };
  };

  networking.firewall.allowedTCPPorts = [ 8000 22 ];

  services.openssh.enable = true;
}
