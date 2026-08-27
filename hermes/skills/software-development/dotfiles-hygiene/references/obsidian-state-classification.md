# Obsidian State Classification

When Obsidian is used to browse a dotfiles repo, two kinds of directories can appear. Classify them separately.

## `.obsidian/` — Vault configuration

Located at the root of the vault (i.e., the repo root), this is Obsidian's own configuration directory.

### Files to keep/commit

- `app.json` — general app settings (usually empty or minimal).
- `appearance.json` — theme/appearance settings.
- `core-plugins.json` — which core plugins are enabled.
- `hotkeys.json` — custom hotkeys (if you want them shared).

### Files/directories to ignore

- `workspace.json`, `workspace-mobile.json` — current UI layout and last-open files; machine/session-specific.
- `*.log` — runtime logs.
- `plugins/` — community plugins; usually large and machine-managed.
- `themes/` — downloaded themes; large and reproducible.
- `snippets/` — optional; commit only if you authored custom CSS snippets.

## `obsidian/` (without leading dot) — Electron profile data

A sibling directory named `obsidian/` is usually an Electron/Chromium user-data directory created by running Obsidian with `--user-data-dir=obsidian/` or by an install that placed profile data next to the vault.

It contains runtime-only artifacts:

- `Cache/`, `Code Cache/`, `GPUCache/` — browser caches.
- `Cookies`, `Cookies-journal` — session cookies.
- `IndexedDB/`, `Local Storage/`, `Session Storage/` — local databases.
- `Crashpad/`, `Dawn*Cache/`, `Shared Dictionary/` — runtime telemetry/crash data.

**Action:** ignore the entire directory and delete the local copy.

## Typical `.gitignore` snippet

```gitignore
# Obsidian vault config — keep core files, ignore session/runtime state
.obsidian/workspace*
.obsidian/cache/
.obsidian/*.log
.obsidian/plugins/
.obsidian/themes/
.obsidian/snippets/
.obsidian/hotkeys.json
.obsidian/backlink.json
.obsidian/community-plugins.json
.obsidian/graph.json
.obsidian/types.json

# Obsidian Electron profile data (if any)
obsidian/
```

## Verification

After editing `.gitignore`, run:

```bash
git status --short
```

Only `.obsidian/app.json`, `.obsidian/appearance.json`, and `.obsidian/core-plugins.json` (plus any authored snippets) should remain untracked and ready to commit.
