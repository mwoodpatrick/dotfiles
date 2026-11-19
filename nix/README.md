# README

Copy of Nix 26.05 configuration files for WSL-2

configuration.nix -> /etc/nixos

.wslconfig -> %UserProfile%

boot_wsl.ps1 -> %UserProfile%

wsl.conf -> /etc

[Advanced settings configuration in WSL](https://learn.microsoft.com/en-us/windows/wsl/wsl-config)

# NixOS 26.05

The latest stable version of NixOS is 26.05, codenamed "Yarara", which was released on May 30, 2026.

This release will receive security updates and bug fixes through December 31, 2026. The previous stable release, 25.11 ("Xantusia"), officially reached its end-of-life on June 30, 2026.

## Key Highlights in 26.05

- **Systemd Stage 1:** Stage 1 (initrd) is now based on systemd by default.
- **GNOME 50:** GNOME desktop environment updated to version 50 ("Tokyo").
- **Toolchain Updates:** GCC 15, LLVM 21, Node.js 24 LTS, Ruby 3.4.
- **x86_64-darwin Deprecation:** Final Nixpkgs release with official Intel Mac support.

## References

- [NixOS 26.05 released](https://nixos.org/blog/announcements/2026/nixos-2605/)
- [NixOS Releases](https://endoflife.date/nixos)

## NixOS on WSL

The recommended approach is using NixOS-WSL.

### Prerequisites

- Windows 11 or Windows 10 Build 19041+
- Updated WSL2 kernel
