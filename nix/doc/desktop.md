# Desktop

# Startup

On startup/login the following files are processed:

- ~/.bash_profile (which sources ~/.profile and .bashrc)
- ~/.profile  which sources /nix/store/<hash>-hm-session-vars.sh/etc/profile.d/hm-session-vars.sh" sets PATH env var to export PATH="$HOME/.local/bin:$PATH". Currently these sessions files set the XDG env vars need to review this
- ~/.bashrc which sources $XDG_CONFIG_HOME/bash/init.bash

export LOCALE_ARCHIVE_2_27="/nix/store/7c57qdfwri1vx6ywbadk30wplcmxb06q-glibc-locales-2.42-103/lib/locale/locale-archive"
export NIX_XDG_DESKTOP_PORTAL_DIR="/etc/profiles/per-user/mwoodpatrick/share/xdg-desktop-portal/portals"
export OLLAMA_API_KEY_FILE="/run/secrets/OLLAMA_API_KEY"
export OLLAMA_HOST="http://localhost:11434"
export STARSHIP_CONFIG="/mnt/wsl/projects/git/dotfiles/starship.toml"
export XDG_BIN_HOME="/home/mwoodpatrick/.local/bin"
export XDG_CACHE_HOME="/home/mwoodpatrick/.cache"
export XDG_CONFIG_HOME="/mnt/wsl/projects/git/dotfiles"
export XDG_DATA_HOME="/mnt/wsl/projects/data"
export XDG_STATE_HOME="/home/mwoodpatrick/.local/state"


# KDE

Running **KDE Plasma 6** on **NixOS-WSL** works best by pairing NixOS's declarative `services.desktopManager.plasma6` module with **XRDP** (so you get a full, isolated KDE desktop window via Windows Remote Desktop Connection without conflicting with WSLg's built-in Wayland compositor). Currently this is using an X11 server, I need to look into Wayland support. We current set GDK_BACKEND=x11: Explicitly tells GTK4 to connect to XRDP's X11 display rather than looking for a Wayland socket. We also set LIBGL_ALWAYS_SOFTWARE=1: Forces Mesa's llvmpipe software OpenGL renderer if /dev/dxg hardware acceleration is not exposed to the Xorg XRDP session.

If you only want individual KDE apps (like Dolphin, Kate, or Konsole) appearing as native Windows windows via WSLg, you do not need XRDP at all—only the packages. Below are both setups.

---

### Option 1: Full KDE Plasma 6 Desktop via XRDP (Recommended)

Because WSL2 does not expose physical DRM/GPU display hardware to a traditional Linux login screen (SDDM), connecting via **Windows Remote Desktop (`mstsc.exe`)** over XRDP is the cleanest way to run a complete Plasma desktop.

#### 1. Ensure `systemd` and a User Password Are Set

NixOS-WSL enables `systemd` by default, which Plasma 6 requires for D-Bus and user session services. XRDP also requires a Linux password for your WSL user (since WSL defaults to passwordless login).

Inside your NixOS-WSL terminal, set a password for your user (`mwoodpatrick` or your configured `wsl.defaultUser`), see [secrets.md](secrets.md)
#### 2. Add KDE Plasma 6 and XRDP to Your NixOS Configuration

In your NixOS configuration (e.g., `/etc/nixos/configuration.nix` or your host module), enable Plasma 6, X11, and `xrdp` on a non-conflicting port (using `3390` avoids colliding with Windows' own RDP service on `3389`):

```nix
{ config, pkgs, ... }:

{
  # Enable X11 and KDE Plasma 6
  services.xserver = {
    enable = true;
    xkb.layout = "us";
  };

  services.desktopManager.plasma6.enable = true;

  # Enable XRDP on port 3390 to avoid conflicting with Windows RDP (3389)
  services.xrdp = {
    enable = true;
    port = 3390;
    defaultWindowManager = "startplasma-x11";
    openFirewall = true;
  };

  # Ensure WSL2 systemd is active
  wsl.enable = true;

  # Optional: useful KDE utilities & clipboard tools
  environment.systemPackages = with pkgs; [
    kdePackages.konsole
    kdePackages.dolphin
    kdePackages.kate
    xclip
  ];
}

```

*(Tip: Enabling `plasma6` automatically enables PipeWire audio; if you don't want audio daemons running inside WSL2, add `services.pipewire.enable = lib.mkForce false;`.)*

#### 3. Rebuild NixOS and Restart WSL

Apply the configuration:

```bash
sudo nixos-rebuild switch

```

*Verification:* Check that XRDP is listening on port 3390:

```bash
ss -tulpn | grep 3390

```

You should see `xrdp` bound to `0.0.0.0:3390` or `*:3390`.

#### 4. Connect from Windows Remote Desktop

1. Press **Win + R** on Windows, type `mstsc`, and press **Enter**.
2. In **Computer**, enter `localhost:3390` and click **Connect**.
3. At the XRDP login prompt, keep the session set to **Xorg**, enter your NixOS username and the password you set in Step 1, and click **OK**.

---

### Option 2: Run KDE Apps Directly on Windows via WSLg (No Full Desktop)

If you only want KDE apps (Dolphin, Okular, Kate, KDevelop) integrated directly into the Windows taskbar via **WSLg** rather than a separate Plasma desktop:

1. Add the KDE packages you want to `environment.systemPackages` (without enabling `xrdp` or `xserver`):

```nix
environment.systemPackages = with pkgs; [
  kdePackages.dolphin
  kdePackages.konsole
  kdePackages.kate
  kdePackages.breeze-icons
];

```

2. Run `sudo nixos-rebuild switch`.


3. Launch any KDE app directly from your NixOS terminal (e.g., `dolphin &` or `kate &`)—WSLg automatically renders the window on your Windows desktop.

---

### Common WSL2 + KDE Gotchas

* **Black screen on XRDP login:** Make sure you log in with a **non-root** user (`wsl.defaultUser`) and wait a few seconds after starting WSL for `systemd` user units to finish initializing.


* **KWallet password popups on every login:** Because XRDP does not unlock KWallet via PAM the way SDDM does on bare metal, open **KDE Wallet** (`kwalletmanager5`) on first login and either leave the wallet password blank or disable the wallet subsystem if you don't need it.
* **HiDPI / Blurry scaling in Remote Desktop:** In Windows Remote Desktop (`mstsc`), click **Show Options > Display** before connecting, or inside KDE go to **System Settings > Display & Monitor** and adjust the **Scale** slider.

# Hardware accelerated desktop

Yes—with standard **XRDP (`Xorg` / `xorgxrdp`)**, you are giving up hardware GPU acceleration by default, and audio/video behave differently than they do under WSLg. Here is how each subsystem behaves in WSL2 and what options you have:

---

### 1. Hardware GPU Acceleration (3D / OpenGL / Vulkan)

* **Standard XRDP (`xorgxrdp`) = CPU Software Rendering:**
By default, XRDP's Xorg backend renders the entire Plasma desktop and OpenGL applications on the CPU using Mesa's **`llvmpipe`** software rasterizer, then compresses screen updates over RDP. For terminals, editors, and standard desktop apps this feels smooth over `localhost`, but KWin desktop effects (blur, transparency), 3D/OpenGL apps, and GPU compute inside that X session will run on the CPU.
* **Why WSLg Has GPU Acceleration (and XRDP Doesn't Out of the Box):**
WSL2 exposes your Windows GPU to Linux via **`/dev/dxg`** (DirectX paravirtualization) and Mesa's **`d3d12`** Gallium driver (and Dozen for Vulkan). WSLg's Weston compositor is built specifically to use `/dev/dxg` + `d3d12` for hardware-accelerated OpenGL/EGL and zero-copy buffer sharing with Windows.
* **Can You Get GPU Acceleration in XRDP?**
* *NixOS-WSL GPU driver setup:* Regardless of desktop, NixOS-WSL needs `wsl.useWindowsDriver = true;` (which mounts Windows' `/usr/lib/wsl/lib` drivers and exposes `/dev/dxg`) plus `hardware.graphics.enable = true;` for apps to see the Windows GPU.
* *XRDP + Glamor (`xorgxrdp` with `glamor`):* While `xorgxrdp` has experimental `glamor` support to offload 2D/3D acceleration to a DRM render node (`/dev/dri/renderD128`), WSL2 exposes `/dev/dxg` rather than a standard Linux DRM render node unless translated via Mesa's `d3d12` backend—meaning getting hardware-accelerated OpenGL inside `xorgxrdp` on WSL2 is fragile and not supported out of the box in NixOS's `services.xrdp` module.
* *Workaround if you need GPU-accelerated apps:* Even when running your desktop via XRDP, you can launch a specific GPU-heavy app (like a browser, 3D viewer, or Vulkan/CUDA workload) from Konsole with `WAYLAND_DISPLAY=wayland-0 DISPLAY=:0 <app>` so that individual window renders directly through WSLg's GPU-accelerated compositor while the rest of your Plasma desktop stays in XRDP.



---

### 2. Audio (Playback & Microphone)

* **XRDP Audio Redirection:**
Windows Remote Desktop (`mstsc.exe`) natively supports bidirectional RDP audio redirection (**Local Resources > Remote audio > Play on this computer / Record from this computer**), **provided** PipeWire or PulseAudio inside NixOS loads the **`module-xrdp-sink` / `module-xrdp-source**` plugin (`pulseaudio-module-xrdp`).
* **WSLg PulseAudio (`PULSE_SERVER`) Alternative (Simpler on WSL2):**
WSLg already runs a PulseAudio/RDP audio bridge in the background accessible via `/mnt/wslg/PulseServer`. Instead of configuring `pulseaudio-module-xrdp`, you can point your XRDP session's environment at WSLg's PulseAudio server:
```nix
environment.variables.PULSE_SERVER = "unix:/mnt/wslg/PulseServer";

```


With `PULSE_SERVER` set (and PipeWire/PulseAudio inside NixOS acting as a client or routing to it), audio from KDE apps inside XRDP plays directly through Windows' audio mixer—and continues playing even if you minimize or disconnect the RDP window.

---

### 3. Video Playback & Webcam

* **Video Playback (YouTube, VLC, mpv):**
* **Works fine for normal resolutions (1080p):** Video plays smoothly over `localhost` RDP, though decoding and color-space conversion happen on the CPU (`llvmpipe` / software `ffmpeg`) and frames are re-encoded by XRDP's RemoteFX/AVC codec to send to `mstsc.exe`.
* **High-resolution / 4K / High-FPS video:** Will use noticeably more CPU and show higher latency/frame drops than WSLg because there is no hardware VA-API/D3D12 video decode pipeline inside the XRDP Xorg session.


* **Webcam / Video Capture:**
* WSL2's default kernel does **not** include USB/UVC webcam drivers or pass Windows webcams through to `/dev/video*` automatically, and `mstsc.exe` does not forward webcams to XRDP on Linux. To use a webcam in NixOS-WSL, you must attach the USB camera via **`usbipd-win`** from Windows and ensure the WSL2 kernel has UVC (`CONFIG_MEDIA_USB_SUPPORT` / `CONFIG_USB_VIDEO_CLASS`) enabled.



---

### Summary Comparison

| Capability | XRDP (`startplasma-x11`) | WSLg (Individual KDE Apps or Nested `kwin_wayland`) |
| --- | --- | --- |
| **Desktop Stability** | High (clean, isolated full Plasma 6 desktop) | Native for single apps; quirky/buggy for nested full desktop |
| **3D / OpenGL Acceleration** | CPU (`llvmpipe`) by default | Hardware accelerated via `/dev/dxg` + Mesa `d3d12` |
| **Audio Out / Mic** | Works via `PULSE_SERVER=unix:/mnt/wslg/PulseServer` or `xrdp` module | Works out of the box via `/mnt/wslg/PulseServer` |
| **Video Playback** | Smooth at 1080p (CPU-decoded + RDP-encoded) | Hardware-accelerated compositing |
| **Window Management** | Contained inside one Windows RDP window (full multi-monitor support in `mstsc`) | Seamless individual windows on Windows taskbar |


You actually **can** run KWin/Plasma 6 as a nested Wayland compositor inside WSLg (`kwin_wayland`), rather than it being strictly impossible—however, it is **not** recommended or used as the default desktop setup because of several architectural and runtime friction points between WSLg's Weston compositor, `kwin_wayland`, and NixOS's systemd session management.

---

### 1. Why a Nested `kwin_wayland` Session Is Problematic on WSLg

* **Socket Collision (`WAYLAND_DISPLAY=wayland-0`):**
WSLg mounts its host Weston Wayland socket into `$XDG_RUNTIME_DIR/wayland-0` (symlinked from `/mnt/wslg/runtime-dir/wayland-0`). When you start a nested `kwin_wayland` instance, KWin tries to bind a Wayland socket for its own clients (`plasmashell`, KDE apps)—either colliding with `wayland-0` or binding `wayland-1`, which forces you to carefully isolate environment variables so Plasma components connect to KWin (`wayland-1`) rather than escaping directly to WSLg's host Weston compositor (`wayland-0`).
* **Systemd Session & D-Bus Activation Conflicts:**
Modern Plasma 6 relies heavily on `systemd --user` units (`plasma-plasmashell.service`, `plasma-kwin_wayland.service`, `xdg-desktop-portal-kde`) to orchestrate startup. In NixOS-WSL, your user's `systemd` session already inherits WSLg's `WAYLAND_DISPLAY=wayland-0` and `DISPLAY=:0` via the WSLg environment generator. Launching a nested Plasma session requires overriding the systemd user environment and D-Bus activation environment without breaking WSLg's integration for regular terminal-launched apps.
* **Limited Wayland Protocol & Input/Windowing Support in WSLg's Weston:**
WSLg uses a customized **Weston** compositor paired with **FreeRDP** (`mstsc` under the hood) to project individual Linux windows onto the Windows desktop. Running a full desktop shell (`plasmashell`) inside a nested Wayland window over WSLg's Weston often runs into:
* **Pointer locking, relative pointer, and global shortcut issues:** Windows intercepts system keybinds (like `Alt+Tab`, `Super`/Win key, and window snapping), and Weston's nested surface handling can cause focus/redraw stalls or broken multi-monitor/HiDPI fractional scaling.
* **WSLg's `d3d12` Mesa driver quirks:** Nested compositing (KWin rendering into a Wayland buffer over Mesa's `d3d12` Gallium driver, which WSLg's Weston then composites and streams via RDP to Windows) adds an extra compositing/GPU translation layer that frequently triggers rendering glitches, cursor artifacts, or frame pacing issues compared to X11/XRDP.


* **No Display Manager (SDDM) Support:**
NixOS's `services.desktopManager.plasma6.enable = true` expects a login manager (SDDM) and a DRM/KMS seat (`logind`) to launch `startplasma-wayland`. Because WSL2 lacks a physical DRM/KMS display seat, SDDM cannot start a Wayland session natively—meaning a nested `kwin_wayland` session has to be manually scripted with `dbus-run-session` rather than configured declaratively via standard NixOS display manager options.

---

### 2. How to Actually Run Nested Plasma 6 on WSLg (If You Want to Test It)

If you want to experiment with running Plasma 6 nested inside a single WSLg window instead of using XRDP:

1. **Install Plasma 6 in NixOS** (enable `services.desktopManager.plasma6.enable = true;`, and disable SDDM since it won't run on WSL2: `services.displayManager.sddm.enable = lib.mkForce false;`).
2. **Launch a nested KWin + Plasma session** from your NixOS terminal using `dbus-run-session` so it creates an isolated session bus and nested Wayland socket (`wayland-1`) on top of WSLg's `wayland-0`:
```bash
dbus-run-session -- kwin_wayland --xwayland --exit-with-session startplasma-wayland

```


*Verification:* A single native Windows window titled **KDE Wayland Compositor** will open via WSLg containing the full Plasma 6 desktop panel, wallpaper, and launcher.

*(Note: Because WSLg uses FreeRDP under the hood to render Linux windows onto Windows anyway, using **XRDP + `startplasma-x11**` gives you direct RDP rendering without double-compositing through Weston—which is why XRDP remains the smoother daily-driver setup for a full Plasma desktop on WSL2.)*

---

For a walkthrough of setting up KDE Plasma 6 in NixOS on WSL2, see [How To install KDE 6 via NixOS and Windows 11 - WSL](https://www.youtube.com/watch?v=OptlWSuKHSw).

# Nested Wayland server

**No, you cannot use `startplasma-wayland` directly as an XRDP session backend.** Standard XRDP (`xorgxrdp`) speaks only the **X11** display protocol and cannot host a native Wayland compositor (`kwin_wayland`) directly.

### Why `startplasma-wayland` Fails with XRDP

* **Xorg-Only Backend:** XRDP's session manager (`xrdp-sesman`) starts an X11 server (`Xorg` using the `xorgxrdp` driver) and executes your window manager inside it.
* **Compositor Mismatch:** `startplasma-wayland` attempts to initialize `kwin_wayland` directly on bare-metal DRM/KMS hardware (or a parent Wayland compositor). When invoked from XRDP's X11 session, it fails to acquire a DRM device or Wayland socket and terminates immediately (resulting in a black screen or instant RDP disconnect).

---

### Working Alternatives for Wayland Access on NixOS / WSL-2

Depending on what you need Wayland for, choose one of these two approaches:

#### 1. Run a Nested Wayland Compositor Inside Your `startplasma-x11` XRDP Session

If you want to keep your full KDE Plasma desktop over XRDP (`defaultWindowManager = "startplasma-x11"`) while running or testing Wayland applications (such as `tinywl` or a Wayland client) inside it:

* Launch a nested Wayland compositor inside your Plasma X11 terminal:
* **Nested KWin Wayland window:**



```bash
dbus-run-session kwin_wayland --x11

```

* **Or Weston / TinyWL inside X11:**

```bash
weston

```

* **Verification:** Inside that nested compositor window, `WAYLAND_DISPLAY` (e.g., `wayland-0` or `wayland-1`) is exported, allowing native Wayland apps to connect while XRDP continues streaming the outer X11 Plasma desktop.

#### 2. Use WSLg Directly for Native Wayland (Without XRDP)

If you are on NixOS in WSL-2 and do not strictly need the full KDE Plasma desktop shell:

* Run Wayland applications directly from your standard WSL terminal (`wsl.exe` or Windows Terminal) rather than inside XRDP.
* Windows 11's built-in **WSLg** (Weston) automatically provides both `WAYLAND_DISPLAY=wayland-0` and `DISPLAY=:0` with Direct3D12 GPU acceleration, rendering Wayland windows directly alongside your Windows desktop.


* **Verification:** Run `echo $WAYLAND_DISPLAY` in your standard WSL terminal; it should output `wayland-0`.
