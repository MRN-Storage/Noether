{ ... }:

{
  services.immich = {
    enable = true;
    port = 2283;
    mediaLocation = "/data/immich";
    # Configure OIDC once Kanidm is up (see modules/kanidm.nix for the OAuth2 client setup):
    # environment = { OIDC_ISSUER_URL = "https://auth.nas.lan/oauth2/openid/immich"; };
  };
}
