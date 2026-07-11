# scripts/boot_wsl.ps1
Write-Host "Starting WSL ..."
wsl --shutdown
wsl --update --pre-release
# # wsl
# # [Mount a Linux disk in WSL 2](https://learn.microsoft.com/en-us/windows/wsl/wsl2-mount-disk)
# # New-VHD -Path .\Storage\projects5.vhdx  -SizeBytes 256GB -Dynamic -BlockSizeBytes 1MB
# # wsl.exe --mount --vhd Storage\projects5.vhdx --bare
# # sudo mkfs -t ext4 /dev/sdj
# # wsl.exe --mount --vhd C:/Users/mlwp/Storage/projects5.vhdx  --name projects5
wsl --mount --vhd C:/Users/mlwp/Storage/projects.vhdx --name projects
# wsl --mount --vhd C:/Users/mlwp/Storage/projects2.vhdx --name projects2
# wsl --mount --vhd C:/Users/mlwp/Storage/projects3.vhdx --name projects3
# wsl --mount --vhd C:/Users/mlwp/Storage/projects4.vhdx --name projects4
# wsl --mount --vhd C:/Users/mlwp/Storage/projects5.vhdx --name projects5
# # [LVM](https://wiki.archlinux.org/title/LVM)
# # wsl --mount --vhd C:/Users/mlwp/Storage/LVM/vhosts_vg/volume1.vhdx --bare
# # wsl -d Fedora
# # wsl -d Westie-OS-rel2
# # wsl -d Westie-OS-rel3
# wsl -d Debian
# wsl -d Ubuntu-22.04
# wsl -d Ubuntu-24.04
# wsl.exe -d ubuntu-24.04-wayland-simple
# wsl.exe -d ubuntu-24.04-wayland-full
# wsl -d NixOS
# wsl # boot default OS nix-wsl
# wsl.exe -d nix-wsl-temp
# wsl.exe -d nix-wsl-vm-enabled
# wsl -d Ubuntu-24.04-desktop
wsl -d NixOS
Write-Host "LN: lsblk"
Write-Host "LN: df -h"
Write-Host "LN: systemctl status"
