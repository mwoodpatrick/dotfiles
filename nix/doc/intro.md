In developer circles—and across the themes in your notes—**"The Holy Grail of Development Environments"** refers to achieving **byte-for-byte reproducibility across every machine (local dev, CI/CD, and production) with zero host pollution, native execution speed, and seamless IDE automation.**

In modern workflows, the stack widely considered closest to this ideal combines **Nix Flakes**, **`direnv`**, and (when needed) **microVMs or FHS sandboxes**:

---

### 1. The Core Pillars of the "Holy Grail" Setup

* **Declarative & Reproducible (`flake.nix` + `flake.lock`):** Every compiler, language runtime, C header, system library, and CLI tool is pinned to an exact cryptographic hash. Anyone cloning the repo—whether on Linux, WSL2, or macOS—gets the exact same toolchain without "works on my machine" drift.


* **Native Speed Without Container Overhead:** Unlike Docker or DevContainers, Nix development shells run directly on the host kernel. You get native filesystem I/O, direct access to your local editor/LSPs, native GPU/display acceleration, and minimal RAM overhead—no volume mounts or port forwarding required.


* **Zero Global Pollution:** Dependencies live in the immutable `/nix/store/` rather than mutating `/usr/bin` or global language caches, preventing version collisions across projects.


* **Invisible, Automatic Activation (`direnv` + `nix-direnv`):** By placing `use flake` in a committed `.envrc` file, entering a directory (`cd`) or opening an editor (Neovim, VS Code) automatically loads the exact environment in milliseconds and unloads it when you leave.


* **Local Dev & CI Parity:** The exact same `devShells` and `packages` definitions used locally run in GitHub Actions or CI pipelines, eliminating discrepancies between local builds and CI runners.

---

### 2. Solving the Real-World Friction Points

While Nix + `direnv` gets 95% of the way there, hitting true "Holy Grail" ergonomics requires solving three classic edge cases:

| Friction Point | Solution |
| --- | --- |
| **Environment Variable Bloat (`E2BIG` / 128 KB limit)** when projects have dozens of C/Wayland dependencies

 | Merge dependencies into a single `/nix/store` symlink tree via `pkgs.buildEnv` (or expose a single `.nix-dev` symlink) and use `pkgs.mkShellNoCC`.

 |
| **Unpatched Precompiled Binaries & Wheels** (e.g., Python `uv`/`pip` wheels, proprietary SDKs expecting `/lib64/ld-linux` and `/usr/lib`)

 | Wrap the shell in `pkgs.buildFHSEnv` (rootless user/mount namespace) or enable `programs.nix-ld` system-wide on NixOS.

 |
| **Untrusted / Multi-Tenant Execution** (e.g., running AI coding agents or arbitrary code safely)

 | Pair declarative Nix root filesystems with **Firecracker microVMs** for hardware-enforced KVM isolation rather than shared-kernel containers.

 |

---

### 3. Notable Articles & References Using This Phrase

* **"The Holy Grail of Development Environments: My Journey to Nix"** (Nov 2026) — A widely shared walkthrough detailing the progression from heavy Docker-aliased bash scripts to modular Nix Flakes, `home-manager`, `direnv`, and GitHub Actions CI parity.
* **The Nix / Devbox / Flox Ecosystem** — Tools like **Flox** and **Devbox** explicitly market around this concept by wrapping Nix's reproducible store engine in a simpler CLI for teams that want Nix's guarantees without learning the Nix expression language.

* **Article URL:** [https://xnok.github.io/infra-bootstrap-tools/blog/journey-to-nix/](https://xnok.github.io/infra-bootstrap-tools/blog/journey-to-nix/)
* **Author's Site / Series:** [https://xnok.github.io/infra-bootstrap-tools/](https://xnok.github.io/infra-bootstrap-tools/) (by Alexandre Couedelo, also cross-posted on his Medium at [https://alexandre-couedelo.medium.com/](https://alexandre-couedelo.medium.com/))

integrating cleanly with lasted version of OpenCode
Integrating the latest **OpenCode v2.4.x** (`v2.4.1`) cleanly into a **Nix Flake + `direnv` + Neovim** workflow revolves around three pieces: exposing the `opencode` CLI from your flake without polluting `PATH` or colliding with your v1/dev SQLite databases, wiring Neovim's editor-aware integration (`opencode.nvim`), and optionally using OpenCode's **ACP (Agent Client Protocol)** server mode.

---

### 1. Declarative Flake Setup (`flake.nix` + `.envrc`)

Rather than installing `opencode` globally where it misses project-specific compilers (`gcc`, `clangd`, `bun`, `lean`, etc.), expose it inside your project's `devShell` (either from `nixpkgs-unstable` or directly from the `github:anomalyco/opencode` flake input so you stay pinned to `v2.4.x`):

```nix
{
  description = "Reproducible Dev Environment with OpenCode v2.4.x";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    opencode.url = "github:anomalyco/opencode"; # Pins latest v2.4.x
  };

  outputs = { self, nixpkgs, opencode }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      opencodePkg = opencode.packages.${system}.default;
    in {
      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = [
          opencodePkg
          pkgs.ripgrep
          pkgs.fd
          # Add project compilers/LSPs here so OpenCode's bash/tool calls inherit them
        ];

        shellHook = ''
          # Optional: keep project-local OpenCode v2 SQLite DB isolated per repo or channel[cite: 6, 9]
          # export OPENCODE_DB="$PWD/.opencode/opencode.db"
        '';
      };
    };
}

```

With `.envrc` containing `use flake` (and `direnv allow`):

* **Tool Inheritance:** Because `direnv` activates the flake environment in your shell before you launch `nvim` or `opencode`, every shell command, test runner, and build tool OpenCode invokes automatically uses the exact pinned derivations in your `flake.lock`.


* **Database Isolation (`v2.4.x`):** OpenCode 2 isolates channel databases automatically (`opencode.db` vs `opencode-dev.db`). If you run both a stable Nix package and a local `dev` build from `/mnt/wsl/projects/git/opencode`, leave `OPENCODE_DB_STABLE` unset so schema migrations don't collide—or verify which SQLite file is active anytime via `opencode debug paths db`.



---

### 2. Clean Neovim Integration (`nickjvandyke/opencode.nvim`)

Because `opencode` runs as an external CLI/server process rather than a monolithic Lua reimplementation, the cleanest Neovim bridge is **`nickjvandyke/opencode.nvim`** (which communicates with the `opencode` binary on your `PATH` via its local HTTP/SSE server and terminal/tmux pane):

```lua
-- lazy.nvim plugin spec
{
  "nickjvandyke/opencode.nvim",
  dependencies = { "folke/snacks.nvim" }, -- optional, for enhanced input/picker UI
  config = function()
    -- Required so opencode's file edits auto-reload cleanly in Neovim buffers
    vim.o.autoread = true

    ---@type opencode.Opts
    vim.g.opencode_opts = {
      -- Automatically starts/connects to `opencode --port` inside the current project
    }

    -- Core workflow keymaps
    vim.keymap.set({ "n", "x" }, "<leader>oa", function() require("opencode").ask("@this: ", { submit = true }) end, { desc = "Ask OpenCode" })
    vim.keymap.set({ "n", "x" }, "<leader>ox", function() require("opencode").select() end, { desc = "OpenCode Actions" })
    vim.keymap.set({ "n", "t" }, "<leader>ot", function() require("opencode").toggle() end, { desc = "Toggle OpenCode" })
  end,
}

```

#### Why This Fits the Nix + `direnv` Workflow

* **Zero hardcoded store paths in Neovim:** `opencode.nvim` simply executes `opencode` from `PATH`, so entering different project directories via `direnv` automatically binds Neovim to whichever `opencode` version and project toolchain that flake provides.


* **Editor Context Injection (`@this`, `@buffers`, `@diagnostics`):** You can pass visual selections, active LSP diagnostics (e.g., `clangd` or Lean 4 errors), and open buffers directly into OpenCode prompts without copy-pasting.
* **Live Buffer Sync (`autoread`):** When OpenCode edits files on disk (including background subagents introduced in v2.3+), Neovim reloads buffers seamlessly.

---

### 3. Optional: ACP Mode (CodeCompanion / Zed / Multi-Client)

If you prefer keeping a single unified chat UI inside Neovim alongside other local Ollama/cloud providers, OpenCode v2 exposes a native **Agent Client Protocol (ACP)** server (`opencode acp`) that plugins like **CodeCompanion.nvim** can connect to as an ACP adapter—giving you OpenCode's agentic file/bash tools and v2.4 session management directly inside a native Neovim split.

Do you prefer running OpenCode in its full TUI (`opencode.nvim` split/tmux) or embedding it via ACP inside Neovim?

Embedding **OpenCode (`opencode acp`)** inside Neovim via the **Agent Client Protocol (ACP)** works cleanest through **`olimorris/codecompanion.nvim`**, which includes native ACP adapter support (`opencode` is built-in as a supported ACP agent).

Because your shell environment is driven by **Nix Flakes + `direnv**`, CodeCompanion spawns `opencode acp` as a child process of Neovim—meaning it automatically inherits your active `devShell` tools, compilers, LSPs, and environment variables without hardcoding any `/nix/store` paths.

---

### 1. Ensure `opencode` Is in Your Flake `devShell`

Expose `opencode` in your project's `flake.nix` `devShell` alongside your project's build tools and LSPs:

```nix
devShells.${system}.default = pkgs.mkShellNoCC {
  packages = [
    opencodePkg # from nixpkgs-unstable or github:anomalyco/opencode
    pkgs.ripgrep
    pkgs.fd
    # Project compilers / LSPs (e.g., clang-tools, lean, etc.)
  ];
};

```

(Note: If you run both a stable Nix build and a local `dev` build from `/mnt/wsl/projects/git/opencode`, leave `OPENCODE_DB_STABLE` unset so `opencode acp` uses its isolated channel SQLite database and won't collide with other channels.)

---

### 2. Configure `codecompanion.nvim` with the `opencode` ACP Adapter

In your Neovim plugin config (`lazy.nvim`), set `opencode` as your default `chat` strategy adapter (or alongside your existing Ollama/cloud adapters so you can switch on the fly):

```lua
{
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    strategies = {
      chat = {
        adapter = "opencode",
      },
      inline = {
        adapter = "opencode",
      },
    },
    adapters = {
      acp = {
        opencode = function()
          return require("codecompanion.adapters").extend("opencode", {
            -- Optional: override defaults (e.g., pin a specific provider/model)
            defaults = {
              -- model = "anthropic/claude-sonnet-4-5",
            },
            commands = {
              -- Uses `opencode` from your direnv-activated PATH
              default = { "opencode", "acp" },
            },
          })
        end,
      },
    },
    opts = {
      -- Recommended: reload buffers automatically when OpenCode edits files on disk
      log_level = "ERROR",
    },
  },
  keys = {
    { "<leader>aa", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "CodeCompanion Actions" },
    { "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "Toggle OpenCode ACP Chat" },
    { "ga", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "Add Selection to OpenCode Chat" },
  },
}

```

Add `vim.o.autoread = true` in your Neovim `options.lua` so files modified by OpenCode's ACP file tools update immediately in open Neovim buffers.

---

### 3. Verify the ACP Handshake Inside Neovim

1. `cd` into your project directory (so `direnv` loads your flake) and launch `nvim`.


2. Open the chat buffer with `<leader>ac` (`:CodeCompanionChat`).
3. Confirm the chat header shows **`opencode (ACP)`** and test tool access with a prompt like:
```text
@buffers Check which compiler and tool versions are active in this environment.

```


OpenCode will execute inside the inherited `devShell` and report the exact pinned `/nix/store` binaries.



---

### 4. Practical ACP Tips for Multi-Provider / Lean 4 Workflows

* **Switching Between `opencode` ACP and Local Ollama Models:** Keep your existing `http` adapters (like `ollama`) defined under `adapters.http` in `codecompanion.nvim`. Inside any chat buffer, press `ga` (or `:CodeCompanionChat`) and change adapters via the CodeCompanion adapter menu (`gx` in the chat buffer by default) without leaving Neovim.
* **Custom Slash Commands & Subagents:** OpenCode's ACP server automatically exposes your project's `.opencode/` agents, slash commands, and `AGENTS.md` rules inside CodeCompanion's `/` completion menu in the chat buffer.


* **Troubleshooting Connection Issues:** If `opencode acp` fails to initialize, test the stdio JSON-RPC server directly from the same shell with `opencode acp` (it should block waiting for JSON-RPC input on stdin without printing startup errors) and check `:CodeCompanionLogs` in Neovim.

Would you like to merge this with an existing `codecompanion.nvim` Ollama config (for example, routing Lean 4 proof blocks to a local model while keeping `opencode` ACP for multi-file edits)?

Here is a unified **`codecompanion.nvim`** configuration that sets **`opencode` (ACP)** as your primary agentic chat/file-editing adapter while keeping **local Ollama models** wired up for fast, zero-latency inline edits and Lean 4 tactic/proof completion.

---

### 1. Unified `codecompanion.nvim` Setup (`lua/plugins/codecompanion.lua`)

```lua
return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    strategies = {
      -- Primary agentic chat & multi-file refactoring via OpenCode ACP
      chat = {
        adapter = "opencode",
      },
      -- Fast local inline edits / Lean 4 proof fills via Ollama
      inline = {
        adapter = "ollama_lean",
      },
      -- Command-line / quick code actions via local Ollama
      cmd = {
        adapter = "ollama_lean",
      },
    },

    adapters = {
      -- 1. ACP Adapter: Spawns `opencode acp` inside your direnv-activated Nix devShell
      acp = {
        opencode = function()
          return require("codecompanion.adapters").extend("opencode", {
            commands = {
              default = { "opencode", "acp" },
            },
          })
        end,
      },

      -- 2. HTTP Adapter: Local Ollama for low-latency Lean 4 / C / Nix inline work
      http = {
        ollama_lean = function()
          return require("codecompanion.adapters").extend("ollama", {
            name = "ollama_lean",
            schema = {
              model = {
                -- Swap to your preferred local model (e.g., qwen2.5-coder:14b, deepseek-r1:14b, or Goedel-Prover)
                default = "qwen2.5-coder:14b",
              },
              num_ctx = {
                default = 16384,
              },
              temperature = {
                default = 0.2,
              },
            },
          })
        end,
      },
    },

    -- Optional: Reusable prompt templates for Lean 4 + OpenCode workflows
    prompt_library = {
      ["Lean 4: Prove Goal / Tactic"] = {
        strategy = "inline",
        description = "Fill in a `sorry` or suggest Lean 4 tactics using local Ollama",
        opts = {
          adapter = "ollama_lean",
          is_slash_cmd = true,
          short_name = "lean_prove",
        },
        prompts = {
          {
            role = "system",
            content = "You are an expert Lean 4 and Mathlib formalizer. Output valid Lean 4 tactic code only, with no markdown fences or prose.",
          },
          {
            role = "user",
            content = function(context)
              local text = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
              return "Complete the Lean 4 proof or replace `sorry` in:\n\n" .. text
            end,
          },
        },
      },

      ["OpenCode: Verify & Build"] = {
        strategy = "chat",
        description = "Have OpenCode run lake/make/tests in the Nix devShell and fix errors",
        opts = {
          adapter = "opencode",
          is_slash_cmd = true,
          short_name = "oc_verify",
        },
        prompts = {
          {
            role = "user",
            content = "@buffers Run the project build/typecheck command in this devShell, inspect any compiler or LSP errors, and fix them.",
          },
        },
      },
    },

    opts = {
      log_level = "ERROR",
    },
  },

  keys = {
    -- OpenCode ACP Chat (multi-file edits, bash/lake execution, repo search)
    { "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "Toggle OpenCode ACP Chat" },
    -- Local Ollama Inline Edit (highlight a `sorry` block in Lean 4 and prompt inline)
    { "<leader>ai", ":CodeCompanion ", mode = { "n", "v" }, desc = "Inline Edit (Local Ollama)" },
    -- Quick Lean 4 Proof Fill via local Ollama
    { "<leader>ap", "<cmd>CodeCompanion /lean_prove<cr>", mode = { "n", "v" }, desc = "Lean 4 Prove (Ollama)" },
    -- Action Palette (switch adapters or pick custom prompts)
    { "<leader>aa", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "CodeCompanion Actions" },
    -- Send visual selection directly to OpenCode ACP Chat
    { "ga", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "Add Selection to OpenCode Chat" },
  },
}

```

---

### 2. How the Two Adapters Work Together

| Workflow | Active Adapter | Keymap | Why |
| --- | --- | --- | --- |
| **Multi-file edits, running `lake build`, `make`, or `rg**` | `opencode` (ACP) | `<leader>ac` / `ga` | OpenCode's ACP server inherits your `direnv` Nix `devShell` (`lean`, `gcc`, `clangd`, `bun`) and executes multi-step tool calls with buffer auto-reload (`vim.o.autoread = true`).

 |
| **Filling a `sorry` or rewriting a single function** | `ollama_lean` (HTTP) | `<leader>ap` / `<leader>ai` | Local Ollama responds immediately on the selected lines without spinning up an agent loop. |
| **Switching adapters mid-chat** | Either (`opencode` $\leftrightarrow$ `ollama_lean`) | `gx` inside chat buffer | Lets you brainstorm a theorem locally with Ollama, then switch the same buffer to `opencode` ACP to apply edits across files. |

---

### 3. Quick Checklist Before Testing

1. **Enable `autoread` in `lua/config/options.lua`:**
```lua
vim.o.autoread = true

```


This ensures that when OpenCode edits `.lean`, `.c`, or `.nix` files via ACP, open Neovim buffers refresh immediately.
2. **Keep `opencode` in your project's `flake.nix` `devShell`:** Because `direnv` loads your flake before Neovim starts, `opencode acp` automatically sees the exact `lean` / `lake` / `gcc` binaries from `/nix/store`.


3. **Verify both adapters:** Open a `.lean` file in a `direnv`-enabled repo, press `<leader>ac` to verify `opencode (ACP)` connects, and highlight a proof block with `<leader>ap` to confirm local Ollama streams the tactic inline.


The target release date for **NixOS 26.11 ("Zokor")** is **Monday, November 30, 2026** (08:00 UTC).

### Nix 26.11 Current Release Status

* **Release Branch Created:** The `release-26.11` branch was officially branched off from `master` on **November 24, 2026**, and beta/release channels are now being built by Hydra.
* **Final Freeze & Zero Hydra Failures (ZHF):** Between now and November 30, only backported bugfixes and release-blocker patches are landing in `release-26.11` as maintainers wrap up the Zero Hydra Failures campaign and release notes.
* **Support Window:** Once released on November 30, 2026, NixOS 26.11 will receive bugfixes and security updates for seven months (through the end of June 2027), while NixOS 26.05 ("Yarara") will reach end-of-life around December 31, 2026.

The official release schedule, branch-off status, and target November 30, 2026 release date for NixOS 26.11 ("Zokor") are tracked in the following official GitHub and NixOS Discourse threads:

GitHub Release Schedule Tracking Issue (Canonical Calendar): https://github.com/NixOS/nixpkgs/issues/567567

NixOS Discourse Release Announcement & Status Thread: https://discourse.nixos.org/t/let-s-have-a-great-26-11-release-cycle/80323

Zero Hydra Failures (ZHF) Tracking Issue: https://github.com/NixOS/nixpkgs/issues/584347

Feature Freeze & Release Blockers Issue: https://github.com/NixOS/nixpkgs/issues/567960

NixOS Channel Status Page (to monitor nixos-26.11 channel updates): https://channels.nixos.org/
