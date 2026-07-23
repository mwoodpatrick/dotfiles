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

  # Essential build tools and utilities required by modern Neovim plugins
  # (e.g., Mason compilation, Treesitter parsers, and Telescope searching)
  environment.systemPackages = with pkgs; [
    pciutils
    fd
    fzf
    gcc
    ghostscript
    git
    gnumake
    inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    lua-language-server
    lua5_1
    luarocks
    mermaid-cli
    nodejs_26
    neovide
    pnpm
    yarn
    ripgrep
    tmux
    unzip
    tectonic
    wget
    pkgs-unstable.neovim
    pkgs-unstable.ollama
    trash-cli
    xdg-utils
    inputs.nix-ai.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.nix-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
