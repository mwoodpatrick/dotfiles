# Derivations

This document provides a concise overview of Nix derivations, covering how packages are expressed, the generated `.drv` files, the resulting store objects, and the mechanics of `stdenv.mkDerivation`. It also discusses package configuration files (`.pc`), handling many dependencies, multiple outputs, sandboxing, and wrapper programs.

## Table of Contents

- [1. The Package Expression (The Source Recipe)](#1-the-package-expression-the-source-recipe)
- [2. The Derivation File (`.drv`)](#2-the-derivation-file-drv)
- [3. The Store Object (The Built Artifacts)](#3-the-store-object-the-built-artifacts)
- [How are packages defined in Nix](#how-are-packages-defined-in-nix)
- [stdenv.mkDerivation](#stdenvmkderivation)
- [Package Configuration files](#package-configuration-files)
- [Handling many dependencies](#handling-many-dependencies)
- [Is stdenv.mkDerivation limited to c & c++ packages](#is-stdenvmkderivation-limited-to-c--c++-packages)
- [The build sandbox](#the-build-sandbox)
- [Specifying multiple outputs](#specifying-multiple-outputs)
- [Wrapping Programs](#wrapping-programs)
- [Ensuring Reproducibility](#ensuring-reproducibility)

In Nix, a **package** is not a pre-bundled archive like a `.deb` or `.rpm`; rather, it is a reproducible build recipe paired with its resulting immutable directory in the `/nix/store`.

At its lowest level, Nix does not actually have a "package" primitive, it only has **derivations**.
Depending on which stage of the lifecycle you are looking at, a Nix package refers to three connected things:

## 1. The Package Expression (The Source Recipe)

A package starts as a human-readable `.nix` file written in the Nix expression language.

- It is typically structured as a function that accepts an **argument set** (its dependencies, like compilers and libraries) and calls `stdenv.mkDerivation` (a wrapper around the low-level `builtins.derivation` primitive).

- It declares where to fetch the source code (with a cryptographic hash), what dependencies are required at build-time and runtime, and what build steps to run.

## 2. The Derivation File (`.drv`)

When Nix evaluates your `.nix` expression, it translates the high-level code into a serialized, low-level build instruction file stored at `/nix/store/<hash>-<name>.drv`.

- The `<hash>` is a cryptographic hash computed from _every_ input to the build—including the source code, build scripts, compiler versions, environment variables, and target system architecture.

- If any single dependency or build flag changes, the hash changes, creating a completely separate package.

## 3. The Store Object (The Built Artifacts)

When Nix "realises" (builds) the `.drv` file—either by downloading a pre-built copy from a binary cache or compiling it inside an isolated sandbox with no network access—it outputs the final compiled binaries, libraries, and assets into `/nix/store/<hash>-<name>`.

- **Immutable & Isolated:** Once built, this directory is marked read-only. Because every package lives in its own hash-prefixed directory rather than shared global folders like `/usr/bin` or `/usr/lib`, multiple versions of the same package or library can coexist on the same machine without conflict.

- **Self-Contained Dependency Graph:** Compiled binaries inside `/nix/store/<hash>-<name>` are patched to point directly to the exact `/nix/store` paths of the specific libraries they were built against, eliminating "dependency hell."

## How are packages defined in Nix

In Nix, defining and realizing (building) a package is strictly divided into two distinct phases: **Evaluation** (defining the recipe) and **Realisation** (executing the recipe to produce the package).

### 1. Defining a Package (The Expression)

At its lowest level, Nix does not actually have a "package" primitive; it only has **derivations**. A package is defined by writing a Nix expression (in a `.nix` file) that calls `builtins.derivation`.

Because raw `builtins.derivation` requires specifying everything manually (like setting up `PATH`, unpacking tarballs, and running `make`), Nixpkgs provides a wrapper function called **`stdenv.mkDerivation`**.

A typical package definition is structured as a function that takes an **argument set** (its dependencies) and returns a derivation:

```nix
### hello.nix
{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "hello";
  version = "2.12.1";

  # 1. Source: Where to get the code
  src = fetchurl {
    url = "mirror://gnu/hello/${pname}-${version}.tar.gz";
    hash = "sha256-jZkUKv2SV28wsM18tCqNxoCZmLxdYH2Idh9RLgH2yA8=";
  };

  # 2. Dependencies: What is needed to build/run it
  nativeBuildInputs = [ ]; # Build-time tools (e.g., cmake, pkg-config)
  buildInputs = [ ];       # Target libraries (e.g., openssl, zlib)

  # 3. Build Phases: (Handled automatically by stdenv for standard autotools/make,
  #    or customized via configurePhase, buildPhase, installPhase)
  installPhase = ''
    mkdir -p $out/bin
    cp hello $out/bin/
  '';
}

```

#### Dependency Injection (`callPackage`)

The file above only defines a _function_. To turn it into a concrete package definition, Nixpkgs uses **`pkgs.callPackage`**. `callPackage` inspects the function's argument set (`{ lib, stdenv, fetchurl }`) and automatically passes the matching attributes from the massive Nixpkgs repository.

---

### 2. Evaluation Phase (`nix-instantiate`)

When you run a build command (like `nix build` or `nix-build`), Nix first runs the **Evaluation Phase**:

1. **Resolves Nix Code:** Nix evaluates your `.nix` expression, resolves all functions and variables, and fetches/hashes any pure source inputs.

2. **Computes the Store Path:** Nix hashes all inputs (source code, build scripts, compiler versions, environment variables, and target architecture) to calculate a deterministic output path: `/nix/store/<hash>-hello-2.12.1`.

3. **Writes a `.drv` File:** Nix serializes the low-level build instructions into a plain-text **derivation file** (`/nix/store/<hash>-hello-2.12.1.drv`). This file contains the exact `builder` executable (usually `bash`), arguments, input `.drv` dependencies, and environment variables.

---

### 3. Realisation Phase (`nix-store --realise`)

Once the `.drv` file exists, Nix enters the **Realisation Phase** to turn the recipe into actual compiled binaries on disk:

1. **Substituter Check (Binary Cache):** Before compiling anything, Nix checks configured binary caches (like `cache.nixos.org`) to see if `/nix/store/<hash>-hello-2.12.1` has already been built by someone else. If it exists, Nix downloads it and skips the build.
2. **Dependency Realisation:** If no binary cache hit is found, the Nix daemon recursively realises all input `.drv` files (e.g., `gcc`, `bash`, `glibc`) so every dependency exists in `/nix/store`.

3. **Sandboxed Execution:** The Nix daemon creates an isolated build sandbox (no network access, restricted filesystem visibility containing _only_ the declared inputs, and a temporary build directory).

4. **Running the Builder:** Nix invokes the builder specified in the `.drv` file (e.g., `/nix/store/...-bash/bin/bash -e builder.sh`). In `stdenv`, this steps through standard phases (`unpackPhase`, `patchPhase`, `configurePhase`, `buildPhase`, `checkPhase`, `installPhase`, `fixupPhase`).

5. **Producing `$out`:** The build writes its final artifacts into the path assigned to the `$out` environment variable (`/nix/store/<hash>-hello-2.12.1`). Once the builder exits cleanly, Nix marks the store path as valid and read-only.

## stdenv.mkDerivation

**`stdenv.mkDerivation`** is the standard Nixpkgs wrapper function used to build packages and development environments. While Nix only natively understands the low-level `builtins.derivation` primitive, `stdenv.mkDerivation` wraps it to provide a complete Unix build environment—including standard utilities (`coreutils`, `gnugrep`, `gnumake`, `bash`), a C/C++ compiler toolchain, dependency resolution, and a structured multi-phase build lifecycle.

### Basic Structure

A typical package definition passes an attribute set of metadata, source inputs, dependencies, and build instructions to `stdenv.mkDerivation`:

```nix
{ lib, stdenv, fetchurl, pkg-config, zlib }:

stdenv.mkDerivation rec {
  pname = "example";
  version = "1.0.0";

  # 1. Source code
  src = fetchurl {
    url = "https://example.org/${pname}-${version}.tar.gz";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  # 2. Dependencies
  nativeBuildInputs = [ pkg-config ]; # Tools executed on the build machine
  buildInputs = [ zlib ];             # Libraries/headers for the target host

  # 3. Custom build/install overrides (optional for standard Autotools/Make)
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp example $out/bin/
    runHook postInstall
  '';
}

```

---

### Key Concepts

- **Naming (`pname` + `version` vs. `name`):** Passing `pname` and `version` automatically constructs `name = "${pname}-${version}"`, which determines the output `/nix/store/<hash>-<name>` path. For unversioned derivations (such as dev shells or wrapper scripts), you can set `name` directly.

- **Dependency Separation:**
- `nativeBuildInputs`: Build-time tools executed on the build platform (e.g., `cmake`, `pkg-config`, `wayland-scanner`). Their `/bin` directories are added to `PATH`.

- `buildInputs`: Target/host libraries and headers (e.g., `wlroots`, `wayland`, `openssl`). Setup hooks automatically expose their headers, libraries, and `.pc` files via environment variables like `NIX_CFLAGS_COMPILE`, `NIX_LDFLAGS`, and `PKG_CONFIG_PATH`.

- **Standard Build Phases:** `stdenv` executes a default sequence of Bash functions (`unpackPhase`, `patchPhase`, `configurePhase`, `buildPhase`, `checkPhase`, `installPhase`, `fixupPhase`). Standard Autotools/Makefile projects often build without overriding any phases, while custom builds or other languages override specific phases or use language-specific wrappers (such as `buildRustPackage` or `buildGoModule`) built atop `stdenv.mkDerivation`.

- **Variants:**
- `stdenvNoCC.mkDerivation`: Omits the C/C++ compiler toolchain, useful for shell scripts, fonts, or pre-built binaries.

- `pkgs.mkShell`: A thin wrapper around `stdenv.mkDerivation` tailored specifically for interactive `nix develop` / `nix-shell` environments.

**Yes.** Every derivation explicitly specifies the exact `/nix/store` output paths it will produce. In fact, Nix calculates these output paths **before** running the build—during the evaluation phase when it generates the `.drv` file.

Depending on whether you are looking at the high-level `.nix` code or the low-level `.drv` file, outputs are specified in two ways:

### 1. In High-Level Nix Expressions (`.nix`)

- **Single Output (Default):** By default, `builtins.derivation` and `stdenv.mkDerivation` define a single output named `"out"`. During the build, Nix passes the computed `/nix/store/<hash>-<name>` path to the builder via the `$out` environment variable.

- **Multiple Outputs:** You can split a package into multiple distinct store paths (for example, separating headers or documentation so runtime users don't have to download them) by passing the `outputs` attribute as a list of strings:

```nix
stdenv.mkDerivation {
  pname = "example";
  version = "1.0";
  outputs = [ "out" "dev" "doc" ];
  # ...
}

```

Each entry in that list becomes an environment variable (`$out`, `$dev`, `$doc`) pointing to its own dedicated `/nix/store` path, and `stdenv`'s `fixupPhase` automatically moves files like `include/` and `share/doc/` into `$dev` and `$doc` respectively.

### 2. In the Low-Level `.drv` File

When Nix evaluates your expression and writes the `.drv` file, **Outputs** is the very first field recorded in the file.

- It maps each output name (e.g., `out`, `dev`) to its pre-computed, deterministic `/nix/store/<hash>-<name>` path.

- The Nix build daemon requires this upfront so it can verify after the build finishes that the builder actually created every declared output path before marking the build valid. (The one exception is _fixed-output derivations_ like `fetchurl`, where the store path hash is derived from the expected file content hash you provide rather than the build inputs).

## Package Configuration files

A **`.pc` file** (package configuration file) is a plain-text metadata file used by the **`pkg-config`** tool to tell compilers and build systems (such as `make`, Meson, or CMake) how to compile and link against an installed library.

Instead of hardcoding `/nix/store` paths, header locations, or transitive library dependencies into your build scripts, your build invokes `pkg-config` (e.g., `pkg-config --cflags --libs wayland-client`), which reads the matching `.pc` file and prints the exact compiler (`-I...`) and linker (`-L... -l...`) flags needed.

---

### 1. What Is Inside a `.pc` File?

A `.pc` file uses a simple key-value format containing directory variables at the top and package metadata/flags below:

```ini
prefix=/nix/store/xxxx-wayland-1.23.0-dev
includedir=${prefix}/include
libdir=/nix/store/yyyy-wayland-1.23.0/lib

Name: Wayland Client
Description: Wayland client library
Version: 1.23.0
Requires: wayland-util
Libs: -L${libdir} -lwayland-client
Cflags: -I${includedir}

```

- **Variables (`prefix`, `libdir`, `includedir`, etc.):** Define the exact `/nix/store` locations where the package's files live. Build tools can also query custom variables directly (for example, `pkg-config --variable=pkgdatadir wayland-protocols` returns the path to Wayland's XML protocol files).

- **`Name` / `Description` / `Version`:** Used by build systems to verify minimum required library versions.

- **`Requires` / `Requires.private`:** Lists other `.pc` files this library depends on, allowing `pkg-config` to automatically resolve transitive dependencies.

- **`Cflags` & `Libs`:** The compiler and linker flags injected into your build command.

---

### 2. How `.pc` Files Relate to Nix Derivations

Because Nix isolates every derivation output in its own hash-prefixed `/nix/store/<hash>-<name>` directory rather than shared global directories like `/usr/lib/pkgconfig` or `/usr/share/pkgconfig`, derivations interact with `.pc` files in three specific ways:

1. **Multi-Output Splitting (`outputs = [ "out" "dev" ]`):**

- When a library derivation is built with multiple outputs, `stdenv`'s `fixupPhase` automatically moves `lib/pkgconfig/*.pc` (along with C headers in `include/`) out of the main `$out` path and into the **`$dev` output** (`/nix/store/<hash>-<name>-dev`).

- Architecture-independent packages (such as `wayland-protocols`) place their `.pc` files in `share/pkgconfig/` rather than `lib/pkgconfig/`.

2. **Automatic Path Rewriting in `fixupPhase`:**

- During `fixupPhase`, Nixpkgs hooks inspect generated `.pc` files and ensure `prefix`, `libdir`, and `includedir` point to the exact `/nix/store` output paths of that derivation (even when `libdir` is in `$out` while the `.pc` file itself lives in `$dev`).

3. **Discovery via `pkg-config`'s Setup Hook (`PKG_CONFIG_PATH`):**

- When you build a downstream derivation and place `pkgs.pkg-config` in `nativeBuildInputs` and your libraries in `buildInputs`, `pkg-config`'s Nix setup hook automatically runs during environment setup.

- The hook scans every dependency in `buildInputs` and `nativeBuildInputs` (automatically resolving `.dev` outputs) for `lib/pkgconfig` and `share/pkgconfig` subdirectories and appends them to the `PKG_CONFIG_PATH` environment variable inside the build sandbox.

- (Note: If you merge packages into a symlink farm with `pkgs.buildEnv`, you must explicitly set `extraOutputsToInstall = [ "dev" ];` and include `"/lib"` and `"/share"` in `pathsToLink` so those `.pc` files get linked.)

`.pc` files are generated by a library's **build system** during compilation and installation—not by `pkg-config` itself. Because a `.pc` file must contain the exact installation paths (`prefix`, `libdir`, `includedir`) and enabled feature flags chosen at build time, it cannot be static; it is dynamically templated during `configurePhase` or `buildPhase` and installed during `installPhase`.

Depending on the build tool a project uses, `.pc` files are generated in one of four ways:

### 1. Meson (`import('pkgconfig')` Module)

Modern C/C++ projects (including `wayland`, `wlroots`, `pixman`, and `mesa`) typically use Meson's built-in `pkgconfig` module in `meson.build`:

```meson
pkg = import('pkgconfig')
pkg.generate(
  lib_myproject,
  name: 'myproject',
  description: 'My library description',
  requires: ['wayland-client'],
)

```

During `meson setup` (in Nix's `configurePhase`), Meson automatically reads the configured `--prefix` (`/nix/store/<hash>-<name>`), inspects the target's linked dependencies, and writes out `myproject.pc` into the build directory.

### 2. CMake (`configure_file()`)

CMake does not have a single mandatory `.pc` generator, so projects ship a template file named `myproject.pc.in` containing `@VARIABLE@` placeholders:

```ini
prefix=@CMAKE_INSTALL_PREFIX@
libdir=${prefix}/@CMAKE_INSTALL_LIBDIR@
includedir=${prefix}/@CMAKE_INSTALL_INCLUDEDIR@

Name: @PROJECT_NAME@
Version: @PROJECT_VERSION@
Libs: -L${libdir} -lmyproject
Cflags: -I${includedir}

```

Inside `CMakeLists.txt`, the build system substitutes those variables during `configurePhase` and registers the output for installation:

```cmake
configure_file(myproject.pc.in myproject.pc @ONLY)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/myproject.pc
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig)

```

### 3. GNU Autotools (`configure` / `AC_CONFIG_FILES`)

Older C/C++ projects using Autoconf and Automake also use a `myproject.pc.in` template with `@prefix@`, `@exec_prefix@`, `@libdir@`, and `@VERSION@` placeholders:

- `configure.ac` declares `AC_CONFIG_FILES([myproject.pc])`.
- When `./configure --prefix=/nix/store/...` runs during `configurePhase`, the generated `config.status` script performs variable substitution to create `myproject.pc`.
- `Makefile.am` installs it via `pkgconfig_DATA = myproject.pc`.

### 4. Plain Makefiles or Custom Scripts (`sed` / `install`)

Projects with hand-written Makefiles (or Nix expressions packaging pre-built binaries/headers that lack upstream `.pc` files) generate them directly with `sed`, `envsubst`, or shell `cat` commands during `buildPhase` or `installPhase`:

```nix
postInstall = ''
  mkdir -p $out/lib/pkgconfig
  cat > $out/lib/pkgconfig/my-lib.pc <<EOF
  prefix=$out
  libdir=\${prefix}/lib
  includedir=\${prefix}/include

  Name: my-lib
  Description: Custom library
  Version: ${version}
  Libs: -L\${libdir} -lmylib
  Cflags: -I\${includedir}
  EOF
'';

```

### What Nix Does After Generation (`fixupPhase`)

Once the build system installs the `.pc` file into `$out/lib/pkgconfig` or `$out/share/pkgconfig`, Nix's `stdenv` `fixupPhase` automatically runs two cleanup steps:

1. **Moves to `$dev`:** If the derivation defines `outputs = [ "out" "dev" ]`, `fixupPhase` moves `lib/pkgconfig/*.pc` (and `share/pkgconfig/*.pc` if `dev` is present) into `$dev`.

2. **Fixes Multi-Output Paths:** Because build systems initially set `prefix=$out` (pointing to `/nix/store/<hash>-<name>`), Nix's `fixupPhase` patches `includedir` (and `prefix` if needed) inside the `.pc` file so header lookups point to `$dev/include` while `libdir` still points to `$out/lib`.

---

### Where to Inspect & Learn More

`stdenv.mkDerivation` is documented across several official references, tutorials, and source files depending on whether you need an exhaustive attribute reference, a beginner walkthrough, or the underlying implementation:

### 1. Official Reference: The Nixpkgs Manual

The authoritative, complete specification for `stdenv.mkDerivation` lives in the **Standard Environment (`stdenv`)** chapter of the Nixpkgs Reference Manual.

- **Where to find it:** [Nixpkgs Manual – Standard Environment](https://www.google.com/search?q=https://nixos.org/manual/nixpkgs/unstable/%23chap-stdenv) (look specifically at the **Using `stdenv**`, **Attributes**, and **Phases** sections).
- **What it covers:** Every supported input attribute (`pname`, `version`, `src`, `buildInputs`, `nativeBuildInputs`, `propagatedBuildInputs`, `strictDeps`, `enableParallelBuilding`, etc.), environment variables, and the exact execution order and hooks of every build phase (`unpackPhase` through `fixupPhase`).
- **Source file in Git:** If you have a local clone of `nixpkgs`, the Markdown source for this documentation is located at `doc/stdenv/stdenv.chapter.md`.

### 2. Guided Tutorials: `nix.dev` & Nix Pills

If you want practical examples rather than a dry reference sheet:

- **Packaging existing software with Nix (`nix.dev`):** The official tutorial site walks through writing a `stdenv.mkDerivation` expression from scratch, explaining `callPackage`, phases, and hooks in plain language (`[https://nix.dev/tutorials/packaging-existing-software.html](https://nix.dev/tutorials/packaging-existing-software.html)`).
- **Nix Pills (Chapters 19 & 20):** The classic deep-dive series explains how `stdenv.mkDerivation` wraps the low-level `builtins.derivation` primitive (`[https://nixos.org/guides/nix-pills/19-fundamentals-of-stdenv.html](https://nixos.org/guides/nix-pills/19-fundamentals-of-stdenv.html)`).

### 3. Function Search: Noogle

- **Noogle (`noogle.dev`):** Searching for `pkgs.stdenv.mkDerivation` on [noogle.dev](https://noogle.dev/f/pkgs/stdenv/mkDerivation/) pulls up its type signature, documentation summary, and a direct link to its exact line number in the `nixpkgs` repository.

### 4. Inspecting the Implementation Directly

Because `stdenv.mkDerivation` is implemented in Nix and Bash inside `nixpkgs`, you can jump straight to its source code from your terminal:

- **Via `nix repl`:** Run `nix repl -f '<nixpkgs>'` (or `nix repl --expr 'import <nixpkgs> {}'`) and run:

```nix
:e stdenv.mkDerivation

```

This opens the exact implementation file (`pkgs/stdenv/generic/make-derivation.nix`) in your `$EDITOR`.

- **Build script (`setup.sh`):** To see the actual Bash functions that execute the build phases (`genericBuild`, `unpackPhase`, `buildPhase`, etc.), inspect `pkgs/stdenv/generic/setup.sh` in the `nixpkgs` repository.

- **Nixpkgs Manual:** The _Standard Environment (`stdenv`)_ chapter (`doc/stdenv/stdenv.chapter.md` in Nixpkgs) documents every attribute, hook, and phase.

- **Source Implementation:** In `nix repl -f '<nixpkgs>'`, running `:e stdenv.mkDerivation` opens `pkgs/stdenv/generic/make-derivation.nix` directly in your editor, while `pkgs/stdenv/generic/setup.sh` contains the Bash phase implementations.

Are you looking to package a specific project with `stdenv.mkDerivation`, customize its build phases, or refine a `devShell`?

## Handling many dependencies

By default, `stdenv.mkDerivation` does **not** create a merged directory of symlinks for dependencies. Instead, its initialization script (`setup.sh`) iterates over every dependency and appends each package's individual `/nix/store/<hash>-<pkg>/bin` path directly onto `PATH` (and similarly populates `NIX_CFLAGS_COMPILE`, `NIX_LDFLAGS`, `PKG_CONFIG_PATH`, etc.).

## Is stdenv.mkDerivation limited to c & c++ packages

**No**, `stdenv.mkDerivation` is not limited to C and C++ packages. It is a general-purpose build orchestrator that can package software written in any language, shell scripts, configuration files, fonts, themes, or pre-compiled binaries.

### Why It Feels C/C++-Centric

By default, `stdenv` includes a C/C++ toolchain (`gcc` or `clang`, `binutils`, `make`, and GNU coreutils) in the build environment, and its default build phases (`configurePhase`, `buildPhase`, `installPhase`) are designed around standard Unix build systems like GNU Autotools and Makefiles. Because of this:

- **C/C++ packages** often build with almost zero configuration.

- **Other languages** simply override those default phases—or use language-specific hooks and wrappers built on top of `stdenv.mkDerivation`.

### How Other Languages Use `stdenv.mkDerivation`

In Nixpkgs, almost every language-specific builder is actually a wrapper around `stdenv.mkDerivation` (or uses `stdenv.mkDerivation` directly with setup hooks):

- **Rust (`rustPlatform.buildRustPackage`):** Calls `stdenv.mkDerivation` under the hood, adding `cargo` and `rustc` to `nativeBuildInputs` and replacing the C-style `configurePhase`/`buildPhase` with Cargo build and test hooks.
- **Go (`buildGoModule`):** Wraps `stdenv.mkDerivation` to manage Go module vendor dependencies and run `go build` instead of `make`.
- **Python (`python3Packages.buildPythonPackage`):** Wraps `stdenv.mkDerivation` to build wheels (`pip`/`setuptools`/`flit`) and wrap resulting scripts with the proper `PYTHONPATH`.
- **Node.js / Frontend (`buildNpmPackage` / `mkYarnPackage`):** Uses `stdenv.mkDerivation` with Node.js hooks to run `npm run build` and bundle assets.
- **Pure Assets, Scripts, & Binaries:** You can use `stdenv.mkDerivation` directly (or `stdenvNoCC.mkDerivation`, which omits the C compiler to speed up evaluation and builds) for packaging shell scripts, fonts, icons, or pre-built binaries:

```nix
{ stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation {
  pname = "my-script";
  version = "1.0";
  src = ./my-script.sh;

  dontUnpack = true;
  installPhase = ''
    install -Dm755 $src $out/bin/my-script
  '';
}

```

---

### How Nix Actually Handles Giant Dependency Lists

Because large packages (like Chromium, LibreOffice, or full KDE/GNOME builds) easily exceed the Linux kernel's `ARG_MAX` / single-variable `MAX_ARG_STRLEN` limit (128 KB per environment variable string) when hundreds of `/nix/store/...` paths are concatenated, Nixpkgs uses two mechanisms rather than a symlink farm:

1. **`__structuredAttrs = true;` (Passing Environment via JSON File)**

- Instead of passing huge lists of inputs and flags through OS environment variables (`execve` arguments), setting `__structuredAttrs = true` tells Nix to serialize all derivation attributes and dependency lists into a `.attrs.json` file inside the build sandbox.
- `setup.sh` reads that JSON file directly inside Bash, bypassing the OS `ARG_MAX` environment size limit for derivation attributes.

2. **Response Files (`@file`) in Compiler/Linker Wrappers**

- Because `NIX_CFLAGS_COMPILE` and `NIX_LDFLAGS` also grow huge with hundreds of `-I/nix/store/...` and `-L/nix/store/...` flags, Nixpkgs' `gcc-wrapper` and `binutils-wrapper` support passing flags via temporary response files (`@responsefile`) rather than directly on the `gcc`/`ld` command line.

---

### When You _Do_ Want a Single Symlink Directory

If you specifically want a single merged `bin/` directory (for a development shell, IDE integration, or avoiding long `PATH` strings in subprocesses), you have to explicitly build one using **`pkgs.buildEnv`** (or **`pkgs.symlinkJoin`**) and point `PATH` to it:

```nix
let
  mergedTools = pkgs.buildEnv {
    name = "build-tools-env";
    paths = [ pkgs.git pkgs.gcc pkgs.gnumake pkgs.pkg-config ];
    pathsToLink = [ "/bin" ];
  };
in
pkgs.stdenv.mkDerivation {
  name = "my-package";
  nativeBuildInputs = [ mergedTools ];
  # ...
}

```

When `mergedTools` is passed to `nativeBuildInputs`, `stdenv` adds only that single `/nix/store/<hash>-build-tools-env/bin` entry to `PATH` instead of separate entries for every individual tool. (Note: Compiler wrappers like `gcc-wrapper` and `pkg-config` still require their setup hooks and `NIX_CFLAGS_COMPILE` / `PKG_CONFIG_PATH` variables to locate headers and libraries.)

## The build sandbox

In Nix, the **build sandbox** is an isolated execution environment created by the Nix build daemon whenever it realises (builds) a derivation. Its purpose is to guarantee **reproducible, deterministic builds** by preventing build scripts from accidentally depending on undeclared system state, local files, or the internet.

### What the Sandbox Isolates

When the Nix daemon runs a build (using Linux namespaces on Linux, or `sandbox-exec` on macOS), it restricts the builder process in several ways:

- **Filesystem Visibility (Store Isolation):** The build process only sees the exact `/nix/store` paths declared in the derivation's inputs (its `inputDrvs` and `inputSrcs`). Everything else on your system—`/usr`, `/etc`, `/home`, and even other valid `/nix/store` packages that weren't explicitly listed in `buildInputs` or `nativeBuildInputs`—is completely hidden.

- **Temporary Build & Output Directories:** The sandbox mounts a fresh, ephemeral `/build` directory (where source archives are unpacked and compiled) and writable target paths for the derivation's declared outputs (such as `$out`). Once the build succeeds, `/build` is deleted and `$out` becomes read-only.

- **Network Isolation:** All network access is blocked (except on the loopback interface `lo`). A standard build cannot download dependencies from GitHub, npm, crates.io, or PyPI mid-build. (The only exception is **fixed-output derivations** like `fetchurl`, which are granted network access because their output is verified against an exact cryptographic hash you supply upfront.)

- **Sanitized Environment & Users:** All host environment variables are wiped and replaced with only the variables defined in the `.drv` file. On Linux, the build runs under dedicated unprivileged build users (`nixbld1`, `nixbld2`, etc.) with isolated PID, IPC, and UTS namespaces.

---

### Why This Matters for `stdenv.mkDerivation`

1. **No "Works on My Machine" Bugs:** Because global paths like `/usr/include` or `/usr/bin` do not exist inside the sandbox, a build cannot silently pick up an undeclared library installed on your host OS.
2. **Enforced Dependency Completeness:** If you forget to add `pkg-config` or a C library to `nativeBuildInputs` / `buildInputs`, the build fails immediately inside the sandbox—even if that library is already sitting in your local `/nix/store`.

3. **Interactive Debugging (`nix develop`):** Unlike `nix build`, running `nix develop` drops you into your normal shell **outside** the build sandbox so you can use your editor, git, and network—while still populating the `PATH` and compiler environment variables that `stdenv` would set up. (If you ever need to debug a failing sandboxed build directly, `nix develop --ignore-environment` or `breakpointHook` lets you inspect the sandbox state.)

## Specifying multiple outputs

A derivation can produce multiple outputs, each placed in its own separate `/nix/store` directory. This is commonly used in Nixpkgs to split runtime binaries and libraries from C headers (`.dev`) or documentation (`.doc`), so runtime users do not have to download build-time files.

### How to Define Multiple Outputs

You specify multiple outputs by passing an `outputs` list of strings to `stdenv.mkDerivation` (or `builtins.derivation`):

```nix
stdenv.mkDerivation {
  pname = "example";
  version = "1.0.0";

  outputs = [ "out" "dev" "doc" ];

  # ...
}

```

### How It Works During Evaluation and Build

- **Pre-computed Store Paths:** Before running the build, Nix computes a distinct deterministic `/nix/store/<hash>-<name>-<output>` path for every name in the `outputs` list (the first output, conventionally `"out"`, omits the `-out` suffix).

- **Environment Variables in the Sandbox:** Inside the build sandbox, Nix exports each output name as an environment variable (`$out`, `$dev`, `$doc`) pointing to its corresponding `/nix/store` path.

- **Automatic Splitting in `stdenv`:** When using standard output names like `"dev"`, `"doc"`, `"man"`, or `"bin"`, `stdenv`'s `fixupPhase` automatically moves standard directories (such as `include/` and `lib/pkgconfig/` into `$dev`, and `share/doc/` into `$doc`) without requiring manual `mv` commands in `installPhase`.

- **Referencing Specific Outputs:** Downstream expressions can access a specific output as an attribute on the derivation (e.g., `pkgs.wayland.dev` or `pkgs.wayland.out`), while referencing the package directly (`pkgs.wayland`) defaults to the first output in the list.

## Wrapping Programs

**`wrapProgram`** is a shell helper function provided by Nixpkgs' **`makeWrapper`** (or `makeBinaryWrapper`) setup hook. It is used to ensure an executable always runs with specific environment variables, `PATH` entries, or command-line flags—without requiring the user to configure their shell environment manually before running the program.

### Why It Is Needed

In Nix, packages are isolated inside their own `/nix/store/<hash>-<name>` directories and cannot rely on global paths like `/usr/bin` or global configuration variables. Many programs (especially interpreted scripts in Python, Perl, or Bash, or GUI apps using GSettings/GTK/Qt) expect runtime tools on `PATH`, shared data directories in `XDG_DATA_DIRS`, or library paths to be set when they launch. `wrapProgram` bakes those runtime requirements directly into the executable's entrypoint.

---

### How It Works

When you call `wrapProgram $out/bin/my-app <flags>` (typically inside `postInstall` or `postFixup`), it performs three steps:

1. **Renames the Original Executable:** It moves `$out/bin/my-app` to a hidden file in the same directory named `$out/bin/.my-app-wrapped`.
2. **Generates a Wrapper Script (or Binary):** It creates a new executable at `$out/bin/my-app` (either a POSIX shell script via `makeWrapper`, or a compiled C binary via `makeBinaryWrapper`).
3. **Configures Environment & `exec`s the Original:** When a user runs `my-app`, the wrapper modifies the specified environment variables or prepends/appends CLI flags, and then replaces its own process with the real binary using `exec -a "$0" "$out/bin/.my-app-wrapped" "$@"` (preserving `argv[0]` and forwarding all user arguments).

_(Note: Because `wrapProgram` leaves the hidden `.my-app-wrapped` file inside `$out/bin/`, `makeWrapper` also provides `wrapProgram`'s cousin **`makeWrapper`**, which lets you place the unwrapped binary elsewhere—such as `$out/libexec/my-app`—and generate the wrapper at `$out/bin/my-app`.)_

---

### Common Example

To use `wrapProgram`, add `makeWrapper` (or `makeBinaryWrapper`) to `nativeBuildInputs` and call `wrapProgram` in `postInstall` or `postFixup`:

```nix
{ lib, stdenv, makeWrapper, coreutils, jq }:

stdenv.mkDerivation {
  pname = "my-tool";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -Dm755 my-tool.sh $out/bin/my-tool
  '';

  postFixup = ''
    wrapProgram $out/bin/my-tool \
      --prefix PATH : ${lib.makeBinPath [ coreutils jq ]} \
      --set MY_APP_MODE "production" \
      --add-flags "--config /etc/my-tool.conf"
  '';
}

```

### Common `wrapProgram` Flags

- **`--prefix VAR : VALUE` / `--suffix VAR : VALUE`:** Prepends or appends `VALUE` to a colon-separated variable like `PATH` or `XDG_DATA_DIRS` (commonly paired with `lib.makeBinPath [ ... ]`).
- **`--set VAR VALUE`:** Unconditionally sets `VAR=VALUE`.
- **`--set-default VAR VALUE`:** Sets `VAR=VALUE` only if `VAR` is not already set in the user's environment.
- **`--unset VAR`:** Removes `VAR` from the environment before launching.
- **`--add-flags "FLAGS"`:** Passes default command-line arguments ahead of whatever arguments the user supplies.

_(Tip: On macOS—and for binaries that might be invoked via shebangs `#!/usr/bin/env`—prefer `makeBinaryWrapper` in `nativeBuildInputs` instead of `makeWrapper`, as macOS cannot use a shell script as a `#!` interpreter whereas a compiled C wrapper works everywhere.)_

## Ensuring Reproducibility

In Nix, ensuring an executable runs with the exact library and binary versions it was built and tested against—regardless of what is installed or missing in `/etc/profiles/per-user/${USER}/bin` or `/run/current-system/sw/bin`—is handled at two distinct layers: **ELF/Mach-O binary linking** (for shared libraries) and **wrapper scripts** (for runtime subprocesses and environment paths).

### 1. Shared Libraries (`.so` / `.dylib`): Automatic via `RUNPATH` / `RPATH`

For compiled binaries (C, C++, Rust, Go, etc.), Nix handles library version pinning **automatically** during `stdenv.mkDerivation`'s `fixupPhase`:

- **Embedded Store Paths:** When a binary is linked against libraries declared in `buildInputs`, `gcc-wrapper`/`ld-wrapper` and `patchelf` (on Linux) or `install_name_tool` (on macOS) embed the exact `/nix/store/<hash>-<lib>-<version>/lib` paths directly into the binary's ELF `RUNPATH` (and `INTERP` for `ld-linux.so`).

- **Immune to User `PATH`:** Because the dynamic linker (`ld.so`) reads the binary's embedded `RUNPATH` before checking system paths, your binary will **never** accidentally load a different library version from `/run/current-system/sw/lib` or a user profile—even if the user's environment has conflicting versions or none at all.

- _(Note: Avoid setting `LD_LIBRARY_PATH` in the user environment, as it overrides `RUNPATH`.)_

---

### 2. Runtime Binaries & Tools: `wrapProgram` (or `makeWrapper`)

`RUNPATH` only protects shared libraries, not external executables your program spawns at runtime (e.g., calling `jq`, `git`, `ffmpeg`, or `xdg-open` via `exec`/`system()`), nor interpreter search paths (`PYTHONPATH`, `GI_TYPELIB_PATH`). If your executable relies on `PATH` to find helper tools, it will pick up whatever version sits in `/etc/profiles/per-user/${USER}/bin` or `/run/current-system/sw/bin` unless you bind them explicitly.

Use **`makeWrapper`** (or **`makeBinaryWrapper`**) with **`wrapProgram`** in `postFixup` to prepend the exact `/nix/store` paths of your tested runtime dependencies onto `PATH`:

```nix
{ lib, stdenv, makeBinaryWrapper, jq, coreutils, wayland }:

stdenv.mkDerivation {
  pname = "my-app";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ makeBinaryWrapper ];
  buildInputs = [ wayland ]; # Automatically pinned via ELF RUNPATH

  installPhase = ''
    install -Dm755 my-app $out/bin/my-app
  '';

  # Pin exact versions of runtime CLI dependencies ahead of user/system PATH
  postFixup = ''
    wrapProgram $out/bin/my-app \
      --prefix PATH : ${lib.makeBinPath [ jq coreutils ]}
  '';
}

```

#### Why `--prefix PATH :` Solves the Profile Conflict

- **`--prefix PATH : ${lib.makeBinPath [ ... ]}`** prepends the exact `/nix/store/<hash>-<pkg>/bin` directories of the packages passed to your derivation **ahead** of `/etc/profiles/per-user/${USER}/bin` and `/run/current-system/sw/bin`.
- If the user environment lacks `jq` or has an incompatible version, `my-app` still resolves the exact `jq` version from `/nix/store` that it was built and tested against, while still allowing `my-app` to fall back to the user's `PATH` for everything else.
- **Strict Isolation (`--set PATH`):** If your executable must _only_ see the exact binaries you declare and completely ignore `/etc/profiles/per-user/${USER}/bin` and `/run/current-system/sw/bin`, replace `--prefix PATH :` with:

```nix
--set PATH ${lib.makeBinPath [ jq coreutils ]}

```

---

### 3. Hardcoding Exact Binary Paths at Build Time (Alternative for Source Code)

If you control the source code or build configuration (e.g., Meson, CMake, or `substituteInPlace` in `postPatch`), an alternative to `wrapProgram` is patching the source directly to invoke the full `/nix/store` path rather than searching `PATH`:

```nix
postPatch = ''
  substituteInPlace src/main.c \
    --replace-fail '"jq"' '"${lib.getExe jq}"'
'';

```

`lib.getExe jq` evaluates to `/nix/store/<hash>-jq-<version>/bin/jq`, baking the exact store binary path into the compiled executable just like `RUNPATH` does for libraries.

---

### Verification

1. **Verify shared library pinning (`RUNPATH`):**

```bash
ldd ./result/bin/my-app

```

Confirm every `.so` entry resolves directly to `/nix/store/<hash>-...` rather than `/run/...` or `not found`. 2. **Verify subprocess binary pinning (`wrapProgram`):**
Test the binary in a stripped environment with no system or user profile paths:

```bash
env -i ./result/bin/my-app

```

If the executable runs cleanly with an empty `PATH`, all runtime binaries and libraries are completely self-contained in `/nix/store`.
