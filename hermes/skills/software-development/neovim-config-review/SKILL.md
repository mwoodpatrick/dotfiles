---
name: neovim-config-review
title: Neovim Configuration Review
version: 1.0.0
description: Use when the user asks to review or fix their Neovim config.
trigger: Use when the user asks to review or fix their Neovim config.
---

# Neovim Configuration Review

Review, explain, and repair Neovim Lua configurations, especially Kickstart-derived or `vim.pack`-based setups.

## 1. Gather context first

Before changing anything, read the high-signal files in this order:

1. `nvim/init.lua` — entry point, plugin manager, leader/options/keymaps.
2. `nvim/lua/plugins/init.lua` or equivalent modular loader.
3. Every `nvim/lua/plugins/*.lua` file referenced by the loader.
4. `nvim/lua/user/utils.lua` or other local helpers.
5. `nvim/nvim-pack-lock.json` if present — confirms pinned plugins.

Also run a quick structural scan:

```bash
cd nvim
find lua -name '*.lua' -print0 | xargs -0 -n1 luac -p
```

This catches syntax errors without needing a running Neovim instance.

## 2. Common issues to look for

### Dead / duplicate code
- Inline options/keymaps duplicated in `lua/config/options.lua` or `lua/config/keymaps.lua` but never `require`d.
- Commented-out autocommand blocks left over from experiments.
- `lua/custom/plugins/init.lua` or similar custom loader that is not wired up.
- Extracted config files that exist on disk but are stale or empty — verify content with `cat`/`wc` rather than trusting a previous `read_file` result.

### Plugin manager mistakes
- With `vim.pack`:
  - `vim.pack.add` called inside a returned setup function vs. at module load time.
  - `PackChanged` autocommand missing build hooks for `telescope-fzf-native`, `LuaSnip`, `nvim-treesitter`.
- With `lazy.nvim` (older configs):
  - Plugin specs returning tables vs. functions in unexpected places.

### LSP misconfiguration
- Wrong language-server binary copy-pasted into server configs, e.g.:
  - `cssls` must use `vscode-css-language-server`, not `vscode-json-language-server`.
  - `htmlls` must use `vscode-html-language-server`.
  - `jsonls` correctly uses `vscode-json-language-server`.
- NixOS branch with empty `if is_nixos then ... else ... end` blocks; prefer `if not is_nixos then ... end`.
- LSP servers configured but never enabled via `vim.lsp.enable(name)`.

### Keymap bugs
- `vim.keymap.set` called **inside** a function so it re-registers every invocation.
- Leader-key mappings shadowing built-ins without documentation.
- Same key bound by multiple plugins (e.g. two pickers both on `<leader>ff`).

### Plugin setup missing
- Plugins installed with `vim.pack.add` but `.setup()` never called (e.g. `nvim-dap-ui`).
- Old API fallbacks that no longer exist in the installed version (e.g. `nvim-treesitter.configs.setup` in the rewrite).

### Adapter / AI plugin issues
- Placeholder API keys like `'YOUR_API_KEY'` in adapter configs (e.g. CodeCompanion `openai` adapter). Remove the adapter if unused, or read the key from an environment variable.
- **Missing required dependencies:** Some plugins pull in mandatory dependencies that `vim.pack` will not install automatically. Example: `nvim-dap-ui` requires `nvim-neotest/nvim-nio`; without it `require('dapui')` errors on startup. Add the dependency via `vim.pack.add` and then run `vim.pack.update()` before testing.
- Experimental/private Neovim APIs (`vim._core.ui2`) used without a warning comment; add a warning that they may break on update.
- Unconditionally loaded example/local plugins (e.g. `plugins.example`) that warn on startup when the corresponding package does not exist. Often the fix is to symlink the local repo into the expected `pack/.../start/` path, not to remove the loader entry.
- **Missing required dependencies installed by `vim.pack`.** Some plugins have mandatory runtime dependencies that are not pulled in automatically. Example: `nvim-dap-ui` requires `nvim-neotest/nvim-nio`; without it `require('dapui').setup()` errors on startup. Add the dependency via `vim.pack.add`, run `vim.pack.update()`, and verify with `nvim --headless +qa`.

### Treesitter
- Mixing old `configs.setup` API with new `require('nvim-treesitter').install(...)` API.
- `FileType` autocommand that auto-installs parsers; verify it does not retry forever on failure.

### Machine-specific hardcoded values
Note them for the user but do not change unless asked. Add `FIXME` comments so the values are discoverable on other machines:
- Ollama/model names like `gemma4:12b`.
- Vault paths like `~/obsidian/vaults/personal`.
- Windows/WSL absolute paths like `/mnt/wsl/projects/...`.
- API key placeholders like `'YOUR_API_KEY'`.
- Aider CLI invocations like `aider --model ollama_chat/gemma4`.

## 3. Interactive review workflow

When the user asks to go through issues one at a time:

1. State the issue clearly.
2. Explain why it matters.
3. Offer 2–3 concrete options (including “skip”).
4. Wait for the user's choice.
5. Apply the chosen fix with `patch` or `write_file`.
6. Validate with `luac -p` immediately after the edit.
7. Move to the next issue.

This avoids batch-editing the whole config at once and keeps the user in control.

## 4. Validation commands

- Syntax check all Lua files:
  ```bash
  cd nvim && find lua -name '*.lua' -print0 | xargs -0 -n1 luac -p
  ```
- Syntax check `init.lua`:
  ```bash
  cd nvim && luac -p init.lua
  ```
- Inspect lock file:
  ```bash
  cd nvim && python3 -c "import json; d=json.load(open('nvim-pack-lock.json')); print(len(d.get('plugins', d)), 'entries')"
  ```

## 5. Pitfalls

- `read_file` can return stale/truncated content if the file was read with offset/limit earlier; re-read the whole file before a `write_file` or `patch` if in doubt.
- `patch` may fail on files last read via pagination; use absolute paths and re-read if the tool warns about it.
- **Extracted config files may be empty or stale on disk.** When moving code from `init.lua` into `lua/config/options.lua` or `lua/config/keymaps.lua`, do not assume the target file already contains the same content you saw earlier. Verify with `cat` or `wc -l`, and rewrite with `write_file` if it is empty or truncated.
- Do not assume `lua/config/options.lua` is used just because it exists; verify `init.lua` requires it.
- Do not silently fix machine-specific values (model names, vault paths) without asking.
- When refactoring Kickstart-derived configs, the user often wants to keep Kickstart's educational comments; ask before stripping them.
- **Don't remove a local-plugin loader entry just because the package is missing.** Check whether the local repo exists elsewhere (e.g. under `/mnt/wsl/projects/git/example.nvim`) and symlink it into `~/.local/share/nvim/site/pack/core/start/` before deciding to delete the loader entry.
- **Global notification routing belongs near the plugin that provides it.** For example, `vim.notify = Snacks.notifier` should be set in `snacks.lua` right after `snacks.setup()`, not in LSP or other feature files.

## 6. Related skills

- `interactive-review` — for the interactive one-issue-at-a-time workflow.
- `hermes-agent` — for Hermes-specific setup questions.
- `systematic-debugging` — if a Neovim runtime bug needs deeper root-cause analysis.

## 7. Note on overlap

This skill and `interactive-review` overlap when reviewing Neovim configs interactively. Prefer `interactive-review` for the workflow mechanics (how to present options one-by-one), and `neovim-config-review` for the domain-specific checklist (what to look for in a Neovim config). They may be consolidated in the future.
