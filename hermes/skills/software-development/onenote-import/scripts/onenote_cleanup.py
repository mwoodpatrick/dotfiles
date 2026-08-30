#!/usr/bin/env python3
"""
Cleanup script for OneNote → Markdown exports from onenote-md-exporter.

Preserves the original file as <name>.original.md and writes the cleaned
version to <name>.md.

What it does:
- Strips inline HTML <span> tags, keeping only their inner text.
- Removes empty links (link text that is only HTML/whitespace).
- Deduplicates consecutive identical URLs inside markdown links.
- Normalizes line endings to LF.
- Trims trailing whitespace.
- Removes excessive blank lines (max 2 consecutive).
- Escapes shell examples like '$ ' that could be mis-rendered.

Usage:
    python3 onenote_cleanup.py onenote/notes/zsh.md
"""

import argparse
import re
import sys
from pathlib import Path


def strip_span_tags(text: str) -> str:
    """Remove <span style='...'>...</span>, keeping inner text."""
    return re.sub(r"<span[^>]*>(.*?)</span>", r"\1", text, flags=re.DOTALL)


def clean_inline_html(text: str) -> str:
    """Strip remaining inline HTML tags commonly produced by OneNote/pandoc."""
    # Remove <a> tags that have no href and no content (or only spans that we already stripped)
    # Keep markdown links intact.
    text = re.sub(r"</?a>(?!\s*\()", "", text)
    # Remove other inline formatting tags
    for tag in ("em", "strong", "b", "i", "u", "strike", "s", "code"):
        text = re.sub(rf"</?{tag}[^>]*>", "", text)
    return text


def dedupe_consecutive_links(text: str) -> str:
    """
    Remove repeated identical bare URLs like [foo](url)[bar](url) where the
    second link adds no value (common OneNote footnote reference pattern).
    """
    pattern = re.compile(
        r"(\[([^\]]+)\]\((https?://[^)]+)\))"
        r"((?:\[[^\]]*\]\(\3\))+)",
    )

    def repl(match):
        first = match.group(1)
        rest = match.group(4)
        # Keep the first link, drop the trailing duplicate URL references if they
        # are just numeric/empty footnote markers.
        if re.fullmatch(r"(?:\[\s*\d+\s*\]\([^)]+\))+", rest):
            return first
        return match.group(0)

    return pattern.sub(repl, text)


def remove_empty_bare_links(text: str) -> str:
    """Remove markdown links whose display text is empty/only whitespace."""
    return re.sub(r"\[\s*\]\([^)]+\)", "", text)


def normalize_shell_examples(text: str) -> str:
    r"""
    Lines starting with a literal ``\$`` were escaped by the exporter; remove the
    backslash so shell commands render as code.
    """
    return re.sub(r"(?m)^\\\$ ", r"$ ", text)


def collapse_blank_lines(text: str) -> str:
    """Reduce runs of more than two blank lines to two."""
    return re.sub(r"\n{3,}", "\n\n", text)


def cleanup(text: str) -> str:
    text = strip_span_tags(text)
    text = clean_inline_html(text)
    text = dedupe_consecutive_links(text)
    text = remove_empty_bare_links(text)
    text = normalize_shell_examples(text)
    # Normalize line endings and trim trailing whitespace per line
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = "\n".join(line.rstrip() for line in text.split("\n"))
    text = collapse_blank_lines(text)
    return text.rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Clean up onenote-md-exporter markdown output."
    )
    parser.add_argument("path", help="Markdown file to clean")
    parser.add_argument(
        "--no-backup",
        action="store_true",
        help="Do not write an .original.md backup",
    )
    args = parser.parse_args()

    src = Path(args.path)
    if not src.exists():
        print(f"ERROR: file not found: {src}", file=sys.stderr)
        return 1

    original = src.read_text(encoding="utf-8")
    cleaned = cleanup(original)

    if not args.no_backup:
        backup = src.with_suffix(".original" + src.suffix)
        backup.write_text(original, encoding="utf-8")
        print(f"Wrote backup: {backup}")

    src.write_text(cleaned, encoding="utf-8", newline="\n")
    print(f"Wrote cleaned: {src}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
