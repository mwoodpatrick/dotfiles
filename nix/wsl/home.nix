{
  config,
  lib,
  pkgs,
  inputs,
  unstable,
  username,
  ...
}:
let
  home = config.home.homeDirectory;
  projects_root = "/mnt/wsl/projects";
  git_root = "${projects_root}/git";
  xdg_data = "${projects_root}/data";
  xdg_state = "${projects_root}/state";
  browser = "firefox.desktop"; # Or "chromium-browser.desktop", "brave-browser.desktop"
  inherit (lib) mkForce;
in
{
  home = {
    # Optional: Only needed if you install GUI apps in home.packages rather than configuration.nix
    homeDirectory = "/home/${username}";

    sessionVariables = {
      # Ensure Ollama daemon target is consistently set in the shell session
      OLLAMA_HOST = "http://localhost:11434";
      OLLAMA_API_KEY_FILE = "/run/secrets/OLLAMA_API_KEY";
      XDG_DATA_HOME = mkForce "${xdg_data}";
      XDG_STATE_HOME = mkForce "${xdg_state}";
    };
  };

  xdg = {
    enable = true; # Whether to enable management of XDG base directories
    mime.enable = mkForce false; # wants to put file in /home/${user}/.local/share/applications/mimeapps.list
    # standard .desktop files configured to launch background utilities,
    # tray applets, or services automatically when a user logs into a
    # graphical desktop session (such as GNOME, KDE Plasma, or XFCE).
    # TODO disable for now, enabled when we add a graphical-desktop
    autostart = {
      enable = false;
    };
    # Controls where ~/.config files go
    configHome = "${git_root}/dotfiles";
    # Controls where ~/.local/share files (and applications/) go
    dataHome = "${projects_root}/data";

    # desktop-agnostic D-Bus bridge that lets applications—especially sandboxed,
    # wrapped, or containerized software (such as Flatpak, Snap, VS Code inside
    # FHS wrappers, and web browsers)—interact safely with the host
    # desktop environment.
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

    # conflict with nixos/modules/services/misc/graphical-desktop.nix
    mimeApps = {
      enable = false;
      defaultApplications = {
        "text/html" = browser;
        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;
        "x-scheme-handler/about" = browser;
        "x-scheme-handler/unknown" = browser;
      };
    };
  };

  # (Optional) Declare the GTK icon theme if using GTK/GNOME apps
  #  gtk = {
  #    enable = true;
  #    iconTheme = {
  #      name = "Adwaita";
  #      package = pkgs.adwaita-icon-theme;
  #    };
  #  };

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.

  home.stateVersion = "26.05";

  # Installs tools directly inside the user's execution profile path
  home.packages =
    with pkgs;
    lib.unique [
      (firefox.override {
        extraPolicies = {
          # Optional: remove the 3rdparty policy if you don't need native messaging hosts
          "3rdparty" = null;

          ExtensionSettings = {
            # Allow manual installation from addons.mozilla.org (or use "normal_installed" / "force_installed" with install_url to auto-install)
            "nordpassStandalone@nordsecurity.com" = {
              installation_mode = "normal_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/nordpass-password-manager/latest.xpi";
            };
          };
        };
      })
      # [adwaita](https://gnome.pages.gitlab.gnome.org/libadwaita/)
      # Building blocks for modern adaptive GNOME applications.
      adwaita-icon-theme # a modern theme used by many apps
      aider-chat
      atool
      shellcheck # Required backend linter utilized by the Bash LSP
      black # Python formatters & linters
      unstable.bun
      btop
      bubblewrap # Sandboxing toolkit utility used for security boundaries
      chafa
      clang-tools
      unstable.claude-code
      codex
      cowsay
      unstable.elan # Install latest Lean theorem prover.
      fd # Fast user directory scanner dependency
      file # Provides the core `file` utility binary
      fortune
      fzf
      gemini-cli
      git
      gh # GitHub official CLI engine
      ghostty
      # [default-icon-theme](https://www.freedesktop.org/wiki/Software/icon-theme)
      # icon-theme contains the standard also references the default icon theme called hicolor.
      hicolor-icon-theme # contains the fallback “hicolor” icons
      httpie
      htop
      isort # Python formatters & linters
      jq # Essential CLI JSON processor
      kitty
      lua5_1
      luarocks
      lazygit
      lmstudio
      lua-language-server
      lsof
      lswt
      mesa-demos # [Collection of demos and test programs for OpenGL and Mesa](https://github.com/mirror/mesa-demos)
      neovide
      unstable.neovim
      nerdfix
      nodejs_26
      nil # fast, lightweight nix language server
      nixd # nix langiage server with deep-introspection features
      nixfmt
      # inputs.nix-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
      # inputs.nix-ai.packages.${pkgs.stdenv.hostPlatform.system}.default
      ni
      adwaita-icon-theme # a modern theme used by many apps
      aider-chat
      atool
      shellcheck # Required backend linter utilized by the Bash LSP
      black # Python formatters & linters
      btop
      bubblewrap # Sandboxing toolkit utility used for security boundaries
      chafa
      unstable.claude-code
      codex
      cowsay
      unstable.elan # Install latest Lean theorem prover.
      fd # Fast user directory scanner dependency
      fzf
      file # Provides the core `file` utility binary
      fortune
      gemini-cli
      git
      gh # GitHub official CLI engine
      ghostty
      hicolor-icon-theme # contains the fallback “hicolor” icons
      httpie
      htop
      isort # Python formatters & linters
      jq # Essential CLI JSON processor
      kitty
      lua5_1
      luarocks
      lazygit
      lmstudio
      lua-language-server
      lsof
      lswt
      mesa-demos # [Collection of demos and test programs for OpenGL and Mesa](https://github.com/mirror/mesa-demos)
      neovide
      unstable.neovim
      nerdfix
      nodejs_26
      nil # fast, lightweight nix language server
      nixd # nix langiage server with deep-introspection features
      nixfmt
      # inputs.nix-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
      # inputs.nix-ai.packages.${pkgs.stdenv.hostPlatform.system}.default
      ni
      adwaita-icon-theme # a modern theme used by many apps
      aider-chat
      atool
      shellcheck # Required backend linter utilized by the Bash LSP
      black # Python formatters & linters
      btop
      bubblewrap # Sandboxing toolkit utility used for security boundaries
      chafa
      unstable.claude-code
      codex
      cowsay
      unstable.elan # Install latest Lean theorem prover.
      fd # Fast user directory scanner dependency
      fzf
      file # Provides the core `file` utility binary
      fortune
      gemini-cli
      git
      gh # GitHub official CLI engine
      ghostty
      hicolor-icon-theme # contains the fallback “hicolor” icons
      httpie
      htop
      isort # Python formatters & linters
      jq # Essential CLI JSON processor
      kitty
      lua5_1
      luarocks
      lazygit
      lmstudio
      lua-language-server
      lsof
      lswt
      mesa-demos # [Collection of demos and test programs for OpenGL and Mesa](https://github.com/mirror/mesa-demos)
      neovide
      unstable.neovim
      nerdfix
      nodejs_26
      nil # fast, lightweight nix language server
      nixd # nix langiage server with deep-introspection features
      nixfmt
      # inputs.nix-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
      # inputs.nix-ai.packages.${pkgs.stdenv.hostPlatform.system}.default
      ni
      adwaita-icon-theme # a modern theme used by many apps
      aider-chat
      atool
      shellcheck # Required backend linter utilized by the Bash LSP
      black # Python formatters & linters
      btop
      bubblewrap # Sandboxing toolkit utility used for security boundaries
      chafa
      unstable.claude-code
      codex
      cowsay
      unstable.elan # Install latest Lean theorem prover.
      fd # Fast user directory scanner dependency
      fzf
      file # Provides the core `file` utility binary
      fortune
      gedit
      gemini-cli
      git
      gh # GitHub official CLI engine
      ghostty
      hicolor-icon-theme # contains the fallback “hicolor” icons
      httpie
      htop
      isort # Python formatters & linters
      jq # Essential CLI JSON processor
      kitty
      lua5_1
      luarocks
      lazygit
      lmstudio
      lua-language-server
      lsof
      lswt
      mesa-demos # [Collection of demos and test programs for OpenGL and Mesa](https://github.com/mirror/mesa-demos)
      neovide
      unstable.neovim
      nerdfix
      nodejs_26
      nil # fast, lightweight nix language server
      nixd # nix langiage server with deep-introspection features
      nixfmt
      # inputs.nix-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
      # inputs.nix-ai.packages.${pkgs.stdenv.hostPlatform.system}.default
      nix-ld
      nix-index # locate the package providing a certain file in nixpkgs
      obsidian
      unstable.ollama
      ponysay
      python3Packages.openai
      # opencode
      # Local OpenCode build via flake input:
      # OpenCode CLI target
      # inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode
      # inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode-desktop
      # OpenCode Desktop (Electron/GUI) target
      # inputs.opencode.packages.${pkgs.system}.desktop
      # unstable.opencode # Official Nixpkgs unstable derivation
      # (pkgs.opencode.override {
      # npmDepsHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
      # })
      # (pkgs.opencode.overrideAttrs (oldAttrs: {
      # npmDeps = oldAttrs.npmDeps.overrideAttrs (_: {
      # outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
      # });
      # }))
      # (unstable.opencode.overrideAttrs (oldAttrs: {
      # npmDeps = oldAttrs.passthru.npmDeps.overrideAttrs (_: {
      # outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
      # });
      # }))
      # unstable.opencode-desktop
      # opencode-desktop
      pandoc
      patchelf # Small utility to modify the dynamic linker and RPATH of ELF executables.
      pnpm
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
      librsvg # Small library to render SVG images to Cairo surfaces
      resvg # SVG rendering library.
      ripgrep # Optimal regex finder for tools like Telescope/Nvim
      rustup # Includes cargo, rustc, etc.
      shfmt # bash formatter
      slirp4netns # User-space network engine for rootless sandboxes
      sqlite # Provides both the CLI utility and sqlite3 libraries
      stylua
      imagemagick
      tmux
      trash-cli
      tree-sitter
      typescript-language-server
      ueberzugpp
      unstable.warp-terminal
      unzip
      viu
      vscode-langservers-extracted
      unstable.vscodium-fhs
      wayland
      wayland-utils
      waylevel
      wl-clipboard
      wmctrl
      wezterm
      xclock
      xdg-utils
      xdotool
      xlsfonts
      xprop
      xwininfo
      yarn
      yq-go # Provides a reliable YAML processor/parser
      # Migrated from configuration.nix
      # inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      unstable.zed-editor
      tinywl
    ];

  programs.home-manager.enable = true;

  # 3. Automated Git Architecture Configurations
  # Ties directly into your upstream tracking layout definitions
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "${username}";
        email = "${username}@gmail.com";
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
    enable = true;
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
      if [ -f "${config.xdg.configHome}/bash/init.bash" ]; then
        source "${config.xdg.configHome}/bash/init.bash"
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
}
