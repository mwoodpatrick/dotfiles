#!/usr/bin/env python3
"""
Hermes tool script: postprocess OneNote manual exports into clean Markdown.

OneNote desktop only supports whole-notebook export as a folder of .mht files
(File → Export → Notebook → Single File Web Page (*.mht)). This script parses that
folder, extracts each .mht MIME archive into a page directory, converts the page
HTML to Markdown with pandoc, extracts embedded resources, and runs the cleanup
script so the raw export is preserved as <name>.original.md.

This is invoked by the onenote-import skill; it is not meant to be run by hand.
"""

from __future__ import annotations

import argparse
import base64
import email
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any


def require_dir(path: Path) -> None:
    if not path.exists():
        print(f"ERROR: directory not found: {path}", file=sys.stderr)
        sys.exit(1)
    if not path.is_dir():
        print(f"ERROR: not a directory: {path}", file=sys.stderr)
        sys.exit(1)


def require_command(name: str) -> None:
    if shutil.which(name) is None:
        print(f"ERROR: command not found on PATH: {name}", file=sys.stderr)
        sys.exit(1)


def sanitize_path(name: str) -> str:
    safe = re.sub(r"[^\w\s-]", "_", name).strip().replace(" ", "_")
    safe = re.sub(r"_+", "_", safe)
    return safe or "untitled"


def parse_mht_file(mht_path: Path) -> tuple[str, dict[str, bytes]]:
    """
    Parse a OneNote-exported .mht file and return (html_text, cid_to_data).

    OneNote MHT uses Content-Location as the part identifier for the main HTML,
    and Content-ID or Content-Location for embedded resources.
    """
    text = mht_path.read_text(encoding="utf-8", errors="replace")
    # email.message_from_string handles MIME-style multipart structure
    msg = email.message_from_string(text)

    html_text = ""
    cid_to_data: dict[str, bytes] = {}

    # Walk through MIME parts
    for part in msg.walk():
        if part.get_content_type() == "multipart/related":
            continue

        content_location = part.get("Content-Location", "")
        content_id = part.get("Content-ID", "")
        payload = part.get_payload(decode=True) or b""

        # The first HTML part is typically the page body.
        if part.get_content_type() == "text/html" and not html_text:
            charset = part.get_content_charset() or "utf-8"
            try:
                html_text = payload.decode(charset, errors="replace")
            except LookupError:
                html_text = payload.decode("utf-8", errors="replace")

        # Index embedded resources by Content-ID or Content-Location.
        if content_id:
            key = content_id.lstrip("").rstrip("").strip()
            if key.startswith("cid:"):
                key = key[4:]
            cid_to_data[key] = payload
        elif content_location:
            cid_to_data[content_location] = payload

    return html_text, cid_to_data


def rewrite_resource_links(html: str, cid_to_data: dict[str, bytes], dest_dir: Path) -> str:
    """Replace cid: URLs and data URIs with local relative file paths."""
    # Handle cid:<name> references
    def cid_repl(match: Any) -> str:
        prefix = match.group(1)  # 'src=' or 'url('
        quote_char = match.group(2)
        cid = match.group(3)

        data = cid_to_data.get(cid) or cid_to_data.get(cid.lower())
        if not data:
            return match.group(0)

        ext = resource_ext(cid, data)
        local_name = sanitize_path(cid) + ext
        local_path = dest_dir / local_name
        local_path.write_bytes(data)
        return f"{prefix}{quote_char}{local_name}{quote_char}"

    html = re.sub(
        r"(?i)(src=|url\()([\"\']?)(cid:)([^\"\'>\)]+)\2",
        cid_repl,
        html,
    )

    # Handle inline data URIs
    def data_uri_repl(match: Any) -> str:
        prefix = match.group(1)
        quote_char = match.group(2)
        media_type = match.group(3)
        b64 = match.group(4)
        try:
            data = base64.b64decode(b64)
        except Exception:
            return match.group(0)
        ext = media_ext(media_type)
        local_name = f"resource_{hash(data) % 1000000:06d}{ext}"
        local_path = dest_dir / local_name
        local_path.write_bytes(data)
        return f"{prefix}{quote_char}{local_name}{quote_char}"

    html = re.sub(
        r"(?i)(src=|url\()([\"\']?)data:([^;]+);base64,([^\"\'>\)]+)\2",
        data_uri_repl,
        html,
    )

    return html


def resource_ext(name: str, data: bytes) -> str:
    """Best-effort extension for an embedded resource."""
    lowered = name.lower()
    if any(ext in lowered for ext in [".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp", ".svg"]):
        for e in [".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp", ".svg"]:
            if e in lowered:
                return e
    if lowered.endswith(".css"):
        return ".css"
    if data[:4] == b"\x89PNG":
        return ".png"
    if data[:2] == b"\xff\xd8":
        return ".jpg"
    if data[:4] == b"GIF8":
        return ".gif"
    return ".bin"


def media_ext(media_type: str) -> str:
    mapping = {
        "image/png": ".png",
        "image/jpeg": ".jpg",
        "image/gif": ".gif",
        "image/svg+xml": ".svg",
        "image/webp": ".webp",
        "text/css": ".css",
    }
    return mapping.get(media_type.lower().split(";")[0].strip(), ".bin")


def pandoc_html_to_markdown(html: str) -> str:
    """Convert HTML to Markdown via NixOS pandoc."""
    result = subprocess.run(
        [
            "pandoc",
            "-f",
            "html",
            "-t",
            "markdown_strict+backtick_code_blocks",
            "--wrap=none",
        ],
        input=html,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(f"pandoc failed: {result.stderr}")
    return result.stdout


def run_cleanup(md_path: Path) -> None:
    """Run the skill's native cleanup script preserving the original."""
    cleanup_script = Path(__file__).with_name("onenote_cleanup.py")
    if not cleanup_script.exists():
        raise FileNotFoundError(f"cleanup script not found: {cleanup_script}")
    subprocess.run([sys.executable, str(cleanup_script), str(md_path)], check=True)


def infer_page_title(html: str, mht_path: Path) -> str:
    """Try to extract a clean page title from HTML meta or filename."""
    match = re.search(r"<title[^>]*>([^\"]+)</title>", html, re.IGNORECASE | re.DOTALL)
    if match:
        title = re.sub(r"[\r\n]+", " ", match.group(1)).strip()
        if title:
            return title
    return mht_path.stem


def process_mht(mht_path: Path, output_dir: Path) -> Path | None:
    """Convert a single .mht file to cleaned Markdown + resources."""
    html_text, cid_to_data = parse_mht_file(mht_path)
    if not html_text:
        print(f"WARNING: no HTML content in {mht_path}", file=sys.stderr)
        return None

    title = infer_page_title(html_text, mht_path)
    page_name = sanitize_path(title)

    # OneNote exports usually put the .mht at the top level with a directory of
    # the same name containing the resources next to it. Replicate that layout.
    page_dir = output_dir / page_name
    resource_dir = page_dir / f"{page_name}_files"
    resource_dir.mkdir(parents=True, exist_ok=True)

    html_text = rewrite_resource_links(html_text, cid_to_data, resource_dir)
    markdown = pandoc_html_to_markdown(html_text)

    md_path = page_dir / f"{page_name}.md"
    md_path.write_text(markdown, encoding="utf-8", newline="\n")
    run_cleanup(md_path)
    print(f"Wrote: {md_path}")
    return md_path


def discover_mht_files(input_dir: Path, recursive: bool = True) -> list[Path]:
    """Find .mht or .mhtml files exported by OneNote."""
    if recursive:
        return sorted(input_dir.rglob("*.mht")) + sorted(input_dir.rglob("*.mhtml"))
    return sorted(input_dir.glob("*.mht")) + sorted(input_dir.glob("*.mhtml"))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Postprocess OneNote .mht exports to clean Markdown."
    )
    parser.add_argument(
        "input",
        help="Directory containing .mht files exported from OneNote, or a single .mht file.",
    )
    parser.add_argument("--output", default="onenote/notes", help="Target directory")
    parser.add_argument(
        "--no-resources", action="store_true", help="Skip extracting embedded resources"
    )
    parser.add_argument(
        "--no-recursive", action="store_true", help="Only process .mht files in the top directory"
    )
    args = parser.parse_args()

    require_command("pandoc")

    input_path = Path(args.input)
    output_dir = Path(args.output).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    if input_path.is_file():
        mht_files = [input_path]
    else:
        require_dir(input_path)
        mht_files = discover_mht_files(input_path, recursive=not args.no_recursive)

    if not mht_files:
        print(f"ERROR: no .mht/.mhtml files found in {input_path}", file=sys.stderr)
        return 1

    results: list[Path] = []
    for mht in mht_files:
        exported = process_mht(mht, output_dir)
        if exported:
            results.append(exported)

    summary = {
        "input": str(input_path.resolve()),
        "output_dir": str(output_dir),
        "count": len(results),
        "exported": [str(p.relative_to(output_dir)) for p in results],
    }
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
