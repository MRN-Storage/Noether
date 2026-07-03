{ config, ... }:

{
  services.kanidm = {
    enableServer = true;
    serverSettings = {
      domain = "auth.nas.lan";
      origin = "https://auth.nas.lan";
      # Point these at real cert files â€” see the sops-nix note below for handling
      # the key privately instead of committing it to your flake repo.
      tls_chain = "/var/lib/kanidm/chain.pem";
      tls_key = "/var/lib/kanidm/key.pem";
      bindaddress = "127.0.0.1:8443"; # nginx terminates public TLS and proxies here
    };
  };

  # After first boot, create an OAuth2 client for Immich with:
  #   kanidm system oauth2 create immich "Immich" https://photos.nas.lan
  #   kanidm system oauth2 update-scope-map immich <group> openid email profile
}
