# Python Development in NixOS
**This is bold**
*This is italic*
See [Development Environments on NixOS](https://nixos-and-flakes.thiscute.world/development/intro)
Using `pip` directly on NixOS often leads to issues because NixOS does not manage Python environments in the standard, mutable way that other Linux distributions do. When `pip` attempts to compile C-based extensions, it typically fails to find system libraries in the standard locations (`/usr/lib`, etc.), resulting in missing dependency errors.

To work with Python on NixOS effectively, you should avoid global `pip` installations and instead use one of the following approaches.

### 1. The Recommended Way: `mkShell` (Development Shells)

The idiomatic way to handle Python dependencies in Nix is to create a localized development shell using `pkgs.mkShell`. This allows you to define a pure, reproducible environment where your dependencies are available to Python.

* **Create a `shell.nix` (or `flake.nix`):** Define the Python interpreter and the required libraries as `buildInputs`.
* **Use `venvShellHook`:** This is a built-in Nix helper that automatically creates and sources a virtual environment (`.venv`) when you enter the shell.

```nix
# Example shell.nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = [
    pkgs.python3
    pkgs.python3Packages.venvShellHook
  ];

  venvDir = ".venv";
}

```

When you run `nix-shell`, it will automatically set up the virtual environment, allowing you to use `pip` inside that folder without hitting system linking issues.

### 2. Alternatives for Better Ergonomics

If writing `shell.nix` files feels like too much friction, several tools integrate Nix with modern Python workflows:

* **[devenv](https://devenv.sh/):** A tool that simplifies creating developer shells and can automatically manage Python environments.
* **[poetry2nix](https://github.com/nix-community/poetry2nix):** If you prefer using Poetry for dependency management, this tool converts Poetry projects into Nix derivations, ensuring high reproducibility.
* **[uv](https://github.com/astral-sh/uv):** Increasingly popular for its speed; you can use it within a Nix shell to manage environments.

### Why `pip` usually fails

When you run `pip install` on NixOS, it expects to find system libraries like `glibc` or `zlib` in locations like `/lib` or `/usr/lib`. Nix, however, stores all dependencies in the `/nix/store` directory with unique hashes. Because the paths are non-standard, Python extensions that need to link against C libraries cannot locate them, causing `file not found` errors.

### Summary of Best Practices

* **Never use `sudo pip install`:** This can lead to system-wide breakage and is not supported by the Nix design philosophy.
* **Prefer Nix Packages:** Whenever possible, install Python libraries via `pkgs.python3Packages.<name>` in your Nix configuration or shell, rather than via `pip`.
* **Use `venv` inside Nix shells:** If you must use `pip`, always do so inside a `nix-shell` or `nix develop` environment that has been configured with the necessary dependencies provided by Nix.

[How to use Python on NixOS](https://www.youtube.com/watch?v=6fftiTJ2vuQ)

This video provides a helpful walkthrough of setting up project-specific development environments on NixOS.
