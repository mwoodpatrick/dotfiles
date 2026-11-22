[Firefox](https://wiki.nixos.org/wiki/Firefox)

On **NixOS running in WSL2**, Firefox stores its runtime profiles, user preferences, and crash/diagnostic logs inside your Linux home directory (just like standard Linux), while declarative NixOS or Home Manager configurations live in `/etc/nixos` or your flake directory and compile into `/nix/store`.

There are two main reasons why paths are typically written relative to `~` (`~/.config/...` and `~/.cache/...`) rather than `$XDG_CONFIG_HOME` or `$XDG_CACHE_HOME`:

### 1. Default Behavior on NixOS-WSL

On a standard NixOS and NixOS-WSL installation, **`$XDG_CONFIG_HOME` and `$XDG_CACHE_HOME` are unset by default** (unless you explicitly set them in your shell environment or via Home Manager's `xdg.enable = true`).

Per the XDG Base Directory Specification, when those variables are unset or empty, applications fall back to `$HOME/.config` (`~/.config`) and `$HOME/.cache` (`~/.cache`). Writing `~/.config/mozilla/firefox` works out of the box whether those variables are exported in your environment or not, whereas pasting `$XDG_CONFIG_HOME/mozilla/firefox` into a terminal when `$XDG_CONFIG_HOME` is unset expands to `/mozilla/firefox` (a nonexistent root path).

### 2. How Firefox Resolves the Path Under the Hood

Starting with Firefox 147 on Linux, Mozilla updated Firefox's XDG lookup logic to follow the spec properly:

* **Configuration & Profiles:** `$XDG_CONFIG_HOME/mozilla/firefox` (falling back to `~/.config/mozilla/firefox` when unset).
* **Cache & Temporary Files:** `$XDG_CACHE_HOME/mozilla/firefox` (falling back to `~/.cache/mozilla/firefox` when unset).
* **Legacy Override:** If an existing `~/.mozilla` directory is already present when Firefox launches, Firefox continues using `~/.mozilla/firefox` for backward compatibility rather than migrating existing profiles automatically.

### Safe Shell Expansion Syntax

If you customize `XDG_CONFIG_HOME` or `XDG_CACHE_HOME` (or want shell commands that work regardless of whether they are set), use POSIX parameter expansion defaults:

```bash
"${XDG_CONFIG_HOME:-$HOME/.config}/mozilla/firefox"
"${XDG_CACHE_HOME:-$HOME/.cache}/mozilla/firefox"

```

In NixOS / Home Manager modules, you can also reference `config.xdg.configHome` and `config.xdg.cacheHome` directly, which resolve to `~/.config` and `~/.cache` by default and automatically track any custom XDG overrides you configure.
---

### 1. User Configuration & Profile Data

Firefox 147+ adopted the XDG Base Directory specification for new profiles, while older profiles or legacy Home Manager setups still use `~/.mozilla`. Check both locations depending on when your profile was first created:

* **Modern XDG Path (Firefox 147+ / NixOS 26.05+):**
* `~/.config/mozilla/firefox/` (contains `profiles.ini` and `<random-id>.default-release/`)
* Cache & temporary data: `~/.cache/mozilla/firefox/`


* **Legacy Path (Older profiles or `programs.firefox.configPath = ".mozilla/firefox"`):**
* `~/.mozilla/firefox/`



**Key Configuration Files Inside the Profile Folder (`<id>.default-release/`):**

* `prefs.js` — Active browser settings modified via `about:config` or the Settings UI.
* `user.js` — Optional user overrides loaded on startup (managed automatically if you use Home Manager's `programs.firefox.profiles.<name>.settings`).
* `containers.json`, `extensions.json`, `places.sqlite` — Bookmarks, history, and add-on state.

---

### 2. Declarative System & Home Manager Configuration (NixOS-Specific)

Unlike traditional distros where `/etc/firefox/policies/policies.json` is edited directly, NixOS wraps the Firefox binary with policies and preferences stored in the Nix store:

* **Your Nix Source Files:** `/etc/nixos/configuration.nix` (or your personal flake repository, such as `home.nix` / `modules/home-common.nix`) using `programs.firefox`.


* **Compiled Enterprise Policies & AutoConfig:** Generated inside `/nix/store/<hash>-firefox-<version>/lib/firefox/distribution/policies.json` (and `mozilla.cfg`), symlinked into `/run/current-system/sw/bin/firefox` or `~/.nix-profile/bin/firefox`.

---

### 3. Logs & Crash Reports

Firefox does **not** write a continuous general-purpose `firefox.log` file to `/var/log` by default. Instead, logs are split across crash directories, systemd journals, and optional runtime logging:

* **Crash Reports & Minidumps:**
* `~/.config/mozilla/firefox/Crash Reports/` (or `~/.mozilla/firefox/Crash Reports/`)
* Contains `submitted/` and `pending/` `.dmp` crash files and `events/` logs.


* **Startup / WSLg / Wayland / GPU Output (`stdout`/`stderr`):**
* If launched from your WSL terminal, errors print directly to your terminal.
* If launched via a desktop/WSLg launcher under systemd, check the user journal:



```bash
journalctl --user -e | grep -i firefox

```

* **Enabling Verbose HTTP / Gecko Debug Logs on Demand:**
* Launch Firefox from your NixOS-WSL shell with `MOZ_LOG` and `MOZ_LOG_FILE`:



```bash
MOZ_LOG="timestamp,nsHttp:3" MOZ_LOG_FILE="$HOME/firefox.log" firefox

```

```
*(Firefox appends process IDs to the filename, e.g., `firefox.log.moz_log`.)*

```

---

### Quick Command to Locate Your Active Profile Path

Run this inside your NixOS-WSL shell to print the exact profile directory currently in use:

```bash
find ~/.config/mozilla/firefox ~/.mozilla/firefox -maxdepth 2 -name "prefs.js" 2>/dev/null

```

**Yes.** If you install Firefox via `home.packages = [ pkgs.firefox ];` (or `environment.systemPackages`) without enabling `programs.firefox` in Home Manager or NixOS, Firefox behaves identically to a standard upstream Linux installation and reads/writes its profile and configuration directly from `$XDG_CONFIG_HOME/mozilla/firefox` (or `~/.mozilla/firefox` for legacy profiles).

That makes your Firefox config completely portable across NixOS and non-NixOS Linux distributions.

---

### 1. What Works Seamlessly Across NixOS & Non-Nix Distros

When `programs.firefox` is omitted, Home Manager does not lock or overwrite any files in your profile directory. You can symlink or sync your profile files via a standard dotfile manager (`stow`, `chezmoi`, `yadm`, or a shared Git repo) and use them across any Linux distro:

* **`user.js` (Portable Preferences):** Place a `user.js` file inside your profile folder (`$XDG_CONFIG_HOME/mozilla/firefox/<profile>/user.js`). On startup, Firefox copies those `user_pref(...)` settings into `prefs.js` on every distro without needing Nix.
* **`chrome/userChrome.css` & `chrome/userContent.css`:** Custom UI/CSS styling works identically across distros when `toolkit.legacyUserProfileCustomizations.stylesheets` is set to `true` in `user.js`.
* **`containers.json` & `search.json.mozlz4`:** Container definitions and search engine configs work across distros (provided you don't mount the same active profile directory simultaneously on two running browsers).

---

### 2. Important Caveats for Cross-Distro Sharing

* **Firefox Version Alignment (147+ vs. Older Distros):**
* Firefox 147+ defaults to `$XDG_CONFIG_HOME/mozilla/firefox` when no `~/.mozilla` directory exists.
* If one of your non-Nix distros runs an older ESR build (e.g., Firefox 128 ESR or 140 ESR) that only looks in `~/.mozilla/firefox`, either keep your shared profile in `~/.mozilla/firefox` (which Firefox 147+ automatically respects for backward compatibility) or symlink `~/.mozilla/firefox` to `$XDG_CONFIG_HOME/mozilla/firefox` on the older distro.


* **Extension Binaries & Native Messaging Hosts:**
* Add-ons installed through the Firefox Add-ons UI (`extensions/` and `extension-preferences.json`) sync across distros, **except** extensions that rely on external OS native messaging hosts (such as 1Password, KeePassXC, Bitwarden CLI, or Plasma Browser Integration).
* On NixOS, native messaging manifests live in `/nix/store/.../lib/mozilla/native-messaging-hosts/`, whereas on traditional distros they live in `/usr/lib/mozilla/native-messaging-hosts/` or `$XDG_CONFIG_HOME/mozilla/native-messaging-hosts/`.


* **Avoid Symlinking the Entire Profile Directory Across Live OSes:**
* `places.sqlite` (history/bookmarks), `cookies.sqlite`, and `lock` files are binary SQLite databases and lockfiles. Never share the live SQLite databases concurrently or commit them to Git; instead, track only declarative text files (`profiles.ini`, `user.js`, `chrome/`, `containers.json`) in your dotfiles repo and let Firefox Sync or local per-machine storage handle `places.sqlite` and session state.



---

### 3. Recommended Portable Setup in `home.nix`

In your shared Home Manager config (`modules/home-common.nix`), install the package without configuring `programs.firefox`:

```nix
{ pkgs, ... }:

{
  home.packages = [
    pkgs.firefox
  ];
}

```

Then manage `$XDG_CONFIG_HOME/mozilla/firefox/profiles.ini` and `$XDG_CONFIG_HOME/mozilla/firefox/default/user.js` in your cross-distro dotfiles repository (using `stow`, `chezmoi`, or `xdg.configFile` if you want Home Manager to symlink them on NixOS while keeping the source files plain text for non-Nix distros).

**Yes.** You can sync Firefox extensions (along with their settings) across both NixOS and non-NixOS hosts using **Firefox Sync** (simplest and works everywhere), **declarative Nix/Home Manager modules** (for NixOS hosts), or **Firefox Enterprise Policies** (portable JSON across any Linux distro).

Because your previous setup keeps Firefox unmanaged by `programs.firefox` so profile files stay portable across Nix and non-Nix distros, **Firefox Sync** is the cleanest drop-in option, while **`policies.json`** gives you declarative, file-based extension syncing across both NixOS and non-NixOS without needing a Mozilla account.

---

### Method 1: Firefox Sync (Easiest Cross-Distro & Cross-OS)

Firefox's built-in Sync works identically whether Firefox is installed via `pkgs.firefox` on NixOS-WSL or via `apt`/`dnf`/`pacman` on a traditional Linux distro—even when `programs.firefox` is omitted from `home.nix`.

1. Open Firefox on your primary machine and go to **Settings > Sync** (or `about:preferences#sync`).
2. Sign in with your Mozilla account, click **Change...** under *Syncing*, and verify **Add-ons** is checked (alongside **Settings** if you want extension preferences synced).
3. Sign into the same account on your other NixOS and non-Nix hosts. Firefox automatically downloads and enables your extensions from `addons.mozilla.org`.

*Verification:* Open `about:addons` (`Ctrl+Shift+A`) on the second host—your extensions appear automatically within a minute of signing in.

---

### Method 2: Declarative `policies.json` (Account-Free, Works on Both NixOS & Non-Nix)

If you want extensions installed automatically from files in your dotfiles/config repo without relying on a Mozilla account, use Firefox's **`ExtensionSettings`** enterprise policy.

* **On Non-Nix Distros:** Place `policies.json` in `/etc/firefox/policies/policies.json` (or `<firefox-install-dir>/distribution/policies.json`).
* **On NixOS (without `programs.firefox`):** Wrap `pkgs.firefox` in `home.nix` using `extraPolicies` (which generates the exact same `policies.json` inside `/nix/store`):

```nix
# In your shared Home Manager module (e.g., modules/home-common.nix)
{ pkgs, ... }:

{
  home.packages = [
    (pkgs.firefox.override {
      extraPolicies = {
        ExtensionSettings = {
          # uBlock Origin
          "uBlock0@raymondhill.net" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          };
          # Bitwarden
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
            installation_mode = "normal_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          };
        };
      };
    })
  ];
}

```

*(Tip: You can find any installed extension's exact ID in `about:support` under the **Add-ons** table.)*

*Verification:* Launch Firefox and check `about:policies`—both extensions appear as active under `ExtensionSettings` and install automatically on first launch.

---

### Method 3: NixOS-Only Declarative Extensions (`NUR` / `nix-firefox-addons`)

If you ever decide to manage Firefox via Home Manager on your NixOS hosts (`programs.firefox.enable = true`), you can install pre-packaged `.xpi` derivations directly from the Nix store using the **NUR (`rycee.firefox-addons`)** flake input:

```nix
programs.firefox = {
  enable = true;
  profiles.default.extensions.packages = with inputs.nur.legacyPackages.${pkgs.system}.repos.rycee.firefox-addons; [
    ublock-origin
    bitwarden
  ];
};

```

*(Note: Enabling `programs.firefox` has Home Manager manage `profiles.ini` and `user.js` on NixOS, though you can still keep `user.js` settings shared by importing or reading a shared file.)*

---

### What Does *Not* Sync Automatically Between Hosts

* **Extension internal storage / local state:** Some extensions (like Violentmonkey scripts or custom uBlock filter lists) do not sync their internal IndexedDB/storage via Firefox Sync unless the extension itself has its own cloud/WebDAV/Git sync feature enabled.
* **Native messaging host binaries:** Extensions that talk to external OS binaries (e.g., KeePassXC, 1Password, Tridactyl native messenger) still require the companion package to be installed on each host OS (`pkgs.keepassxc` / `programs.firefox.nativeMessagingHosts` on NixOS, or system packages on non-Nix distros).

This error occurs because an active Firefox Enterprise Policy (`ExtensionSettings`) is blocking the installation of `nordpassStandalone@nordsecurity.com`.

Commonly, this happens when a global block rule (`"*"` set to `"blocked"`) is defined in `policies.json` without explicitly whitelisting NordPass, or when a previously configured Nix/Home Manager Firefox policy wrapper is still active.

### 1. Check Active Policies in Firefox

Open a new tab and navigate to **`about:policies`**.

* Look under the **Active** tab for **`ExtensionSettings`**.
* Check if `"*"` has `"installation_mode": "blocked"` or if `nordpassStandalone@nordsecurity.com` is explicitly listed as blocked.
* Click the **Documentation** or **Errors** tabs if anything looks malformed, and check where Firefox is loading its policies from (on NixOS, policies are compiled into `/nix/store/<hash>-firefox-<version>/lib/firefox/distribution/policies.json`).

### 2. Allow or Force-Install NordPass in NixOS / Home Manager

If you are wrapping `pkgs.firefox` with `extraPolicies` (or using `programs.firefox.policies` in Home Manager / NixOS), add `nordpassStandalone@nordsecurity.com` to `ExtensionSettings`:

```nix
(pkgs.firefox.override {
  extraPolicies = {
    ExtensionSettings = {
      # Keep your existing rules (e.g., "*" = { installation_mode = "blocked"; };)
      "nordpassStandalone@nordsecurity.com" = {
        installation_mode = "normal_installed"; # or "force_installed" / "allowed"
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/nordpass-password-manager/latest.xpi";
      };
    };
  };
})

```

* Use `"allowed"` if you only want to unblock manual installation from `addons.mozilla.org` without auto-installing it.
* Use `"normal_installed"` or `"force_installed"` with `install_url` if you want Firefox to install and sync it automatically across hosts.

### 3. Check for Residual System-Wide Policies (Non-Nix / Hybrid Setups)

If `about:policies` shows active policies even though you removed `extraPolicies` from your Nix config:

* Check if `/etc/firefox/policies/policies.json` exists on your system and remove or update it.
* Ensure you aren't launching a different Firefox binary on your `PATH` (run `which firefox` and `readlink -f $(which firefox)` to verify which `/nix/store` derivation is running).
