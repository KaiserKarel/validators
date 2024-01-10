{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    union.url = "github:unionlabs/union";
    sops-nix.url = "github:Mic92/sops-nix";
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, union, sops-nix, crane, ... }:
    {
      nixosConfigurations.kaiserkarel =
        let
          system = "x86_64-linux";
          pkgs = import nixpkgs { inherit system; };
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            sops-nix.nixosModules.sops
            union.nixosModules.unionvisor
            "${nixpkgs}/nixos/modules/virtualisation/openstack-config.nix"
            {
              system.stateVersion = "23.11";

              networking.firewall.allowedTCPPorts = [ 80 443 26656 26657 26666 ];
              networking.hostName = "kaiserkarel";

              services.unionvisor = {
                enable = true;
                moniker = "kaiserkarel";
                seeds = "a069a341154484298156a56ace42b6e6a71e7b9d@blazingbit.io:27656";
              };

              users.users.datadog.extraGroups = [ "systemd-journal" ];

              services.datadog-agent = {
                enable = true;
                package = pkgs.datadog-agent.override {
                  extraTags = [ "docker" ];
                };
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
                    instances = [
                      {
                        openmetrics_endpoint = "http://localhost:26660/metrics";
                        namespace = "cometbft";
                        metrics = [
                          ".*"
                        ];
                      }
                    ];
                  };
                };
              };

              users.users.root.openssh.authorizedKeys.keys = [
                ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINmoB0Q5eqWmTgXnh4PU8G9J5Rq9OXaNjf5nmbXS5nhv''
                ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAY6rYPYLUl8ccZsZUUZgTyqpwp0CUIYsBhy+4Ub/UuB''
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
                    sopsFile = ./secrets/kaiserkarel/priv_validator_key.json;
                    path = "/var/lib/unionvisor/home/config/priv_validator_key.json";
                  };
                  hubble-key = {
                    restartUnits = [ "hubble.service" ];
                    path = "/etc/hubble/hubble.key";
                    sopsFile = ./secrets/kaiserkarel/hubble.key;
                    format = "binary";
                  };
                };
              };

              nix = {
                settings = { auto-optimise-store = true; };
                gc = {
                  automatic = true;
                  dates = "weekly";
                  options = "--delete-older-than 15d";
                };
              };

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
