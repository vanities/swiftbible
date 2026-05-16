#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# ///
"""Search Matt Bassford's archive for posts matching a query.

Ranks by total query-term frequency. Returns title, filename, score, and a
snippet centered on the first match.

Usage:
    python3 search.py "second coming"
    python3 search.py "hope" --label Sermons --top 10
    python3 search.py "ALS grace" --since 2021 --top 5
    python3 search.py "heaven" --until 2017 --top 3
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


# Resolve archive path: this script lives at
# skills/matt-bassford/scripts/search.py — walk up four parents to
# the repo root, then descend into speakers/matt-bassford/posts.
ARCHIVE = (
    Path(__file__).resolve().parent.parent.parent.parent.parent
    / "speakers"
    / "matt-bassford"
    / "posts"
)


def score_post(content: str, terms: list[str]) -> int:
    text_lower = content.lower()
    return sum(text_lower.count(term.lower()) for term in terms)


def extract_snippet(content: str, terms: list[str], width: int = 240) -> str:
    text_lower = content.lower()
    best_pos = -1
    for term in terms:
        pos = text_lower.find(term.lower())
        if pos >= 0 and (best_pos < 0 or pos < best_pos):
            best_pos = pos
    if best_pos < 0:
        snippet = content[:width]
    else:
        start = max(0, best_pos - 60)
        end = min(len(content), best_pos + width - 60)
        snippet = content[start:end]
        if start > 0:
            snippet = "..." + snippet
        if end < len(content):
            snippet = snippet + "..."
    return re.sub(r"\s+", " ", snippet).strip()


def parse_frontmatter_labels(content: str) -> list[str]:
    match = re.search(r"^labels:\s*\[(.*?)\]", content, re.MULTILINE)
    if not match:
        return []
    raw = match.group(1)
    return [label.strip().strip('"').strip("'") for label in raw.split(",") if label.strip()]


def parse_frontmatter_title(content: str) -> str:
    match = re.search(r'^title:\s*"(.*?)"', content, re.MULTILINE)
    return match.group(1) if match else "(untitled)"


def strip_frontmatter(content: str) -> str:
    if content.startswith("---"):
        end = content.find("\n---", 3)
        if end > 0:
            return content[end + 4 :]
    return content


def main() -> int:
    parser = argparse.ArgumentParser(description="Search Matt Bassford's archive")
    parser.add_argument("query", help="Search terms (space-separated; OR semantics)")
    parser.add_argument("--top", type=int, default=5, help="Max results (default 5)")
    parser.add_argument(
        "--label",
        help="Filter by label: Sermons, Meditations, 'Bulletin Articles', "
        "'Bible Reviews', Hymns, 'Hymn Theory', 'Studies in Character'",
    )
    parser.add_argument("--since", help="Filter posts on/after YYYY[-MM[-DD]]")
    parser.add_argument("--until", help="Filter posts on/before YYYY[-MM[-DD]]")
    args = parser.parse_args()

    if not ARCHIVE.exists():
        print(
            f"Archive not found at {ARCHIVE}\n"
            "Expected the SwiftBible repo with speakers/matt-bassford/posts/.",
            file=sys.stderr,
        )
        return 1

    terms = args.query.split()
    if not terms:
        print("No query terms provided.", file=sys.stderr)
        return 1

    results = []
    for path in sorted(ARCHIVE.glob("*.md")):
        date_str = path.name[:10]
        if args.since and date_str < args.since:
            continue
        if args.until and date_str > args.until:
            continue

        content = path.read_text(encoding="utf-8", errors="replace")

        if args.label:
            labels = parse_frontmatter_labels(content)
            if not any(args.label.lower() == lbl.lower() for lbl in labels):
                continue

        body = strip_frontmatter(content)
        score = score_post(body, terms)
        if score > 0:
            results.append((score, path, content, body))

    if not results:
        print(f"No matches for {args.query!r}.", file=sys.stderr)
        return 0

    results.sort(key=lambda r: -r[0])
    shown = results[: args.top]

    label_filter = f" --label {args.label!r}" if args.label else ""
    range_filter = ""
    if args.since:
        range_filter += f" since {args.since}"
    if args.until:
        range_filter += f" until {args.until}"
    print(
        f"Top {len(shown)} of {len(results)} matches for {args.query!r}"
        f"{label_filter}{range_filter}:\n"
    )
    for score, path, content, body in shown:
        title = parse_frontmatter_title(content)
        snippet = extract_snippet(body, terms)
        print(f"  [{score}] {path.name}")
        print(f"        {title}")
        print(f"        {snippet}")
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
