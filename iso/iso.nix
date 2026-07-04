{config, pkgs, ...}:
{
  imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix> ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users.nixos.openssh.authorizedKeys.keyFiles = [
    ./nixiso.key.pub
  ];

  environment.etc."keyshare/key.pub".source = ./nixiso.key.pub;
  environment.etc."keyshare/key".source = ./nixiso.key;

  boot.kernelModules = [
    "bcache"
    "dm_thin_pool"
    "dm_persistent_data"
    "dm_bio_prison"
  ];

  systemd.services.keyshare = {
    description = "Serve SSH keys via python http.server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 -m http.server 8000 --directory /etc/keyshare";
      Restart = "on-failure";
    };
  };

  systemd.services.pull-noether = {
    description = "Pull Noether repository from GitHub";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.git}/bin/git clone https://github.com/MRN-Storage/Noether /opt/Noether";
      RemainAfterExit = true;
      Restart = "on-failure";
    };
  };

  environment.systemPackages = [ pkgs.bcache-tools pkgs.tree ];

  networking.firewall.allowedTCPPorts = [ 8000 22 ];

  services.openssh.enable = true;
}
