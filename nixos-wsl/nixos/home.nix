{
  config,
  pkgs,
  inputs,
  ...
}:
let
  browser = "firefox.desktop"; # Or "chromium-browser.desktop", "brave-browser.desktop"

  # Create an 'unstable' package set from the input
  unstable = import inputs.nixpkgs-unstable {
    system = "x86_64-linux"; # Ensure this matches your system architecture
    config.allowUnfree = true;
  };
in
{
  # 1. Core Home Manager State Setup
  # Replace with your actual user environment details
  home.username = "mwoodpatrick";
  home.homeDirectory = "/home/mwoodpatrick";

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = browser;
      "x-scheme-handler/http" = browser;
      "x-scheme-handler/https" = browser;
      "x-scheme-handler/about" = browser;
      "x-scheme-handler/unknown" = browser;
    };
  };

  # This value determines the Home Manager release that your configuration is
  # compatible with. Must map to your stable system state variant.
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.

  home.stateVersion = "26.05";

  # Installs tools directly inside the user's execution profile path
  home.packages = with pkgs; [
    pkgs.aider-chat
    atool
    shellcheck # Required backend linter utilized by the Bash LSP
    black # Python formatters & linters
    bubblewrap # Sandboxing toolkit utility used for security boundaries
    chafa
    codex
    fd # Fast user directory scanner dependency
    file # Provides the core `file` utility binary
    fortune
    gemini-cli
    git
    gh # GitHub official CLI engine
    ghostty
    httpie
    htop
    isort # Python formatters & linters
    jq # Essential CLI JSON processor
    kitty
    lazygit
    lmstudio
    lua-language-server
    lsof
    nil # fast, lightweight nix language server
    nixd # nix langiage server with deep-introspection features
    nixfmt
    obsidian
    prettier # Web/JavaScript formatters
    prettierd
    (python314.withPackages (ps: [
      ps.firecrawl-py
      ps.matplotlib
      ps.numpy
      ps.ollama
      ps.pandas
      ps.requests
    ]))
    pyright
    ranger
    ripgrep # Optimal regex finder for tools like Telescope/Nvim
    rustup # Includes cargo, rustc, etc.
    shfmt # bash formatter
    slirp4netns # User-space network engine for rootless sandboxes
    sqlite # Provides both the CLI utility and sqlite3 libraries
    stylua
    imagemagick
    unstable.opencode
    tree-sitter
    unstable.warp-terminal
    wayland
    wayland-utils
    wezterm
    viu
    ueberzugpp
    yq-go # Provides a reliable YAML processor/parser
    # Migrated from configuration.nix
    fd
    fzf
    git
    claude-code
    # inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    lua5_1
    luarocks
    nerdfix
    nodejs_26
    openai
    vscode-langservers-extracted
    neovide
    pnpm
    yarn
    ripgrep
    tmux
    unzip
    pkgs-unstable.neovim
    pkgs-unstable.ollama
    trash-cli
    xdg-utils
    inputs.nix-ai.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.nix-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # 3. Automated Git Architecture Configurations
  # Ties directly into your upstream tracking layout definitions
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "mwoodpatrick";
        email = "mwoodpatrick@gmail.com";
      };
      init = {
        defaultBranch = "main";
      };
      push = {
        autoSetupRemote = true;
      };
    };
  };

  programs.starship = {
    enable = false;
    enableBashIntegration = true; # Automatically hooks it into Bash initExtra [2]
  };

  # 4. Interactive Shell Integrations
  # Replaces legacy mutable config lookups with deterministic configurations
  programs.bash = {
    enable = true;
    enableCompletion = true;

    # Extra lines to run during interactive shell sessions
    # This works perfectly here because it's wrapped safely inside user 'eve' [1.2.5]
    initExtra = ''
      # Dynamically search for the file path on your file system
      if [ -f "/mnt/wsl/projects/git/dotfiles/bash/init.bash" ]; then
        source "/mnt/wsl/projects/git/dotfiles/bash/init.bash"
      fi
    '';

    # Controls Bash history configuration
    # historySize = 10000;
    # historyFileSize = 50000;
    # historyControl = [ "ignoredups" "ignorespace" ]; # Don't record duplicate commands or commands starting with a space

    # Useful shell options to enable automatically
    shellOptions = [
      "autocd" # Typing a directory name directly will cd into it
      "cdspell" # Minor typos in directory names will be automatically corrected
      "cmdhist" # Save multi-line commands as a single history entry
    ];

    # Extra lines to run for ALL login shells (both interactive and script sessions)
    profileExtra = ''
      # Environment variables or path scripts
      export PATH="$HOME/.local/bin:$PATH"
    '';
  };

  # [Visual Studio Code](https://nixos.wiki/wiki/Visual_Studio_Code)
  programs.vscode = {
    enable = true;
    package = unstable.vscode;
    # Install the core Neovim extension
    profiles.default.extensions = with pkgs.vscode-extensions; [
      asvetliakov.vscode-neovim
      dracula-theme.theme-dracula
    ];
    # Force VS Code to recognize your Nix-managed Neovim
    profiles.default.userSettings = {
      # Use the absolute path provided by the Nix profile
      "vscode-neovim.neovimExecutablePaths.linux" = "${unstable.neovim}/bin/nvim";

      # Optional: Disable default VS Code keybindings that conflict with Neovim
      "vim.useCtrlKeys" = true;
      "vim.hlsearch" = true;
    };
  };

  programs.firefox = {
    enable = true;

    # Global enterprise-level policies
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DontCheckDefaultBrowser = true;
      OfferToSaveLogins = false; # If using an external password manager
    };

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      # Declarative extension management
      extensions.packages = with pkgs.nubank.vscode-extensions; [
        # or pkgs.nur.repos.rycee.firefox-addons
        # pkgs.firefox-addons.ublock-origin
        # pkgs.firefox-addons.bitwarden
      ];

      # Native firefox user preferences (about:config)
      settings = {
        "browser.startup.page" = 3; # Resume previous session
        "privacy.trackingprotection.enabled" = true;
        "signon.rememberSignons" = false;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true; # For custom userChrome.css
      };
    };
  };

  # Let Home Manager install and manage itself declaratively
  # This option installs the home-manager CLI tool matching your configuration
  programs.home-manager.enable = true;
}
