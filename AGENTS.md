## 🤖 Agent Instructions: Guiding OpenCode Best Practices

This document serves as a compact set of high-signal knowledge to help AI agents navigate the repository effectively, minimizing guesswork and accelerating development time in this codebase.{
    `
### 🔎 Investigation Strategy (Highest Value First)
Agents must prioritize reading sources that define structure and execution flow:
*   **Metadata & Config:** `README*`, root manifests, workspace configs, lockfiles, build/test/lint/formatter/typecheck/codegen configs.
*   **Automation Plumbing:** CI workflows (`.github/...`), pre-commit hooks, and task runner configurations.
*   **Existing Guides:** Review other instruction files (`AGENTS.md`, `CLAUDE.md`, `.cursor/rules/*`, etc.) for conflicting or confirming guidance.

If documentation conflicts with actual build configs or scripts, **trust the executable source of truth.**

### 🎯 What to Extract (Signals)
Focus on facts that define *how* the system actually works, not just what it's *supposed* to work:
1.  **Commands:** Exact developer commands, especially non-obvious ones (e.g., build variants, specialized CLI flags).
2.  **Execution Order:** Required sequence for complex steps (e.g., `lint -> typecheck -> test`).
3.  **Boundaries:** Monorepo/multi-package ownership, definitive app/library entrypoints.
4.  **Quirks & Flow:** Framework-specific needs: generated code handling, migration patterns, build artifact locations, special environment loading, or dev server startup commands.
5.  **Testing Setup:** Details on fixtures, prerequisites for integration tests, snapshot workflows, etc.

### 🛠️ Writing Rules (Inclusion/Exclusion)
**INCLUDE (High Signal):**
*   Exact commands and one-off shortcuts the agent would otherwise guess wrong.
*   Architecture notes that are not evident from simple file naming.
*   Workflow conventions that diverge from standard language/framework defaults.
*   Non-obvious setup requirements or environment operation gotchas.

**EXCLUDE (Low Signal):**
*   Generic advice on programming practices.
*   Long tutorials or exhaustive directory listings.
*   Obvious language features or common build tool flags.
*   Speculative claims; only document what is verifiable via config/scripts.

### ❓ When to Ask Questions
Only query the user if the repo *cannot* clarify a critical process gap:
*   Undocumented team conventions (e.g., branching policy, PR requirements).
*   Missing test prerequisites known externally but undocumented in source control.

---
**Priority:** This guide is meant to be lean and actionable. If we spent more time on this, the codebase itself would likely need modification or better documentation elsewhere. "When in doubt, omit."`**