{ ... }:

{
  services.immich = {
    enable = true;
    port = 2283;
    mediaLocation = "/data/immich";

    environment = {
    IMMICH_OIDC_ENABLED = "true";

    IMMICH_OIDC_ISSUER_URL =
      "https://auth.nas.lan/oauth2/openid/immich";

    IMMICH_OIDC_CLIENT_ID = "immich";

    IMMICH_OIDC_CLIENT_SECRET =
      "exz7gt9h4dbbkjhbxvzd4wpqb9ut3fdxrkucrzw3y1w4zpfd";
    };
  };
}
