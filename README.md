# Nix configurations for validators.

This repo contains my configurations for validators (through Nixos). The current implementation is a little bit hands-on.

To make this work:

```
nix-build image.nix
```

The machine image can be used with digital ocean to deploy new nixos machines. Make sure to enable ssh access.

For secrets management, I use sops-nix. The flow after creating a new machine is approximately:

1. copy and remove /var/lib/unionvisor/home/config/priv_validator_key.json to my work machine.
2. edit the config.toml to enable prometheus and set the seeds.
3. add priv_validator_key to my sops-nix config, encrypt 
4. nixos-rebuild switch... to redeploy.

The above ensures that I have checked-in encrypted backups of my secrets, and that for secret-rotation I just need to redeploy.