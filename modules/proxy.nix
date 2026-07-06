{ ... }:

{
  services.caddy = {
    enable = true;
    virtualHosts."auth.nas.lan".extraConfig = ''
      reverse_proxy 10.100.0.2:8443 {
        tls internal
        transport http {
          tls
          tls_insecure_skip_verify
        }
      }
    '';
  };
}
