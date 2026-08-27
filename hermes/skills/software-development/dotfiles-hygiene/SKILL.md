---
name: dotfiles-hygiene
description: "Clean untracked state in a personal dotfiles repo."
version: 0.1.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [dotfiles, git, gitignore, cleanup, hygiene, untracked]
    related_skills: [interactive-review, hermes-agent, obsidian]
---

# Dotfiles Repository Hygiene

## Overview

A personal dotfiles repository tends to accumulate untracked directories that blur the line between "source I want to version" and "runtime state that should stay local." This skill provides a structured, interactive review workflow for cleaning that state without accidentally deleting real config or committing caches, secrets, or ephemeral artifacts.

## When to Use

- `git status` shows many `??` untracked entries and the user asks to "review" or "clean up" the repo.
- You need to decide whether a new directory is runtime state or intentional source.
- You are updating `.gitignore` for AI tooling, editor state, or messaging-gateway caches.
- A nested `.gitignore` is ignoring files the user might actually want committed.

## When Not to Use

- The user already knows exactly what to ignore or delete — just apply their instruction.
- The repo is not a personal dotfiles/config repo (use `github-code-review` or `requesting-code-review` for project code).

## Procedure

1. **Start with `git status --short` and `git log --oneline -5`.** Establish what is currently modified, deleted, and untracked. This is the menu of issues.

2. **Group items by risk and category.** Typical groups:
   - **Backup/safety copies:** `*.bak`, `*.sv`, `*.backup`, `*~`
   - **AI tool artifacts:** `.aider*`, `.opencode/`, OpenCode/Opencode local packages
   - **Editor/runtime state:** `.obsidian/workspace*`, `obsidian/` (Electron profile data), `.vscode/`, `vscode/`, `pulse/`
   - **Agent runtime state:** `hermes/` caches, `hermes/lsp/`, `hermes/memories/`, `hermes/.curator_backups/`, `hermes/pastes/`, `hermes/verification_evidence.db`
   - **Nix flake artifacts:** `flake.lock` updates, `result`, `result-*`
   - **Real source to keep:** new skill directories, config files, Docker setups, install scripts

3. **Review one issue at a time.** Present:
   - What the item is.
   - Why it is likely runtime state or source.
   - Options: delete, ignore, keep/commit, inspect contents first.
   - A recommended default (option 1).

4. **Act on the user's terse choice.** This user often replies with just `1`, `a`, `c`, or `y`. Retain the option list in context and execute immediately.

5. **When in doubt, inspect before deleting.** Use `ls -la`, `find`, and `read_file` to confirm a directory is not live config before `rm -rf`.

6. **After deletions and `.gitignore` edits, verify with `git status --short`**. Only the intended items should remain.

## Common Classifications

| Pattern | Usually | Action |
|---------|---------|--------|
| `*.bak`, `*.sv`, `*.backup` | Local safety copy | Delete or ignore |
| `.aider*` | Aider session state | Ignore and delete local copies |
| `.obsidian/app.json`, `appearance.json`, `core-plugins.json` | Obsidian config to share | Keep/commit |
| `.obsidian/workspace.json`, `workspace-mobile.json`, `*.log`, `plugins/`, `themes/`, `snippets/` | Machine/session-specific state | Ignore |
| `obsidian/` (separate sibling directory) | Electron/Chromium profile data (Cache, Cookies, IndexedDB, GPUCache) | Ignore/delete |
| `vscode/`, `.vscode/` | VS Code runtime state and extensions | Ignore (unless tracking curated settings intentionally) |
| `pulse/` | PulseAudio runtime cookie/state | Ignore |
| `hermes/lsp/` | Hermes Agent's bundled LSP server installation | Ignore (runtime install, not source) |
| `hermes/memories/`, `hermes/pastes/`, `hermes/.curator_backups/`, `hermes/verification_evidence.db` | Hermes runtime state | Ignore |
| `opencode/opencode.jsonc` | OpenCode user config | Keep/commit |
| `opencode/package.json`, `package-lock.json`, `node_modules/` | OpenCode ephemeral/generated artifacts | Ignore (OpenCode itself often lists these in its internal `.gitignore`) |

## Pitfalls

- **Deleting a directory that is actually a live profile/home directory.** Before `rm -rf`, check `ls -la`. If it contains `.env`, `auth.json`, `state.db`, model caches, or a full `skills/` tree, it is a working profile, not a backup. Names like `hermes.sv` or `foo.bak` are not enough to classify something as disposable.
- **Assuming a sibling directory with a dot prefix is the same as one without.** `.obsidian/` (Obsidian vault config) and `obsidian/` (Electron user-data dump) are different; classify them separately.
- **Ignoring a nested `.gitignore` surprise.** A tool like OpenCode may ship an internal `.gitignore` that ignores `package.json`. If the user wants that file committed, the nested `.gitignore` is the blocker, not the root one. Ask whether to change the nested file or accept the tool's default.
- **Treating `package-lock.json` as always source.** In dotfiles, lockfiles are often generated artifacts. Ask whether exact versions are pinned in `package.json` instead of committing the lockfile.
- **Forgetting executable bits.** Scripts like `build.sh`, `entrypoint.sh`, `webtop.bash` need `chmod +x` after write.
- **Committing hardcoded secrets.** When reviewing Dockerfiles, replace hardcoded passwords with runtime env vars and an entrypoint script.
- **Missing Nix deprecation renames.** A rebuild warning like "'system' has been renamed to/replaced by 'stdenv.hostPlatform.system'" means a module is reading `pkgs.system`. Replace it with `pkgs.stdenv.hostPlatform.system` before committing.

## Verification

- After each deletion/ignore edit, run `git status --short`.
- After writing shell scripts, run `chmod +x` and a dry-run check if possible.
- Before the final commit, run `git diff --cached --stat` and confirm no generated artifacts are staged.

## References

- `references/obsidian-state-classification.md` — how to split `.obsidian/` config from `obsidian/` runtime data.
- `references/nested-gitignore-decision.md` — handling tools that ignore their own source files.
- `references/nix-deprecation-fixes.md` — common Nix attribute renames encountered while maintaining this dotfiles flake.
