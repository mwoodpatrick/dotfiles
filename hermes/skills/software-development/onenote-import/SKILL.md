---
name: onenote-import
description: Postprocess OneNote .mht exports into clean Markdown.
version: 0.3.0
author: Mark Woodpatrick, Hermes Agent
license: MIT
platforms: [linux, windows]
metadata:
  hermes:
    tags: [onenote, markdown, export, migration, dotfiles, mht, pandoc]
    related_skills: []
---

# OneNote Import Skill

Convert OneNote manual exports (`.mht` single-file web pages) into clean
Markdown in the repo. The OneNote desktop app does the export; this skill does
the postprocessing: parse the MIME archive, extract embedded resources,
convert HTML to Markdown with `pandoc`, and clean up the Markdown while
preserving the raw export as `<name>.original.md`.

## When to Use

- User asks to migrate OneNote content to Markdown.
- OneNote desktop can export the target content as `.mht`.
- Target directory is typically `onenote/` or a subdirectory in the repo.

## Don't Use For

- Fully automated unsupervised export (OneNote manual export is required).
- Notebooks stored only in OneNote for Windows 10 / UWP with no desktop export.

## Prerequisites

1. **OneNote desktop** (Office 2016 / 365) on Windows.
2. **NixOS packages**: `pandoc` and Python 3 with `email` stdlib.
   - `pandoc` is already added in `nixos-wsl/nixos/home.nix`.

## How to Run

### Step 1: Export from OneNote desktop

1. Open OneNote and navigate to the notebook, section, or page.
2. Choose **File → Export**.
3. Select the export scope:
   - **Page** — a single page.
   - **Section** — all pages in the section.
   - **Notebook** — the whole notebook.
4. Set file format to **Single File Web Page (*.mht)**.
5. Choose an export location you can reach from WSL, e.g.:
   ```
   C:\Users\<you>\Documents\onenote-exports\
   ```
   For a notebook export, OneNote creates a folder with one `.mht` per page.
6. Note the exported path; you will pass it to the script.

### Step 2: Postprocess in NixOS

Use `terminal` to invoke the skill script:

```bash
cd /mnt/wsl/projects/git/dotfiles
python3 hermes/skills/software-development/onenote-import/scripts/onenote_import.py \
  /mnt/c/Users/\<you>/Documents/onenote-exports/NixOS \
  --output onenote/notes
```

If you exported a single `.mht` file, pass the file path instead of a directory:

```bash
python3 hermes/skills/software-development/onenote-import/scripts/onenote_import.py \
  /mnt/c/Users/\<you>/Documents/onenote-exports/zsh.mht \
  --output onenote/notes
```

## Quick Reference

| Goal | Command |
|------|---------|
| Export a notebook folder | `.../onenote_import.py /mnt/c/.../onenote-exports/NixOS --output onenote/notes` |
| Export a single .mht | `.../onenote_import.py /mnt/c/.../onenote-exports/zsh.mht --output onenote/notes` |
| Skip embedded images/files | add `--no-resources` |
| Only top-level files | add `--no-recursive` |

## Procedure

1. **Resolve the target.** Default to `onenote/notes` if the user does not specify.
2. **Check `pandoc`.** Fail fast if `pandoc` is not on `PATH`.
3. **Discover `.mht` files.** Recursively find all `.mht` / `.mhtml` files in the input directory (or use the single file passed).
4. **Parse each MIME archive.** Use Python's `email` module to split the MHT into the HTML body and embedded resource parts.
5. **Rewrite resource links.** Replace `cid:` references and inline `data:` URIs with local relative paths and write the binary payloads to a `_files` directory, unless `--no-resources` is passed.
6. **Convert HTML to Markdown.** Run `pandoc -f html -t markdown_strict+backtick_code_blocks`.
7. **Clean up each `.md`.** Run `hermes/skills/software-development/onenote-import/scripts/onenote_cleanup.py` on every exported file, preserving the raw version as `<name>.original.md`.
8. **Report.** Print JSON summary with the count and relative paths of exported files.

## Pitfalls

- OneNote notebook export produces a folder of `.mht` files; individual page/section export produces a single `.mht`.
- Section groups are not a distinct export target in OneNote; export the notebook or individual sections.
- `pandoc` HTML → Markdown conversion may not perfectly match OneNote's visual layout.
- The cleanup script overwrites existing `.original.md` backups if re-run.
- Some inline HTML (`<span>`, `<a>`) may remain if the MHT encoding differs from expectations.

## Verification

- Target directory contains `.md` files.
- For each `.md`, a `.original.md` counterpart exists with the raw pandoc output.
- `grep -c '<span'` on cleaned `.md` files returns 0.
- `file <name>.md` reports UTF-8 text with LF line endings.

## Alternatives

For tenants with Microsoft 365 work/school accounts, the Microsoft Graph API
route avoids manual export. See `references/azure-app-registration.md` for
setup. Note that Graph does **not** work with personal Microsoft accounts for
OneNote access.

## Roadmap

- Token caching if the Graph route is re-enabled.
- Better handling of OneNote-specific CSS classes and generated tag markup.
- Option to merge a notebook folder of .mht files into a single Markdown file.
