{ config, pkgs, ... }:

{
  networking = {
    hostName = "nixos";
    nameservers = [ 
      "1.1.1.1"
      "1.0.0.1"
    ];
    networkmanager.enable = true;
    dhcpcd.extraConfig = "nohook resolv.conf";
    networkmanager.dns = "none";

    firewall = {
      enable = true;
      allowedTCPPorts = [ 8081 ];
      allowedUDPPorts = [];
    };
  };

  services.stubby = {
      enable = true;
      settings = pkgs.stubby.passthru.settingsExample // {
        upstream_recursive_servers = [{
          address_data = "1.1.1.1";
          tls_auth_name = "cloudflare-dns.com";
          tls_pubkey_pinset = [{
            digest = "sha256";
            value = "GP8Knf7qBae+aIfythytMbYnL+yowaWVeD6MoLHkVRg=";
          }];
        } {
          address_data = "1.0.0.1";
          tls_auth_name = "cloudflare-dns.com";
          tls_pubkey_pinset = [{
            digest = "sha256";
            value = "GP8Knf7qBae+aIfythytMbYnL+yowaWVeD6MoLHkVRg=";
          }];
        }];
      };
    };
}
