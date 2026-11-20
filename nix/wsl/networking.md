# Networking

By default, each WSL2 distro sits behind an internal NAT virtual switch private to its Windows host (`172.x.x.x`), making it unreachable from other machines on your LAN. To let two **NixOS-WSL** instances on separate Windows hosts communicate directly over your local network, choose one of three approaches depending on your network setup and whether you want direct LAN bridging or zero-config overlay routing.

---

### Method 1: WSL2 Mirrored Networking + Windows Firewall (Recommended for Same LAN)

Enabling `networkingMode=mirrored` in Windows shares the Windows host's LAN IP address directly with NixOS-WSL. Any port NixOS listens on is reachable at the Windows host's LAN IP without manual `netsh` port-forwarding rules.

#### 1. Enable Mirrored Mode on Both Windows Hosts

Create or edit `C:\Users\<YourUser>\.wslconfig` on **both** Windows machines:

```ini
[wsl2]
networkingMode=mirrored
dnsTunneling=true
autoProxy=true

```

Restart WSL from PowerShell on both machines to apply:

```powershell
wsl --shutdown

```

*Verification:* Inside each NixOS shell, run `ip addr`—you should now see your physical host's LAN IP (e.g., `192.168.1.x`) assigned to an interface inside WSL2.

#### 2. Open Ports in NixOS (configuration.nix)

Enable the service you want to reach (such as OpenSSH) and allow its port through the NixOS firewall on both NixOS instances:

```nix
{ config, pkgs, ... }:

{
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false; # or true if using passwords
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ]; # Add any app/dev server ports here
  };
}

```

Rebuild NixOS:

```bash
sudo nixos-rebuild switch

```

*Verification:* Run `ss -tulpn` inside NixOS to confirm the daemon is listening on `0.0.0.0:22` or `:::22`.

#### 3. Allow Inbound Traffic in Windows Hyper-V Firewall

Even in mirrored mode, Windows' Hyper-V firewall blocks inbound connections to WSL2 by default. On **each** Windows host (in an **Administrator PowerShell**), allow inbound connections on the target port (e.g., TCP 22 for SSH):

```powershell
New-NetFirewallRule -DisplayName "Allow WSL2 SSH" -Direction Inbound -InterfaceAlias "vEthernet (WSL (Hyper-V firewall))" -Action Allow -Protocol TCP -LocalPort 22

```

*(Alternatively, to allow all inbound LAN traffic to WSL2 on a trusted private home network: `Set-NetFirewallHyperVVMSetting -Name '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -DefaultInboundAction Allow`.)*

*Verification:* From NixOS on Host A, connect to Host B's Windows LAN IP:

```bash
ssh <user>@<Host-B-LAN-IP>

```

---

### Method 2: Tailscale / WireGuard Overlay (Easiest Across NATs & Firewalls)

If you want the two NixOS-WSL distros to reach each other by hostname without touching `.wslconfig`, Hyper-V firewall rules, or Windows port forwarding, run **Tailscale** directly inside both NixOS-WSL instances.

#### 1. Enable Tailscale in NixOS (`configuration.nix`)

Add `services.tailscale.enable = true;` (and optionally integrate `sops-nix` with `authKeyFile` if automating enrollment):

```nix
{ config, pkgs, ... }:

{
  services.tailscale.enable = true;

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
}

```

Apply and authenticate on both NixOS distros:

```bash
sudo nixos-rebuild switch
sudo tailscale up

```

*Verification:* Run `tailscale status` on both NixOS instances—each will list the other with a `100.x.y.z` IP and MagicDNS hostname. Run `ping -c 2 <other-nixos-hostname>` to confirm direct peer-to-peer connectivity.

---

### Method 3: Default NAT Mode + Windows Port Forwarding (`netsh`)

If you cannot use `networkingMode=mirrored` (e.g., on older Windows builds or incompatible corporate VPN clients), keep default NAT networking and forward specific ports from each Windows host to its WSL2 internal IP:

1. Find the WSL2 internal IP inside NixOS:

```bash
ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'

```

2. On the corresponding Windows host (**Admin PowerShell**), forward the LAN port to WSL2 and open the Windows firewall:

```powershell
netsh interface portproxy add v4tov4 listenport=2222 listenaddress=0.0.0.0 connectport=22 connectaddress=<WSL2-Internal-IP>
New-NetFirewallRule -DisplayName "WSL2 SSH Forward" -Direction Inbound -Protocol TCP -LocalPort 2222 -Action Allow

```

*(Note: In default NAT mode, WSL2's internal IP changes across reboots unless updated by a startup script, making Method 1 or Method 2 much cleaner for persistent setups.)*

*Verification:* From the other NixOS distro, connect via `ssh -p 2222 <user>@<Windows-Host-LAN-IP>`.
In Windows' `.wslconfig` (under `[wsl2]`), **`autoProxy=true`** instructs WSL2 to automatically mirror your Windows host's HTTP/HTTPS proxy settings into your Linux environment.

---

### What It Actually Does Under the Hood

* **Syncs Windows Proxy Configuration:** WSL2 reads the proxy settings configured in Windows (under **Settings > Network & internet > Proxy**, including manual proxy servers and PAC auto-config scripts) and automatically injects the standard proxy environment variables (`http_proxy`, `https_proxy`, `HTTP_PROXY`, `HTTPS_PROXY`, `no_proxy`, `NO_PROXY`) into your WSL2 distros.
* **Dynamic Updates Without Restarting WSL:** If your Windows proxy changes—such as when you connect or disconnect a corporate VPN, switch Wi-Fi networks, or change proxy settings in Windows—WSL2 dynamically updates the proxy environment inside Linux without requiring a `wsl --shutdown`.
* **Localhost Loopback Translation:** If your Windows host uses a local proxy listening on `127.0.0.1` or `localhost` (common with corporate security agents or local debugging proxies), WSL2 translates that address so Linux tools can reach the proxy running on the Windows side.

---

### When It Matters (and When It Doesn't)

* **Useful on corporate/managed laptops:** If your company routes web traffic through an HTTP/HTTPS proxy or PAC file (or switches proxies when a VPN connects), `autoProxy=true` prevents `nix build`, `curl`, `git`, and package downloads inside NixOS-WSL from failing due to missing proxy variables.
* **No effect on standard home/direct networks:** If Windows has no proxy configured, `autoProxy=true` leaves your Linux environment unchanged.
* **Systemd services in NixOS:** `autoProxy` populates environment variables for interactive WSL sessions launched via WSL's init; background `systemd` daemons inside NixOS (like `nix-daemon.service`) may not inherit user session environment variables automatically unless configured or restarted after proxy changes.

---

### How to Verify Inside NixOS-WSL

Run `env | grep -i proxy` inside your NixOS shell:

* If a proxy is active in Windows, you will see `http_proxy=...` and `https_proxy=...` populated automatically.
* If no proxy is configured on your Windows host, the command will return nothing.
