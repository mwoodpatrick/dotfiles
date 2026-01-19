# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository containing configuration files for Bash, Vim/GVim, GDB, and Neovim (Kickstart). The configuration is designed for Linux development environments, particularly for systems where standard package managers may provide outdated software versions.

## Architecture

### Core Structure

The repository is organized into tool-specific directories:

- `bash/` - Bash configuration with modular sourcing pattern
- `gvim/` - Vim/GVim configuration
- `gdb/` - GDB debugger configuration
- `kickstart/` - Neovim Kickstart configuration (fork/customization)

### Bash Configuration System

The Bash configuration uses a modular loading system centered around `bash/init.bash`:

1. **Main Entry Point**: `bash/init.bash` is the central initialization file
   - Sets `$DOTFILES` environment variable pointing to repository root
   - Sources modular configuration files (aliases.bash, ssh.bash, apt.bash)
   - Configures shell behavior (history, prompt, completion)
   - Sets up PATH_BASE and LD_LIBRARY_PATH_BASE for environment preservation

2. **Module Files**:
   - `aliases.bash` - Command aliases and shell functions (Perforce, git, LSF/batch systems)
   - `ssh.bash` - SSH agent management and key handling
   - `apt.bash` - Package installation functions for setting up development environments
   - `.bashrc` - Standard bashrc that sources custom environment via `$HOME/bin/env`

3. **Environment Variables**:
   - `DOTFILES` - Points to repository root (auto-detected from BASH_SOURCE)
   - `PATH_BASE` / `LD_LIBRARY_PATH_BASE` - Preserve base environment paths
   - Custom paths prepend tools from `/home/utils/` for newer versions

### Neovim Configuration (Kickstart)

Located in `kickstart/`, this is a customized Kickstart.nvim setup:

- **Single-file configuration**: `kickstart/init.lua` (monolithic by design)
- **Plugin manager**: Uses lazy.nvim
- **LSP Setup**: Configured for clangd (non-Mason), pyright, lua_ls, bashls, taplo, jsonls
- **Notable customizations**:
  - Avante.nvim integration for AI-assisted coding (Claude provider)
  - Custom clipboard configuration for X11 systems
  - Diagnostics with virtual lines for multi-line error messages
  - Custom tab/indent settings (2 spaces)
  - Column 80 highlighting

### Installation Pattern

The repository expects to be used via symlinks from home directory:
```bash
~/.vimrc -> ~/dotfiles/gvim/.vimrc
~/.gdbinit -> ~/dotfiles/gdb/gdbinit
```

Bash configuration is sourced from shell initialization files by sourcing `$DOTFILES/bash/init.bash`.

## Common Development Tasks

### Setting up Neovim

The `bash/.bashrc` includes a `setup_nvim` function that creates symlinks in `~/bin` for:
- git (version 2.45.2+)
- fzf (version 0.58.0+)
- ripgrep (rg)
- fd-find (fd)
- xclip
- gcc (linked as `cc` for treesitter compilation)

All tools are sourced from `/home/utils/` with specific versions to bypass outdated system packages.

### Package Installation

The `bash/apt.bash` file contains functions for installing development tools:
- `apt-install-neovim` - Full Neovim build from source with dependencies
- `apt-install-docker` - Docker CE installation
- `apt-install-git` - Git with gh CLI and git-filter-repo
- `apt-install-build-tools` - Core compilation tools (cmake, meson, ninja)
- `apt-install-rust` - Rust toolchain via rustup
- `apt-install-go` - Go language installation
- `apt-install` - Complete development environment setup

### SSH Agent Management

SSH agent initialization is automatic via `ssh.bash`:
- `ssh-agent-check` - Verifies/starts SSH agent (auto-runs on bash init)
- `ssh-agent-check_and_add_identity` - Loads first available key (id_ed25519 or id_rsa)
- `ssh-generate-key` - Creates new ed25519 key using git config email

## Environment Specifics

### Target Systems

This configuration is designed for:
- Linux workstations (verified on systems with `/home/utils/` structure)
- WSL2 environments (functions reference `/mnt/wsl/projects/`)
- X11-based systems (clipboard, xterm, VNC configurations)

### Tool Versioning Strategy

The configuration uses tools from `/home/utils/` with explicit versions rather than system packages:
- Allows using newer versions than distribution repositories provide
- Tools are prepended to PATH (in ssh.bash, init.bash)
- Examples: openssh-8.1p1, sshpass-1.06, gcc-13.2.0, git-2.45.2

### Neovim Launch Aliases

Multiple Neovim configurations can coexist using `NVIM_APPNAME`:
- `ks` - Launch Kickstart config (NVIM_APPNAME=kickstart)
- `nx` - Launch in xterm with default config
- `nx2` - Launch with NVIM_APPNAME=nvim-config

## Working with This Repository

### Modifying Bash Configuration

When adding new shell functions or aliases:
1. Add to appropriate module file (aliases.bash, ssh.bash, or apt.bash)
2. Use the modular loading pattern - don't inline everything in init.bash
3. Test by sourcing: `source $DOTFILES/bash/init.bash`

### Modifying Neovim Configuration

The Kickstart config is intentionally a single file (`kickstart/init.lua`):
- Read comments in init.lua for understanding plugin configuration
- LSP servers are split into `mason` and `non_mason` tables
- Custom keymaps are documented inline
- Use `:checkhealth` to verify configuration

### Git Configuration

Git configuration is handled via functions in `ssh.bash`:
- `git-config-init` - Sets user.email, user.name, credential helper
- `git-config-list` - Display current git configuration
