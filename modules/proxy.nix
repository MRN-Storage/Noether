{ ... }:

{
  networking.hosts = {
    "10.100.0.2" = [ "auth.nas.lan" ];
  };

  services.caddy = {
    enable = true;
    virtualHosts."auth.nas.lan".extraConfig = ''
      tls internal
      reverse_proxy auth.nas.lan {
        transport http {
          tls
          tls_insecure_skip_verify
        }
      }
    '';
  };
}
