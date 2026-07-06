{ ... }:

{

  services.caddy = {
    enable = true;
    virtualHosts."auth.nas.lan".extraConfig = ''
      tls internal
      reverse_proxy https://10.100.0.2:8443 {
        transport http {
          tls
          tls_insecure_skip_verify
        }
      }
    '';
  };
}
