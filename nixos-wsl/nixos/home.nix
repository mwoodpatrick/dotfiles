{
  config,
  lib,
  pkgs,
  inputs,
  unstable,
  ...
}:
let
  home = config.home.homeDirectory;
  projects_root = "/mnt/wsl/projects";
  git_root = "${projects_root}/git";
  xdg_data = "${projects_root}/data";
  browser = "firefox.desktop"; # Or "chromium-browser.desktop", "brave-browser.desktop"
  inherit (lib) mkForce;
in
{
  home = {
    username = "mwoodpatrick";
    homeDirectory = "/home/mwoodpatrick";

    sessionVariables = {
      # Ensure Ollama daemon target is consistently set in the shell session
      OLLAMA_HOST = "http://localhost:11434";
      OLLAMA_API_KEY_FILE = "/run/secrets/OLLAMA_API_KEY";
      XDG_DATA_HOME = mkForce "${xdg_data}";
    };
  };

  xdg = {
    enable = true; # Whether to enable management of XDG base directories
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
    mime.enable = mkForce false; # wants to put file in /home/${user}/.local/share/applications/mimeapps.list
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
    aider-chat
    atool
    shellcheck # Required backend linter utilized by the Bash LSP
    black # Python formatters & linters
    bun
    btop
    bubblewrap # Sandboxing toolkit utility used for security boundaries
    chafa
    unstable.claude-code
    codex
    unstable.elan # Install latest Lean theorem prover.
    fd # Fast user directory scanner dependency
    fzf
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
    lua5_1
    luarocks
    lazygit
    lmstudio
    lua-language-server
    lsof
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
    python3Packages.openai
    # TODO: getting hash mismatch switching to stable branch
    opencode
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
    opencode-desktop
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
    ueberzugpp
    unstable.warp-terminal
    unzip
    viu
    vscode-langservers-extracted
    unstable.vscodium-fhs
    wayland
    wayland-utils
    wl-clipboard
    wezterm
    xdg-utils
    yarn
    yq-go # Provides a reliable YAML processor/parser
    # Migrated from configuration.nix
    # inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    unstable.zed-editor
  ];

  programs.home-manager.enable = true;

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

  # [Firefox](https://wiki.nixos.org/wiki/Firefox)
  programs.firefox = {
    enable = true;
    configPath = "${xdg_data}/mozilla/firefox"; # force profile location
    languagePacks = [ "en-US" ];

    policies = {
      # Updates & Background Services
      AppAutoUpdate = false;
      BackgroundAppUpdate = false;

      # Feature Disabling
      # DisableBuiltinPDFViewer = true;
      # DisableFirefoxStudies = true;
      # DisableFirefoxAccounts = true;
      # DisableFirefoxScreenshots = true;
      # DisableForgetButton = true;
      # DisableMasterPasswordCreation = true;
      # DisableProfileImport = true;
      # DisableProfileRefresh = true;
      # DisableSetDesktopBackground = true;
      # DisablePocket = true;
      DisableTelemetry = true;
      # DisableFormHistory = true;
      # DisablePasswordReveal = true;

      # Access Restrictions
      # BlockAboutConfig = false;
      # BlockAboutProfiles = true;
      # BlockAboutSupport = true;

      # UI and Behavior
      DisplayMenuBar = "never";
      DontCheckDefaultBrowser = true;
      HardwareAcceleration = false;
      # OfferToSaveLogins = false;
      DefaultDownloadDirectory = "${home}/Downloads";

      # Extensions
      ExtensionSettings =
        let
          moz = short: "https://addons.mozilla.org/firefox/downloads/latest/${short}/latest.xpi";
        in
        {
          "*".installation_mode = "blocked";

          "uBlock0@raymondhill.net" = {
            install_url = moz "ublock-origin";
            installation_mode = "force_installed";
            updates_disabled = true;
          };

          "{f3b4b962-34b4-4935-9eee-45b0bce58279}" = {
            install_url = moz "animated-purple-moon-lake";
            installation_mode = "force_installed";
            updates_disabled = true;
          };

          "{73a6fe31-595d-460b-a920-fcc0f8843232}" = {
            install_url = moz "noscript";
            installation_mode = "force_installed";
            updates_disabled = true;
          };

          # NordPass – password manager
          "nordpass@mozilla.org" = {
            install_url = moz "nordpass";
            installation_mode = "force_installed";
            updates_disabled = false;
          };
        };

      # Extension configuration
      "3rdparty".Extensions = {
        "uBlock0@raymondhill.net".adminSettings = {
          userSettings = rec {
            uiTheme = "dark";
            uiAccentCustom = true;
            uiAccentCustom0 = "#8300ff";
            cloudStorageEnabled = mkForce false;

            importedLists = [
              "https://filters.adtidy.org/extension/ublock/filters/3.txt"
              "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
            ];

            externalLists = lib.concatStringsSep "\n" importedLists;
          };

          selectedFilterLists = [
            "CZE-0"
            "adguard-generic"
            "adguard-annoyance"
            "adguard-social"
            "adguard-spyware-url"
            "easylist"
            "easyprivacy"
            "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
            "plowe-0"
            "ublock-abuse"
            "ublock-badware"
            "ublock-filters"
            "ublock-privacy"
            "ublock-quick-fixes"
            "ublock-unbreak"
            "urlhaus-1"
          ];
        };
      };
    };

    # Firefox profile = a complete, isolated user data store for the browser.
    # Profiles let you have separate sets of bookmarks, extensions, preferences, etc.
    profiles = {
      default = {
        id = 0;
        search = {
          force = true;
          default = "ddg";
          privateDefault = "ddg";

          engines = {
            "Nix Packages" = {
              urls = [
                {
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "channel";
                      value = "unstable";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };

            "Nix Options" = {
              urls = [
                {
                  template = "https://search.nixos.org/options";
                  params = [
                    {
                      name = "channel";
                      value = "unstable";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@no" ];
            };

            "NixOS Wiki" = {
              urls = [
                {
                  template = "https://wiki.nixos.org/w/index.php";
                  params = [
                    {
                      name = "search";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@nw" ];
            };
          };
        };
      };
      "work" = {
        id = 1;
        path = "/home/mwoodpatrick/config/.mozilla/firefox/work";
        settings = {
          "privacy.resistFingerprinting" = true;
        };
      };
    };
  };
}
