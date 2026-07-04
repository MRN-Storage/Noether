{ ... }:

# copyparty currently has no native NixOS module, so it's run via podman.
{
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";

  virtualisation.oci-containers.containers.copyparty = {
    image = "copyparty/ac:latest";
    ports = [ "127.0.0.1:3923:3923" ]; # only bind locally; nginx will front it
    volumes = [
      "/data/shared:/w"
    ];
    extraOptions = [ "--network=host" ];
  };
}
