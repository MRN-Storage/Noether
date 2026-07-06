{ config, pkgs, ... }:
{
  services.kanidm.provision = {
    persons.user = {
      legalName = "User User";
    };
  };
}
