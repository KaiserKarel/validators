{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    union.url = "git+ssh://git@github.com/unionlabs/union";
    sops-nix.url = "github:Mic92/sops-nix";
  };
  outputs = { self, nixpkgs, union, sops-nix, ... }:
    {
      nixosConfigurations.wakey-rpc =
        let
          system = "x86_64-linux";
          pkgs = import nixpkgs { inherit system; };
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            union.nixosModules.unionvisor
            {
              system.stateVersion = "23.11";
              # Base configuration for openstack-based VPSs
              imports = [
                "${nixpkgs}/nixos/modules/virtualisation/openstack-config.nix"
                sops-nix.nixosModules.sops
              ];

              sops = {
                age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
                secrets = {
                  datadog_api_key = {
                    restartUnits = [ "datadog-agent.service" ];
                    path = "/etc/datadog-agent/datadog_api.key";
                    sopsFile = ./secrets/datadog.yaml;
                    mode = "0440";
                    owner = "datadog";
                  };
                  priv_validator_key = {
                    restartUnits = [ "unionvisor.service" ];
                    format = "binary";
                    sopsFile = ./secrets/wakey-rpc/priv_validator_key.json;
                    path = "/var/lib/unionvisor/home/config/priv_validator_key.json";
                  };
                };
              };

              # Allow other validators to reach you
              networking.firewall.allowedTCPPorts = [ 80 443 26656 26657 ];

              # Unionvisor module configuration
              services.unionvisor = {
                enable = true;
                moniker = "wakey-wakey-rpc";
              };

              nix = {
                settings = { auto-optimise-store = true; };
                gc = {
                  automatic = true;
                  dates = "weekly";
                  options = "--delete-older-than 15d";
                };
              };

              users.users.datadog.extraGroups = [ "systemd-journal" ];

              services.datadog-agent = {
                enable = true;
                apiKeyFile = "/etc/datadog-agent/datadog_api.key";
                enableLiveProcessCollection = true;
                enableTraceAgent = true;
                site = "datadoghq.eu";
                extraIntegrations = { openmetrics = _: [ ]; };
                extraConfig = { logs_enabled = true; };
                checks = {
                  journald = { logs = [{ type = "journald"; }]; };
                  openmetrics = {
                    init_configs = { };
                    instances = [{
                      openmetrics_endpoint = "http://localhost:26660/metrics";
                      namespace = "cometbft";
                      metrics = [
                        ".*"
                      ];
                    }];
                  };
                };
              };

              # OPTIONAL: Some useful inspection tools for when you SSH into your validator
              environment.systemPackages = with pkgs; [
                bat
                bottom
                helix
                jq
                neofetch
                tree
              ];
            }
          ];
        };
      nixosConfigurations.wakey =
        let
          system = "x86_64-linux";
          pkgs = import nixpkgs { inherit system; };
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            union.nixosModules.unionvisor
            {
              system.stateVersion = "23.11";
              # Base configuration for openstack-based VPSs
              imports = [
                "${nixpkgs}/nixos/modules/virtualisation/openstack-config.nix"
                sops-nix.nixosModules.sops
              ];

              # Allow other validators to reach you
              networking.firewall.allowedTCPPorts = [ 80 443 26656 26657 ];

              # Unionvisor module configuration
              services.unionvisor = {
                enable = true;
                moniker = "wakey-wakey";
              };

              nix = {
                settings = { auto-optimise-store = true; };
                gc = {
                  automatic = true;
                  dates = "weekly";
                  options = "--delete-older-than 15d";
                };
              };

              sops = {
                age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
                secrets = {
                  datadog_api_key = {
                    restartUnits = [ "datadog-agent.service" ];
                    path = "/etc/datadog-agent/datadog_api.key";
                    sopsFile = ./secrets/datadog.yaml;
                    mode = "0440";
                    owner = "datadog";
                  };
                  priv_validator_key = {
                    restartUnits = [ "unionvisor.service" ];
                    format = "binary";
                    sopsFile = ./secrets/wakey/priv_validator_key.json;
                    path = "/var/lib/unionvisor/home/config/priv_validator_key.json";
                  };
                };
              };

              users.users.datadog.extraGroups = [ "systemd-journal" ];

              services.datadog-agent = {
                enable = true;
                apiKeyFile = "/etc/datadog-agent/datadog_api.key";
                enableLiveProcessCollection = true;
                enableTraceAgent = true;
                site = "datadoghq.eu";
                extraIntegrations = { openmetrics = _: [ ]; };
                extraConfig = { logs_enabled = true; };
                checks = {
                  journald = { logs = [{ type = "journald"; }]; };
                  openmetrics = {
                    init_configs = { };
                    instances = [{
                      openmetrics_endpoint = "http://localhost:26660/metrics";
                      namespace = "cometbft";
                      metrics = [
                        ".*"
                      ];
                    }];
                  };
                };
              };

              # OPTIONAL: Some useful inspection tools for when you SSH into your validator
              environment.systemPackages = with pkgs; [
                bat
                bottom
                helix
                jq
                neofetch
                tree
              ];
            }
          ];
        };
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
    };
}
