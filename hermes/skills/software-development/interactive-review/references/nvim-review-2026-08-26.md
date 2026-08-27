# Interactive Review Example: Neovim Config

Real findings from reviewing `/mnt/wsl/projects/git/dotfiles/nvim` on 2026-08-26.
Use as a reference for the shape and prioritization of interactive review issues.

## Issue 1: Duplicated config blocks

- **File:** `init.lua` and `lua/config/{options,keymaps}.lua`
- **Finding:** Options and keymaps were inline in `init.lua` and also duplicated in `lua/config/` files, which were never required.
- **Fix:** Replace the inline blocks with `require 'config.options'` / `require 'config.keymaps'`.

## Issue 2: Wrong LSP server binaries

- **File:** `lua/plugins/lsp.lua`
- **Finding:** `cssls` and `htmlls` were both using `vscode-json-language-server`.
- **Fix:** Use `vscode-css-language-server` for CSS and `vscode-html-language-server` for HTML.

## Issue 3: Keymap defined inside function body

- **File:** `lua/plugins/ui.lua`
- **Finding:** `open_ranger()` originally contained `vim.keymap.set('n', '<leader>r', open_ranger, ...)` inside itself, which would redefine the mapping on every call.
- **Fix:** Move the keymap outside the function.

## Issue 4: Installed plugin never configured

- **File:** `lua/plugins/dap.lua`
- **Finding:** `nvim-dap-ui` was added but `require('dapui').setup()` was never called and no keymap toggled it.
- **Fix:** Call `dapui.setup()`, auto open/close on DAP events, and add `<leader>du` toggle.

## Issue 5: Misleading plugin loader error

- **File:** `lua/plugins/init.lua`
- **Finding:** The loader printed "loading plugin X failed" even when `require` succeeded but the module returned a non-function table.
- **Fix:** Distinguish "skipped: module did not return a function" from actual load errors.

## Issue 6: Legacy API usage

- **File:** `lua/plugins/treesitter.lua`
- **Finding:** Mixed new `nvim-treesitter` API with old `nvim-treesitter.configs.setup()`, which is gone in the `main` branch.
- **Fix:** Remove the legacy `configs.setup` block.

## Issue 7: Dead / leftover commented-out blocks

- **File:** `init.lua`
- **Finding:** Large commented-out `FileType` autocommand for JSON LSP attachment and a leftover Kickstart "next steps" block.
- **Fix:** Remove both dead blocks to reduce noise.

## Issue 8: Empty NixOS branches

- **File:** `lua/plugins/lsp.lua`
- **Finding:** `if is_nixos then -- empty -- else ... end` made the control flow noisy.
- **Fix:** Invert to `if not is_nixos then ... end`.

## Issue 9: Placeholder API key in unused adapter

- **File:** `lua/plugins/codecompanion.lua`
- **Finding:** `openai` adapter contained `env = { api_key = 'YOUR_API_KEY' }` but Ollama was used everywhere.
- **Fix:** Remove the unused `openai` adapter block.

## Issue 10: Experimental/private API without warning

- **File:** `lua/plugins/ui.lua`
- **Finding:** `require('vim._core.ui2').enable` is an internal Neovim API.
- **Fix:** Add a warning comment that it may break on Neovim updates.

## Issue 11: Unconditionally loaded local plugin

- **File:** `lua/plugins/example.lua` / `lua/plugins/init.lua`
- **Finding:** `plugins.example` was in the active loader but the expected package at `~/.local/share/nvim/site/pack/core/start/example.nvim` did not exist, causing a startup warning.
- **Fix:** Symlink the local `example.nvim` repo into the expected pack directory.

## Issue 12: Global notification routing in the wrong file

- **File:** `lua/plugins/lsp.lua` / `lua/plugins/snacks.lua`
- **Finding:** `vim.notify = require('snacks').notifier` was set inside LSP config, coupling it to snacks load order.
- **Fix:** Move the override to `snacks.lua`, immediately after `snacks.setup()`.

## Issue 13: Experimental API without warning

- **File:** `lua/plugins/ui.lua`
- **Finding:** `require('vim._core.ui2').enable` is an internal Neovim API.
- **Fix:** Add a `WARNING` comment above the call noting it may break on future Neovim updates.

## Verification commands used

- `luac -p <file>` for Lua syntax checks.
- `find lua -name '*.lua' -print0 | xargs -0 -n1 luac -p` for batch syntax checks.
- `cat`/`wc` to verify extracted config files were not empty or stale before relying on them.
- `git diff --stat` to summarize the review outcome.
