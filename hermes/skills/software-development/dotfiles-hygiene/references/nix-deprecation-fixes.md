# Nix Deprecation Fixes for This Dotfiles Flake

This reference captures Nix/NixOS deprecation renames that have come up while maintaining the WSL dotfiles configuration, so future rebuilds do not need to rediscover them.

## `pkgs.system` → `pkgs.stdenv.hostPlatform.system`

### Symptom

`nixos-rebuild` prints:

```
'system' has been renamed to/replaced by 'stdenv.hostPlatform.system'
```

### Where it appears

Any module or package set expression that reads `pkgs.system` to select a flake package output, e.g.:

```nix
inputs.hermes-agent.packages.${pkgs.system}.default
```

### Fix

Replace `pkgs.system` with `pkgs.stdenv.hostPlatform.system`:

```nix
inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
```

### Note

The `system` argument passed to `nixpkgs.lib.nixosSystem` and the `system` binding in `flake.nix` are still valid — only the `pkgs.system` accessor is deprecated.

## General approach

When a rebuild emits a "renamed to/replaced by" warning:

1. Run the rebuild with `-v` or `--show-trace` if the file location is unclear.
2. Search the repository for the deprecated identifier.
3. Replace the deprecated form with the modern form in all matching modules.
4. Rebuild to confirm the warning is gone.
5. Commit the fix separately from unrelated changes.

## Related files in this repo

- `nixos-wsl/nixos/configuration.nix`
- `nixos-wsl/nixos/home.nix` (already uses `pkgs.stdenv.hostPlatform.system` in most places)
- `nixos-wsl/nixos/flake.nix` (uses the top-level `system` binding, which is fine)
