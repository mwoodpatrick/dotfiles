# Secret Management 

# Mozill SOPS

**Mozilla SOPS** (**S**ecrets **OP**eration**S**) is an open-source editor and command-line tool for managing encrypted files. Originally created by Mozilla (and now maintained by the CNCF community at [getsops/sops](https://github.com/getsops/sops), it solves the problem of safely storing secrets—such as passwords, API keys, TLS certificates, and tokens—directly inside version-controlled Git repositories alongside your infrastructure or application code.

---

### Core Concept: Value-Only Encryption

Unlike tools that encrypt an entire file into an unreadable binary blob, SOPS understands structured formats (**YAML**, **JSON**, **.env**, **INI**, and **binary** files):

* **Keys stay in plaintext:** Structural keys remain readable so `git diff` and pull request reviews clearly show *which* secret changed without exposing the secret itself.


* **Values are encrypted:** Every leaf value is encrypted individually using AES-256-GCM, and SOPS appends a `sops` metadata block at the bottom of the file containing the encrypted data keys and integrity MAC.



```yaml
# Example of a SOPS-encrypted YAML file stored in Git
database:
    host: ENC[AES256_GCM,data:9xK2...,iv:...,tag:...,type:str]
    password: ENC[AES256_GCM,data:7pL9...,iv:...,tag:...,type:str]
sops:
    age:
        - recipient: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
          enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            ...

```

---

### Key Management Backends

SOPS supports encrypting the file's master data key against multiple cryptographic backends simultaneously, making it easy to share secrets across developers, CI pipelines, and servers:

* **age:** Modern, lightweight, zero-configuration public-key encryption (the standard choice in the Nix/NixOS ecosystem via `sops-nix`).


* **PGP / GPG:** Traditional asymmetric keypairs.


* **Cloud KMS:** AWS KMS, GCP Cloud KMS, Azure Key Vault, and HashiCorp Vault Transit.

---

### Configuration via `.sops.yaml`

A `.sops.yaml` configuration file in the root of your repository defines creation rules—mapping file path regexes to the public keys allowed to encrypt/decrypt them:

```yaml
keys:
  - &admin age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  - &server age1yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy

creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
      - age:
          - *admin
          - *server

```

---

### Common CLI Workflow

* **Create or edit an encrypted file** (decrypts into `$EDITOR` in a temporary file, then re-encrypts on save):


```bash
sops secrets/secrets.yaml

```


* **Decrypt to stdout** (useful in scripts or CI):
```bash
sops -d secrets/secrets.yaml

```


* **Extract a single nested value:**
```bash
sops -d --extract '["database"]["password"]' secrets/secrets.yaml

```


* **Re-encrypt files after adding or rotating keys in `.sops.yaml`:**
```bash
sops updatekeys secrets/secrets.yaml

```



---

### Usage with Nix & NixOS (`sops-nix`)

In Nix and NixOS, SOPS is used primarily through **`sops-nix`** (`github:Mic92/sops-nix`). Because anything evaluated by Nix is copied into the world-readable `/nix/store`, putting plaintext secrets in `.nix` files exposes them to all local users. `sops-nix` keeps the encrypted files safe in Git and `/nix/store`, then decrypts them at system activation or login into an in-memory `tmpfs` (`/run/secrets` for NixOS system services, or `$XDG_RUNTIME_DIR/secrets.d` for Home Manager) with strict permissions.

Would you like to dive deeper into standalone SOPS usage (such as CLI workflows, KMS integration, or CI/CD decryption) or a specific `sops-nix` scenario?
# NixOs & sops


Because every file evaluated by Nix is copied into the world-readable `/nix/store`, putting plaintext passwords, API keys, or private certificates directly into your `.nix` configuration exposes them to every user on the system (and commits them to Git).

**`sops-nix`** (built on Mozilla's **SOPS** — *Secrets OPerationS*) solves this by allowing you to store encrypted YAML, JSON, `.env`, or binary files safely in your Nix repository and decrypting them into an in-memory `tmpfs` (`/run/secrets`) at system activation time.

---

### How `sops-nix` Works

1. **Encrypted in Git & `/nix/store`:** You encrypt a file (e.g., `secrets.yaml`) using an **age** or **GPG** public key. Because the ciphertext is safe to read, Nix copies the encrypted file into `/nix/store` during evaluation without leaking secrets.
2. **Decrypted at Activation (`/run/secrets`):** During `nixos-rebuild switch` (or boot), the `sops-nix` activation script uses the machine's private key (such as `/var/lib/sops-nix/key.txt` or a key derived from `/etc/ssh/ssh_host_ed25519_key`) to decrypt the secrets into `/run/secrets/<secret-name>` in RAM with strict file ownership and permissions (`0400`).
3. **Referenced by Path in NixOS:** NixOS modules point to `config.sops.secrets.<name>.path` (which evaluates to `"/run/secrets/<name>"`) rather than embedding secret strings into derivations.

---

### Step-by-Step Setup (Flakes + `age`)

#### 1. Generate Keys and `.sops.yaml`

On the target NixOS host, generate an `age` keypair (or derive one from your existing SSH host key via `ssh-to-age`):

```bash
# Generate a host age key (requires root to write to /var/lib/sops-nix)
sudo mkdir -p /var/lib/sops-nix
nix-shell -p age --run "sudo age-keygen -o /var/lib/sops-nix/key.txt"

# Print the public key (starts with age1...)
sudo age-keygen -y /var/lib/sops-nix/key.txt

```

Create a `.sops.yaml` file in the root of your NixOS repository specifying which public keys can decrypt which files:

```yaml
keys:
  - &admin_user age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  - &host_server age1yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy

creation_rules:
  - path_regex: secrets/secrets\.yaml$
    key_groups:
      - age:
          - *admin_user
          - *host_server

```

*(Tip: Including both your personal admin key and the server's host key ensures you can edit the secrets file from your workstation while the server can decrypt it on boot.)*

#### 2. Create and Encrypt `secrets/secrets.yaml`

Run `sops` to create and edit the encrypted file (don't forget `git add` so Nix Flakes sees the file):

```bash
mkdir -p secrets
nix-shell -p sops --run "sops secrets/secrets.yaml"

```

Inside your editor, write standard YAML key-value pairs:

```yaml
db_password: "super-secret-password"
wifi:
  psk: "my-wifi-passphrase"

```

When you save and exit, `sops` encrypts the values in place while leaving the YAML keys visible for clean Git diffs. Stage the file:

```bash
git add .sops.yaml secrets/secrets.yaml

```

#### 3. Add `sops-nix` to `flake.nix`

Add `github:Mic92/sops-nix` as a flake input and import `sops-nix.nixosModules.sops` into your NixOS configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, sops-nix, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        sops-nix.nixosModules.sops
      ];
    };
  };
}

```

#### 4. Configure and Consume Secrets in `configuration.nix`

Point `sops` to your encrypted file and private key, declare the secrets you want extracted, and reference `.path` in your services:

```nix
{ config, pkgs, ... }:

{
  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      # Extracts to /run/secrets/db_password owned by postgres
      db_password = {
        owner = "postgres";
        group = "postgres";
        mode = "0400";
      };

      # Nested YAML keys use "/"
      "wifi/psk" = {};

      # Secrets needed before user creation (e.g., hashed user passwords)
      user_password = {
        neededForUsers = true;
      };
    };
  };

  # Example 1: Passing a secret file path to a systemd service
  services.postgresql.authentication = ''
    # ...
  '';
  systemd.services.my-app.serviceConfig.EnvironmentFile = config.sops.secrets.db_password.path;

  # Example 2: Declarative user password
  users.mutableUsers = false;
  users.users.alice = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.user_password.path;
  };
}

```

---

### Advanced Features

* **Secret Templates (`sops.templates`):** If a service requires a configuration file containing a secret embedded alongside non-secret settings (such as a `.env` file or TOML config), `sops-nix` can render the template at activation time:
```nix
sops.templates."app.env" = {
  owner = "my-app";
  content = ''
    DATABASE_URL=postgres://user:${config.sops.placeholder.db_password}@localhost/mydb
  '';
};
# Reference via: config.sops.templates."app.env".path

```


* **Home Manager Integration:** Importing `sops-nix.homeManagerModules.sops` decrypts user-level secrets via a `systemd --user` service into `$XDG_RUNTIME_DIR/secrets.d` (symlinked at `~/.config/sops-nix/secrets`).
* **SSH Host Key Reuse:** Instead of maintaining a separate `age` key file, you can set `sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];` and derive the corresponding `age1...` public key for `.sops.yaml` using `nix-shell -p ssh-to-age --run "ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub"`.

Are you setting up `sops-nix` for system-level NixOS services, Home Manager user secrets, or both?

Using **`sops-nix`** for both NixOS system services and Home Manager user environments is best structured with **two separate encrypted files** (one for root-owned system secrets, one for user-owned secrets) and **two decryption keys** (a machine host key for boot/system activation, and your user `age` key for Home Manager activation).

---

### 1. Directory Structure & Keys Setup

Organize your flake repository to cleanly separate system and user secrets:

```text
nixos-config/
├── .sops.yaml
├── flake.nix
├── configuration.nix          # NixOS system config
├── home.nix                   # Home Manager config
└── secrets/
    ├── system.yaml            # Encrypted with host_key + user_key
    └── user.yaml              # Encrypted with user_key (and optionally host_key)

```

#### Generate Keys

1. **User `age` key** (stored in `~/.config/sops/age/keys.txt`, used both to edit secrets from your workstation and by Home Manager at login/activation):
```bash
mkdir -p ~/.config/sops/age
nix-shell -p age --run "age-keygen -o ~/.config/sops/age/keys.txt"
# Print public key:
nix-shell -p age --run "age-keygen -y ~/.config/sops/age/keys.txt"

```


2. **System host `age` key** (stored in `/var/lib/sops-nix/key.txt` for root-level decryption during `nixos-rebuild` and boot):
```bash
sudo mkdir -p /var/lib/sops-nix
nix-shell -p age --run "sudo age-keygen -o /var/lib/sops-nix/key.txt"
# Print public key:
sudo nix-shell -p age --run "age-keygen -y /var/lib/sops-nix/key.txt"

```



#### Configure `.sops.yaml`

```yaml
keys:
  - &user_mwoodpatrick age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  - &host_nixos age1yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy

creation_rules:
  - path_regex: secrets/system\.yaml$
    key_groups:
      - age:
          - *user_mwoodpatrick
          - *host_nixos

  - path_regex: secrets/user\.yaml$
    key_groups:
      - age:
          - *user_mwoodpatrick

```

Create and stage both files:

```bash
mkdir -p secrets
nix-shell -p sops --run "sops secrets/system.yaml"
nix-shell -p sops --run "sops secrets/user.yaml"
git add .sops.yaml secrets/system.yaml secrets/user.yaml

```

---

### 2. `flake.nix` Wiring (NixOS + Home Manager)

Import both `sops-nix.nixosModules.sops` (in your NixOS system modules) and `sops-nix.homeManagerModules.sops` (in your Home Manager `sharedModules`):

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, ... }:
    let
      system = "x86_64-linux";
      username = "mwoodpatrick";
    in {
      nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit username; };
        modules = [
          ./configuration.nix
          sops-nix.nixosModules.sops

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit username; };
              sharedModules = [
                sops-nix.homeManagerModules.sops
              ];
              users.${username} = import ./home.nix;
            };
          }
        ];
      };
    };
}

```

*(Note: If you use standalone `homeManagerConfiguration` instead of the NixOS module, add `sops-nix.homeManagerModules.sops` directly to the `modules` list inside `home-manager.lib.homeManagerConfiguration`.)*

---

### 3. System Secrets in `configuration.nix`

System secrets decrypt to `/run/secrets/<name>` and are owned by `root` (or the specified service user):

```nix
{ config, pkgs, username, ... }:

{
  sops = {
    defaultSopsFile = ./secrets/system.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      # Needed before users are created during activation
      user_password.neededForUsers = true;

      # Owned by a specific system daemon
      postgres_password = {
        owner = "postgres";
        group = "postgres";
        mode = "0400";
      };
    };
  };

  users.mutableUsers = false;
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPasswordFile = config.sops.secrets.user_password.path;
  };
}

```

---

### 4. User Secrets in `home.nix`

Home Manager runs a `systemd --user` unit (`sops-nix.service`) that decrypts `secrets/user.yaml` into `$XDG_RUNTIME_DIR/secrets.d/` (symlinked at `~/.config/sops-nix/secrets/<name>`):

```nix
{ config, pkgs, username, ... }:

{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.05";

  sops = {
    defaultSopsFile = ./secrets/user.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    secrets = {
      github_token = {};

      # Example: place a decrypted SSH private key directly at ~/.ssh/id_ed25519
      ssh_private_key = {
        path = "${config.home.homeDirectory}/.ssh/id_ed25519";
        mode = "0600";
      };
    };

    # Example: render a config file or shell env file with embedded secrets
    templates."api-keys.env".content = ''
      export GITHUB_TOKEN="${config.sops.placeholder.github_token}"
    '';
  };

  # Source rendered user secrets in your shell
  programs.bash.initExtra = ''
    if [ -f "${config.sops.templates."api-keys.env".path}" ]; then
      source "${config.sops.templates."api-keys.env".path}"
    fi
  '';
}

```

---

### Key Differences Between System and User `sops-nix`

| Feature | NixOS (`nixosModules.sops`) | Home Manager (`homeManagerModules.sops`) |
| --- | --- | --- |
| **Default Output Path** | `/run/secrets/<name>` | `$XDG_RUNTIME_DIR/secrets.d/...` (`~/.config/sops-nix/secrets/<name>`) |
| **Activation Mechanism** | NixOS system activation script (runs as `root` at boot/switch) | `systemd --user` service (`systemctl --user status sops-nix`) |
| **Ownership Options** | Supports `owner` and `group` | Always owned by your user (only `mode` and `path` apply) |
| **Typical Use Cases** | User login passwords (`neededForUsers`), Wi-Fi PSKs, VPN/WireGuard keys, DB/service credentials | Git/API tokens, personal SSH/GPG keys, rclone/restic credentials, `.env` templates |

Would you like examples for specific secrets (such as SSH keys, Wi-Fi/NetworkManager credentials, or a multi-host setup)?


Practical patterns for **SSH keys**, **Wi-Fi / NetworkManager credentials**, and **multi-host setups** using `sops-nix` across NixOS and Home Manager:

---

### 1. SSH Keys (User & Host)

#### A. User SSH Private Keys (via Home Manager)

Store your private key as a multiline YAML block string (`|`) in `secrets/user.yaml`:

```yaml
ssh:
  github_ed25519: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
    ...
    -----END OPENSSH PRIVATE KEY-----

```

In `home.nix`, extract it directly into `~/.ssh/` with `0600` permissions (which OpenSSH strictly requires):

```nix
{ config, ... }:

{
  sops.secrets."ssh/github_ed25519" = {
    path = "${config.home.homeDirectory}/.ssh/id_github_ed25519";
    mode = "0600";
  };

  programs.ssh = {
    enable = true;
    matchBlocks."github.com" = {
      hostname = "github.com";
      user = "git";
      identityFile = config.sops.secrets."ssh/github_ed25519".path;
      identitiesOnly = true;
    };
  };
}

```

*(Tip: Keep the corresponding `.pub` public key in plain text in your Git repo—e.g., `files/id_github_ed25519.pub`—so tools like `ssh-agent` or `ssh-copy-id` can read the public half without decrypting.)*

#### B. System SSH Host Keys (for Ephemeral / Impermanence Setups)

If you redeploy hosts or wipe `/` on boot, store the host's `/etc/ssh/ssh_host_ed25519_key` in `secrets/system.yaml` so the machine keeps a stable SSH fingerprint across rebuilds:

```nix
# configuration.nix
sops.secrets."ssh_host_ed25519_key" = {
  path = "/etc/ssh/ssh_host_ed25519_key";
  owner = "root";
  group = "root";
  mode = "0600";
};

```

---

### 2. Wi-Fi & NetworkManager Credentials (NixOS System)

NetworkManager expects `.env`-style `KEY=VALUE` files when using `networking.networkmanager.ensureProfiles.environmentFiles` (the declarative way to inject Wi-Fi passwords without hardcoding them).

1. **In `secrets/system.yaml`:**
```yaml
wifi:
  home_psk: "super-secret-home-wifi"
  office_psk: "super-secret-office-wifi"

```


2. **In `configuration.nix`:** Use `sops.templates` to render an environment file containing the variables referenced in `ensureProfiles`:
```nix
{ config, ... }:

{
  sops.secrets."wifi/home_psk" = {};
  sops.secrets."wifi/office_psk" = {};

  sops.templates."nm-wifi.env".content = ''
    HOME_WIFI_PSK=${config.sops.placeholder."wifi/home_psk"}
    OFFICE_WIFI_PSK=${config.sops.placeholder."wifi/office_psk"}
  '';

  networking.networkmanager = {
    enable = true;
    ensureProfiles = {
      environmentFiles = [
        config.sops.templates."nm-wifi.env".path
      ];
      profiles = {
        HomeWiFi = {
          connection = {
            id = "HomeWiFi";
            type = "wifi";
            autoconnect = true;
          };
          wifi = {
            ssid = "MyHomeSSID";
            mode = "infrastructure";
          };
          wifi-security = {
            key-mgmt = "wpa-psk";
            psk = "$HOME_WIFI_PSK";
          };
        };
      };
    };
  };
}

```


*(If you use `networking.wireless` / `wpa_supplicant` instead of NetworkManager, pass `secretsFile = config.sops.templates."wireless.env".path;` and reference `@HOME_WIFI_PSK@` inside `networking.wireless.networks."MyHomeSSID".pskRaw` or `psk`.)*

---

### 3. Multi-Host Setup (Per-Host + Shared Secrets)

When managing multiple machines (e.g., `laptop` and `homelab`), split secrets so each host only has the decryption key for its own secrets plus any shared cluster/network secrets.

#### Directory Layout

```text
nixos-config/
├── .sops.yaml
├── flake.nix
├── hosts/
│   ├── laptop/default.nix
│   └── homelab/default.nix
└── secrets/
    ├── shared.yaml            # Encrypted for admin + ALL hosts
    ├── laptop.yaml            # Encrypted for admin + laptop ONLY
    ├── homelab.yaml           # Encrypted for admin + homelab ONLY
    └── user.yaml              # Encrypted for admin (+ user keys on hosts)

```

#### `.sops.yaml` with Anchors & Key Groups

```yaml
keys:
  - &admin_user age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  - &host_laptop age1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  - &host_homelab age1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb

creation_rules:
  - path_regex: secrets/shared\.yaml$
    key_groups:
      - age:
          - *admin_user
          - *host_laptop
          - *host_homelab

  - path_regex: secrets/laptop\.yaml$
    key_groups:
      - age:
          - *admin_user
          - *host_laptop

  - path_regex: secrets/homelab\.yaml$
    key_groups:
      - age:
          - *admin_user
          - *host_homelab

  - path_regex: secrets/user\.yaml$
    key_groups:
      - age:
          - *admin_user

```

#### Referencing Both Per-Host and Shared Files in NixOS

In each host's NixOS config, set `defaultSopsFile` to the host-specific file and override `sopsFile` on any secret pulled from `shared.yaml`:

```nix
# hosts/homelab/default.nix
{ config, ... }:

{
  sops = {
    defaultSopsFile = ../../secrets/homelab.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      # Reads from defaultSopsFile (secrets/homelab.yaml)
      postgres_password = {
        owner = "postgres";
      };

      # Overrides sopsFile to read from secrets/shared.yaml
      tailscale_auth_key = {
        sopsFile = ../../secrets/shared.yaml;
      };
    };
  };

  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets.tailscale_auth_key.path;
  };
}

```

#### Rotating / Adding a New Host Key Later

When you add a new machine's public key to `.sops.yaml`, re-encrypt existing secret files in place so the new host can decrypt them:

```bash
nix-shell -p sops --run "sops updatekeys secrets/shared.yaml"

```

# Files

`SOPS_AGE_KEY_FILE` is not created automatically by `sops` itself—it is an **environment variable** that you (or a module like `sops-nix`) set to tell `sops` where to find your `age` private key file.

How the **underlying key file** is created and how the variable gets set depends on whether you are creating a personal/admin key on the CLI or letting `sops-nix` generate a machine key on NixOS:

---

### 1. Creating the Key File Manually (For Your User / Admin Key)

If you are generating a personal `age` key pair to encrypt and edit secrets from your shell:

1. **Generate the private key file using `age-keygen`:**
By default, `sops` looks for `~/.config/sops/age/keys.txt` on Linux (or `~/Library/Application Support/sops/age/keys.txt` on macOS) even without `SOPS_AGE_KEY_FILE` set, so creating it at that standard path is the cleanest approach:
```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

```


*This writes a file containing a comment with your public key (`# public key: age1...`) and your private key (`AGE-SECRET-KEY-1...`).*
2. **Alternatively, convert an existing SSH ed25519 key to an age key:**
```bash
mkdir -p ~/.config/sops/age
ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

```


3. **Set `SOPS_AGE_KEY_FILE` (only needed if you store the file in a non-default location):**
If you put the key somewhere else (e.g., `/mnt/secure/age-key.txt` or a project directory), export the variable in your shell config (`~/.bashrc`, `~/.zshrc`, or `.envrc`):
```bash
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

```



---

### 2. Automatic Creation in NixOS (`sops-nix`)

In a NixOS setup using `sops-nix`, the key file is created automatically during system activation (`setupSecrets`) when you configure `sops.age` in your NixOS configuration:

* **Auto-generating a standalone machine age key:**
```nix
sops.age.keyFile = "/var/lib/sops-nix/key.txt";
sops.age.generateKey = true;

```


During `nixos-rebuild switch`, `sops-install-secrets` checks if `/var/lib/sops-nix/key.txt` exists. If it does not, it generates a new private key there (`0600`, owned by `root:root`) and prints its `age1...` public key to the console.


* **Deriving from an existing SSH host key:**
```nix
sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

```


Instead of creating a separate file, `sops-nix` converts the host's SSH ed25519 key into an age key in memory during activation.
* **Setting `SOPS_AGE_KEY_FILE` for your interactive shell via NixOS / Home Manager:**
If you want `SOPS_AGE_KEY_FILE` populated in your user session automatically so `sops secrets.yaml` works without passing flags:
```nix
environment.sessionVariables = {
  SOPS_AGE_KEY_FILE = "/home/<your-user>/.config/sops/age/keys.txt";
};

```


*(Or in Home Manager via `home.sessionVariables.SOPS_AGE_KEY_FILE = "${config.xdg.configHome}/sops/age/keys.txt";`.)*
.sops.yaml Configuration
1
2
The .sops.yaml file is the configuration file for SOPS, allowing you to define encryption rules, key management settings, and file handling behaviors. It enables automatic selection of encryption keys and methods based on file patterns, so you don’t need to pass encryption parameters every time.

Core Structure A .sops.yaml file supports three main top-level keys:

creation_rules – Defines how new files are encrypted.

destination_rules – Specifies publishing destinations (e.g., S3, Vault).

stores – Configures formatting options for YAML, JSON, ENV, INI, etc.

Example Configuration

creation_rules:
# Match *.dev.yaml files and encrypt with AWS KMS + PGP + age
- path_regex: \.dev\.yaml$
kms: arn:aws:kms:us-west-2:111111111111:key/abc123
pgp: FBC7B9E2A4F9289AC0C1D4843D16CEE4A27381B4
age: age1s3cqcks5genc6ru8chl0hkkd04zmxvczsvdxq99ekffe4gmvjpzsedk23c

# Match *.prod.yaml files and encrypt with different keys
- path_regex: \.prod\.yaml$
kms: arn:aws:kms:us-west-2:222222222222:key/xyz789
pgp: FBC7B9E2A4F9289AC0C1D4843D16CEE4A27381B4
hc_vault_transit_uri: http://localhost:8200/v1/sops/keys/prodkey

# Default rule for all other files
- pgp: FBC7B9E2A4F9289AC0C1D4843D16CEE4A27381B4

stores:
yaml:
indent: 2
json:
indent: 2
Copy
Key Features

Pattern Matching: path_regex matches file paths to apply specific encryption rules.

Multiple Key Types: Supports AWS KMS, GCP KMS, Azure Key Vault, PGP, age, and HashiCorp Vault.

Key Groups: Require multiple master keys to decrypt using Shamir’s Secret Sharing (key_groups + shamir_threshold).

Selective Encryption: Control which values are encrypted using unencrypted_suffix, encrypted_regex, etc.

Formatting Control: stores lets you set indentation for YAML/JSON output.

Usage Tip Place .sops.yaml at the root of your repo. When you run:

sops edit secrets/dev-config.yaml
Copy
SOPS will automatically pick the right keys based on the matching rule, encrypt only the values (keeping keys visible), and store encryption metadata in the file.

This configuration is essential for consistent, automated, and secure secret management across environments without repetitive CLI flags.

Learn more:
1 -
github.com
2 -
blog.gitguardian.com

https://github.com/getsops/sops
https://blog.gitguardian.com/a-comprehensive-guide-to-sops/
