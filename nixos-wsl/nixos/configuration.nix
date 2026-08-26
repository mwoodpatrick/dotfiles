# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

# access unstable packages via pkgs.pkgs-unstable
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{

  imports = [
    # include NixOS-WSL modules
    # ./hardware-configuration.nix
    # <nixos-wsl/modules>
  ];

  # Core architecture switches mapping the guest VM parameters
  wsl.enable = true;
  wsl.defaultUser = "mwoodpatrick";
  # This tells the NixOS-WSL builder to dynamically generate
  # a valid wsl.conf with interop turned off during system activation
  wsl.interop.includePath = false;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # [nix.gc](https://mynixos.com/nixpkgs/options/nix.gc)
  nix.gc = {
    automatic = true;
    dates = "weekly"; # or "daily"
    options = "--delete-older-than 30d";
    # fred = 23; # enable for flake check
  };

  # Enable the Docker daemon service
  virtualisation.docker = {
    enable = true;
    # Explicitly bind the default bridge to a custom, non-overlapping subnet
    extraOptions = ''
      --bip=192.168.150.1/24
    '';
  };

  xdg = {
    autostart.enable = true;
    portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal
        pkgs.xdg-desktop-portal-gtk
      ];

      config = {
        common = {
          default = [ "gtk" ];
        };
      };
    };
  };

  # [Fonts](https://nixos.wiki/wiki/Fonts)
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts.githubRelease
      nerd-fonts.jetbrains-mono
      dina-font
      # proggyfonts
    ];

    fontconfig = {
      enable = true;

      defaultFonts = {
        serif = [
          "Liberation Serif"
          "Vazirmatn"
        ];
        sansSerif = [
          "Ubuntu"
          "Vazirmatn"
        ];
        monospace = [
          "Ubuntu Mono"
          "JetBrainsMono Nerd Font"
        ];
      };
    };
  };

  # Essential build tools and utilities required by modern Neovim plugins
  # (e.g., Mason compilation, Treesitter parsers, and Telescope searching)
  environment.systemPackages = with pkgs; [
    pciutils
    gcc
    ghostscript
    gnumake
    inputs.hermes-agent.packages.${pkgs.system}.default
    mermaid-cli
    tectonic
    wget
    kmod # Provides lsmod, modprobe, rmmod, etc
    age # Provides age and age-keygen
    ssh-to-age # Convert ssh private keys in ed25519 format to age keys
    sops # Secrets management CLI
    at-spi2-core
    glib # C library of programming buildings blocks
    xdotool # Fake keyboard/mouse input, window management, and more.if using X11 routing fallback
  ];

  # Secrets Management (sops-nix)
  # [Sops-Nix encrypted secrets](https://saylesss88.github.io/installation/enc/sops-nix.html)
  # [Sops-nix options](https://dl.thalheim.io/)
  sops = {
    # Default sops file used for all secrets.
    # This will add secrets.yml to the nix store
    # should be checked into repo
    defaultSopsFile = ./secrets/secrets.yaml;
    # Default sops format used for all secrets
    defaultSopsFormat = "yaml";
    # This will automatically import SSH keys as age keys
    # age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    # This is using an age key that is expected to already be in the filesystem
    # age.keyFile = "/var/lib/sops-nix/key.txt";
    # age.keyFile = "/home/mwoodpatrick/.config/sops/age/keys.txt";
    # Path to age key file used for sops decryptio (should not be checked into repo and be an absolute path)
    age.keyFile = "/mnt/wsl/projects/git/dotfiles/nixos-wsl/nixos/sops/age/keyFile.txt";
    # This will generate a new key if the key specified above does not exist
    age.generateKey = true;

    # Declare every key from your YAML file you want extracted:
    secrets = {
      # This is the actual specification of the secrets.
      OLLAMA_API_KEY = {
        owner = "mwoodpatrick";
        mode = "0400";
        format = "yaml";
      };
      hello = { };
      example_array = {
        owner = "mwoodpatrick";
        mode = "0400";
        format = "yaml";
      };
      example_number = { };
      example_booleans = { };
      # Nested key (extracts 'password' from under 'database'):
      "db-password" = {
        key = "database/password";
      };

      # secrets stored in json file
      "ANTHROPIC_API_KEY" = {
        format = "json";
        sopsFile = ./secrets/secrets.json;
      };

      # Debug me
      # "redis-token" = {
      #   format = "json";
      #   key = "services/redis";
      #   sopsFile = ./secrets/secrets.json;
      # };
    };
  };

  environment.sessionVariables = {
    OLLAMA_API_KEY_FILE = config.sops.secrets.OLLAMA_API_KEY.path;
  };

  # Centralized tool management frameworks
  programs = {
    # source .envrc files
    direnv.enable = true;
    direnv.nix-direnv.enable = true;

    neovim = {
      enable = true;
      defaultEditor = true; # Automatically assigns $EDITOR and $VISUAL to nvim
      viAlias = true; # Maps 'vi' command to nvim
      vimAlias = true; # Maps 'vim' command to nvim
    };

    bash = {
      interactiveShellInit = ''
        if [ -f $GIT_ROOT/dotfiles/bash/init.bash ]; then
          source $GIT_ROOT/dotfiles/bash/init.bash
        fi
      '';
    };
  };

  # Enable NIX-LD to allow unpatched dynamic binaries (like Mason LSPs)
  # to locate their runtime interpreters automatically within the Nix store

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    wayland
    # Add other libraries if Warp throws further "not found" errors
    libxkbcommon
    # Include other GUI-related dependencies if needed
    libx11
    libxcursor
    libxrandr
    libxi
    libGL
  ];

  # Enable the foundational D-Bus system services
  services.dbus.enable = true;
  # services.nonexistentoption.enable = true; # enable for flake check

  # Ensure the systemd user manager is properly configured to linger
  # This allows systemd to manage user services even when you aren't logged in
  systemd.user.services.nix-daemon.wantedBy = [ "multi-user.target" ];

  # Force systemd to instantiate user-space session buses automatically
  systemd.user.extraConfig = ''
    DefaultEnvironment="XDG_RUNTIME_DIR=/run/user/%U"
  '';

  # Workaround for NixOS 26.05 activation bug under headless WSL states
  # Bypasses the broken user-space systemd reload loop during nixos-rebuild switch
  # system.activationScripts.userUnits = "";

  # Make the user-space services significantly more robust against
  # future WSL lifecycle events.
  # Ensure the systemd --user manager starts at boot and persists.
  # When you run nixos-rebuild, the system-level process finds an already-active
  # user manager to talk to.
  # to verify run "systemctl --user status"
  # loginctl show-user mwoodpatrick | grep Linger
  users.users.mwoodpatrick.linger = true;

  # Enable declarative Nix experimental features
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  users.users.mwoodpatrick = {
    isNormalUser = true;
    description = "mwoodpatrick";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
  };

  #  Enable the Unfree licenses required for proprietary GPU acceleration hooks
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
    ];

  # Enable the Ollama Service
  # Enable the background daemon service
  services.ollama = {
    enable = true;

    # use the unstable service version
    package = pkgs.pkgs-unstable.ollama;

    # Pre-seed and pins models to download automatically in the background
    loadModels = [
      "gemma4:12b"
      "deepseek-r1:14b"
    ];

    # Expose the API surface cleanly across internal WSL networking layers if needed
    host = "0.0.0.0";
    port = 11434;
  };

  services.hermes-agent = {
    enable = true;

    # Choose your default model (e.g., routing through local Ollama or OpenRouter)
    settings = {
      model.default = "ollama/gemma4";
      toolsets = [ "all" ];
      terminal = {
        backend = "local";
        timeout = 180;
      };
      # Use the decrypted sops secret for authentication
      env.OLLAMA_API_KEY = "/run/secrets/OLLAMA_API_KEY";
    };

    # Exposes the 'hermes' CLI tool globally in your system PATH
    addToSystemPackages = true;

    # Optional: Enable container mode if the agent needs to run arbitrary package managers
    # container.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
