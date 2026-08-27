# Nested .gitignore Decisions

Some tools (e.g., OpenCode) ship an internal `.gitignore` in their working directory that ignores files you might actually want to version in your dotfiles repo. This reference shows how to recognize and handle the situation.

## The symptom

You run `git add -A` or `git status`, but a file you expect to be staged is missing. `git check-ignore -v <path>` reports a match inside a nested directory.

Example with OpenCode:

```bash
git check-ignore -v opencode/package.json
# opencode/.gitignore:2:package.json    opencode/package.json
```

## How to decide

Ask the user which model applies:

1. **Tool-generated runtime artifact.** The file is recreated automatically and is not meaningful source.
   - Example: OpenCode treats `package.json` as an ephemeral runtime artifact.
   - Action: leave the nested `.gitignore` unchanged; do not force-add.

2. **User-authored source the tool happens to ignore.** You edited the file meaningfully and want it tracked.
   - Example: a custom `package.json` you wrote for a local tool setup.
   - Action: edit or remove the relevant line in the nested `.gitignore`, then stage normally.

## Do not force-add blindly

Using `git add -f` bypasses the `.gitignore` but does not fix the underlying policy. Future edits will still be silently excluded from staging. Prefer changing the `.gitignore` rule when the file is real source.

## Checking whether a file is ignored

```bash
git check-ignore -v path/to/file
```

If the command prints nothing, the file is not ignored.

## Typical root `.gitignore` additions

For OpenCode specifically, add generated artifacts to the root `.gitignore` rather than editing the tool's internal file:

```gitignore
# Opencode local artifacts
opencode/node_modules/
opencode/package-lock.json
```

Keep `opencode/opencode.jsonc` as committed user config.

## Verification

After deciding, run:

```bash
git status --short
```

Confirm that the intended source files are staged/tracked and generated artifacts are not.
