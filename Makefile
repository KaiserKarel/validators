wakey:
	GIT_LFS_SKIP_SMUDGE=1 nixos-rebuild --target-host wakey --use-remote-sudo switch --flake ./#wakey

wakey-rpc:
	GIT_LFS_SKIP_SMUDGE=1 nixos-rebuild --target-host wakey-rpc --use-remote-sudo switch --flake ./#wakey-rpc
	