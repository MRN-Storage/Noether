{ config, pkgs, ... }:
{
  services.kanidm.provision = {
    adminPasswordFile = "/run/secrets/kanidm-admin-password";
    
    persons.user = {
      legalName = "User User";
    };
  };
}
