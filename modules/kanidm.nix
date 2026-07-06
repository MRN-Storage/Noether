{ config, pkgs, ... }:

{
  services.kanidm = {
    enableServer = true;
    package = pkgs.kanidm_1_10; 
    serverSettings = {
      domain = "auth.nas.lan";
      origin = "https://auth.nas.lan";
      bindaddress = "0.0.0.0:8443";
      
      # instruct Kanidm to handle its own internal TLS generation:
      tls_chain = null;
      tls_key = null;
    };
  };

  # Open the firewall port inside the KVM VM so Caddy can reach it
  networking.firewall.allowedTCPPorts = [ 8443 ];
}
