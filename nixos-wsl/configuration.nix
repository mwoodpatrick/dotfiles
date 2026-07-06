# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, ... }:

{
  imports = [
    # include NixOS-WSL modules
    <nixos-wsl/modules>
    <home-manager/nixos>
  ];

  # Core architecture switches mapping the guest VM parameters
  wsl.enable = true;
  wsl.defaultUser = "mwoodpatrick";

  # Essential build tools and utilities required by modern Neovim plugins
  # (e.g., Mason compilation, Treesitter parsers, and Telescope searching)
  environment.systemPackages = with pkgs; [
    fd
    gcc
    git
    gnumake
    lua-language-server
    lua5_1
    luarocks
    ripgrep
    unzip
    wget
  ];

  # Centralized tool management frameworks
  programs = {
    neovim = {
      enable = true;
      defaultEditor = true; # Automatically assigns $EDITOR and $VISUAL to nvim
      viAlias = true;       # Maps 'vi' command to nvim
      vimAlias = true;      # Maps 'vim' command to nvim
    };

  };

  # Enable NIX-LD to allow unpatched dynamic binaries (like Mason LSPs)
  # to locate their runtime interpreters automatically within the Nix store
  programs.nix-ld.enable = true;

  # Enable the foundational D-Bus system services
  services.dbus.enable = true;

  # Force systemd to instantiate user-space session buses automatically
  systemd.user.extraConfig = ''
     DefaultEnvironment="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
   '';

  # Inform your global login shells where to locate the user socket channel
  environment.sessionVariables = {
    DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
  };

  # Workaround for NixOS 26.05 activation bug under headless WSL states
  # Bypasses the broken user-space systemd reload loop during nixos-rebuild switch
  system.activationScripts.userUnits = "";

  # Enable declarative Nix experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users.mwoodpatrick.isNormalUser = true;

  home-manager.startAsUserService = true;
  home-manager.users.mwoodpatrick = { pkgs, ... }: {

    # Packages that should be installed to the user profile.
    home.packages = [ pkgs.atool 
								      pkgs.httpie 
											pkgs.htop
                      pkgs.fortune
		    ];
    programs = {
      # Simply add this alongside your programs.bash block
      starship = {
        enable = false;
        enableBashIntegration = true; # Automatically hooks it into Bash initExtra [2]
      };
  
      bash = {
        enable = true;
  
        # Extra lines to run during interactive shell sessions
        # This works perfectly here because it's wrapped safely inside user 'eve' [1.2.5]
        initExtra = ''
          export EDITOR="nvim"
	  export GIT_ROOT=/mnt/wsl/projects/git
          source $GIT_ROOT/dotfiles/bash/init.bash
        '';
  
        # Shell aliases that get injected directly into your profile
        shellAliases = {
          ll = "ls -l";
          la = "ls -la";
          g = "git";
          v = "nvim";
          ".." = "cd ..";
  	  "nb" = "sudo nixos-rebuild boot";
  	  "ne" = "sudo nixos-rebuild edit";
    	  "ns" = "sudo nixos-rebuild switch";
        };
  
        # Controls Bash history configuration
        # historySize = 10000;
        # historyFileSize = 50000;
        # historyControl = [ "ignoredups" "ignorespace" ]; # Don't record duplicate commands or commands starting with a space
    
        # Useful shell options to enable automatically
        shellOptions = [
          "autocd"   # Typing a directory name directly will cd into it
          "cdspell"  # Minor typos in directory names will be automatically corrected
          "cmdhist"  # Save multi-line commands as a single history entry
        ];
      
      
        # Extra lines to run for ALL login shells (both interactive and script sessions)
        profileExtra = ''
          # Environment variables or path scripts
          export PATH="$HOME/.local/bin:$PATH"
        '';
      };
    };

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    home.stateVersion = "26.05"; # Please read the comment before changing.
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}

