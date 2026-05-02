#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "httpx",
#   "markdownify",
# ]
# ///
"""Scrape Matt Bassford's blog (hisexcellentword.blogspot.com).

Pulls every post via the Blogger JSON feed, converts HTML to Markdown, and
saves each post as `posts/YYYY-MM-DD-slug.md` with YAML frontmatter. Writes
`index.json` as a manifest sorted newest first.

Usage: uv run speakers/matt-bassford/scrape.py
"""
from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any

import httpx
from markdownify import markdownify

BLOG_URL = "https://hisexcellentword.blogspot.com"
FEED_URL = f"{BLOG_URL}/feeds/posts/default"
PAGE_SIZE = 150  # Blogger silently caps page size at ~150
HERE = Path(__file__).parent
POSTS_DIR = HERE / "posts"
INDEX_PATH = HERE / "index.json"


def fetch_page(client: httpx.Client, start_index: int) -> dict[str, Any]:
    params = {
        "alt": "json",
        "max-results": PAGE_SIZE,
        "start-index": start_index,
    }
    resp = client.get(FEED_URL, params=params, timeout=30)
    resp.raise_for_status()
    return resp.json()


def extract_post(entry: dict[str, Any]) -> dict[str, Any]:
    raw_id = entry["id"]["$t"]
    post_id = raw_id.rsplit(".post-", 1)[-1]

    title = entry.get("title", {}).get("$t", "(untitled)")
    published = entry["published"]["$t"]
    updated = entry["updated"]["$t"]
    content_html = entry.get("content", {}).get("$t", "")
    labels = [c["term"] for c in entry.get("category", [])]

    url = ""
    for link in entry.get("link", []):
        if link.get("rel") == "alternate":
            url = link.get("href", "")
            break

    return {
        "id": post_id,
        "title": title,
        "published": published,
        "updated": updated,
        "url": url,
        "labels": labels,
        "content_html": content_html,
    }


def slugify(text: str) -> str:
    text = text.lower()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[-\s]+", "-", text).strip("-")
    return text[:80] or "post"


def yaml_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def write_post(post: dict[str, Any]) -> Path:
    date = post["published"][:10]
    slug = slugify(post["title"])
    path = POSTS_DIR / f"{date}-{slug}.md"

    body_md = markdownify(post["content_html"], heading_style="ATX").strip()
    body_md = re.sub(r"\n{3,}", "\n\n", body_md)

    labels_yaml = "[" + ", ".join(f'"{yaml_escape(l)}"' for l in post["labels"]) + "]"
    frontmatter = (
        "---\n"
        f'title: "{yaml_escape(post["title"])}"\n'
        f'date: {post["published"]}\n'
        f'updated: {post["updated"]}\n'
        f'url: "{post["url"]}"\n'
        f"labels: {labels_yaml}\n"
        f'id: "{post["id"]}"\n'
        "---\n\n"
    )

    path.write_text(frontmatter + body_md + "\n", encoding="utf-8")
    return path


def main() -> int:
    POSTS_DIR.mkdir(exist_ok=True)

    posts: list[dict[str, Any]] = []
    start = 1
    total: int | None = None
    with httpx.Client(headers={"User-Agent": "swiftbible-archival/1.0"}) as client:
        while True:
            data = fetch_page(client, start)
            feed = data.get("feed", {})
            if total is None:
                try:
                    total = int(feed["openSearch$totalResults"]["$t"])
                except (KeyError, TypeError, ValueError):
                    total = None
            entries = feed.get("entry", []) or []
            print(
                f"  start-index={start} got {len(entries)} entries"
                + (f" ({len(posts) + len(entries)}/{total})" if total else ""),
                file=sys.stderr,
            )
            if not entries:
                break
            for e in entries:
                posts.append(extract_post(e))
            if total is not None and len(posts) >= total:
                break
            start += len(entries)

    print(f"Got {len(posts)} posts. Writing markdown...", file=sys.stderr)

    index: list[dict[str, Any]] = []
    for p in posts:
        path = write_post(p)
        index.append(
            {
                "id": p["id"],
                "title": p["title"],
                "date": p["published"],
                "url": p["url"],
                "labels": p["labels"],
                "file": str(path.relative_to(HERE)),
            }
        )

    index.sort(key=lambda x: x["date"], reverse=True)
    INDEX_PATH.write_text(json.dumps(index, indent=2), encoding="utf-8")

    if index:
        dates = [i["date"][:10] for i in index]
        label_counts = Counter(l for i in index for l in i["labels"]).most_common(10)
        print("", file=sys.stderr)
        print(f"  Total posts: {len(index)}", file=sys.stderr)
        print(f"  Date range:  {min(dates)} → {max(dates)}", file=sys.stderr)
        print(f"  Output:      {POSTS_DIR}", file=sys.stderr)
        print(f"  Index:       {INDEX_PATH}", file=sys.stderr)
        if label_counts:
            print("  Top labels:", file=sys.stderr)
            for label, count in label_counts:
                print(f"    {count:4d}  {label}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    sys.exit(main())
