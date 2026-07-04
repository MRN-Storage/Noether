{ ... }:

{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."photos.nas.lan" = {
      # TODO: enableACME + forceSSL once you have a real domain/DNS pointed here,
      # or use Tailscale + self-signed certs for LAN-only access.
      locations."/".proxyPass = "http://127.0.0.1:2283";
    };

    virtualHosts."files.nas.lan" = {
      locations."/".proxyPass = "http://127.0.0.1:3923";
    };

    virtualHosts."auth.nas.lan" = {
      locations."/".proxyPass = "https://10.100.0.2:8443";
    };
  };
}
