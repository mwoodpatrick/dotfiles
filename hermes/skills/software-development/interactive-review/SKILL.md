---
name: interactive-review
description: "Review config or code one issue at a time, interactively."
version: 0.1.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [review, workflow, config, code-quality]
    related_skills: [requesting-code-review, simplify-code, systematic-debugging]
---

# Interactive Review Skill

## Overview

A disciplined, user-driven review workflow: identify issues, present them one at a time, explain why each matters, offer numbered options, and apply the chosen fix before moving on. This prevents review fatigue, keeps the user in control, and surfaces false positives before edits are made.

## When to Use

- User asks you to "review files" or "review this config" without a single obvious fix.
- The target is a personal dotfile, editor config, or small codebase where user preferences dominate correctness.
- Multiple independent issues exist and the user may want to skip or rethink some.
- You would otherwise produce a long bulleted list of findings and apply patches wholesale.

## When Not to Use

- A single clear bug with one obvious fix — just fix it and report.
- An automated pass (lint, format, security scan) — use `requesting-code-review` or run the tool directly.
- The user explicitly asked you to "just fix everything" without review.

## Procedure

1. **Survey the target.** Use `read_file`, `search_files`, and quick syntax checks (`luac -p`, `python -m py_compile`, etc.) to identify concrete issues. Aim for 3–10 high-signal findings. Stop at ~10 unless the user wants more.

2. **Prioritize.** Lead with correctness bugs, then performance/leaks, then style/organization, then portability/maintainability. Do not bury the first real bug under formatting notes.

3. **Present one issue.** State:
   - The exact file and line(s).
   - What you found.
   - Why it matters (impact on behavior, performance, or future maintenance).
   - Numbered options, with option 1 as the recommended default.

4. **Wait for the user's choice.** Do not apply the fix until they pick an option.

   - **Terse choices:** The user may reply with only the option token (e.g., `1`, `a`, `c`). Retain the option list in your own context and act immediately on their selection. Do not re-ask for confirmation.

5. **Apply the chosen fix.** Use `patch` or `write_file`. Run a focused syntax/build check immediately after.

6. **Confirm.** Report the change and its verification result.

7. **Repeat** with the next issue, or ask if the user wants to stop after fatigue signals ("that's enough", "move on").

## Presentation Template

```
## Issue N: <short title>

**What I found:** <file:line> …

**Why it matters:** …

**Options:**
1. <recommended fix>
2. <alternative>
3. Skip for now.

Which would you prefer?
```

## Pitfalls

- **Over-listing.** A dump of 15 issues with no prioritization overwhelms the user and hides the bugs.
- **Applying without asking.** The interactive workflow exists because preferences and intent vary. Even obvious-looking fixes can be wrong for the user's setup.
- **Skipping verification.** After each edit, re-run the relevant syntax check or build command so bad edits are caught immediately, not at the end.
- **Vague impact.** "This is bad practice" is not actionable. Tie the issue to a concrete failure mode.
- **Dead files as style issues.** If a file is unused and duplicated, treat it as a separate issue (delete vs. wire up) rather than ignoring it.
- **Trusting extracted files without verifying them on disk.** When moving code from a large file into a dedicated module, the target file may already exist with stale or empty content that does not match what you saw in a previous truncated `read_file`. Always re-read the whole file or use `cat`/`wc` before relying on it as the new source of truth.
- **Forgetting to validate immediately after each edit.** Run `luac -p`, `python -m py_compile`, or the relevant syntax check right after applying a fix, not just at the end of the session.
- **Assuming a local plugin package exists.** If a config references a local plugin path (e.g. `~/.local/share/nvim/site/pack/core/start/example.nvim`), verify it exists before deciding the loader is wrong; often the fix is to symlink the local repo, not remove the loader.
- **Moving `vim.notify` overrides into unrelated files.** Global notification routing belongs near the plugin that provides it (e.g. `snacks.lua`), not in LSP or other feature files.
- **Leaving experimental/private API calls uncommented.** APIs like `vim._core.ui2` should carry a warning that they can break on Neovim updates.

## Verification

- Each applied change is followed by a targeted check (`luac -p`, `python -m py_compile`, `git diff --stat`, or the project's test/lint command).
- User confirms whether to continue, stop, or backtrack.

## Reference Examples

- `references/nvim-review-2026-08-26.md` — concrete findings and fixes from a real interactive review of a Neovim config.
