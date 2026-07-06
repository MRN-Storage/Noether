{ config, pkgs, ... }:

{
  services.kanidm = {
    enableServer = true;
    package = pkgs.kanidm_1_10; 
    server.settings = {
      domain = "auth.nas.lan";
      origin = "https://auth.nas.lan";
      bindaddress = "0.0.0.0:8443";

      tls_chain = "/var/lib/kanidm/chain.pem";
      tls_key = "/var/lib/kanidm/key.pem";
    };
  };

  systemd.services.kanidm.preStart = ''
    if [ ! -f /var/lib/kanidm/key.pem ]; then
      mkdir -p /var/lib/kanidm
      ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:4096 \
        -keyout /var/lib/kanidm/key.pem \
        -out /var/lib/kanidm/chain.pem \
        -days 3650 -nodes \
        -subj "/CN=auth.nas.lan"
      chown -R kanidm:kanidm /var/lib/kanidm
    fi
  '';

  imports = [ ./kanidm-provision.nix ];

  # Open the firewall port inside the KVM VM so Caddy can reach it
  networking.firewall.allowedTCPPorts = [ 8443 ];
}
