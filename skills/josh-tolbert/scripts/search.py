#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# ///
"""Search Josh Tolbert's transcript archive for lessons matching a query.

Ranks by total query-term frequency. Returns date, series, title, score, and a
snippet centred on the first match.

Modelled on ../../matt-bassford/scripts/search.py, with two differences forced
by this corpus:

  * Metadata lives in `speakers/josh-tolbert/manifest.tsv`, not in per-file
    frontmatter. Titles, durations and speaker attribution come from there.
  * The transcripts are **gitignored** (they are verbatim transcriptions of
    another congregation's worship services and this repo is public). If they
    are absent, this script still works in `--list` mode off the manifest and
    tells you how to rebuild them, instead of failing.

IMPORTANT: the transcripts are NOT speaker-separated. A hit is a hit in the
recording, not proof Josh said it — classes are dialogic and members answer at
length. Always open the file and read the surrounding lines before quoting.

Usage:
    python3 search.py "definition of holy"
    python3 search.py "remnant" --series nehemiah --top 10
    python3 search.py "Josephus" --since 2022
    python3 search.py "depression faith" --top 3 --context 400
    python3 search.py --list
    python3 search.py --list --series isaiah
"""
from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

# Scoring ignores these so a multi-word query is ranked by its content words
# rather than by "of" / "the". Snippets also centre on the first content word.
STOPWORDS = {
    "a", "an", "and", "are", "as", "at", "be", "but", "by", "for", "from", "has",
    "he", "in", "is", "it", "its", "of", "on", "or", "that", "the", "then", "to",
    "was", "we", "what", "when", "will", "with", "you",
}

# Files below this word count are aborted livestream fragments, not lessons
# (one is 4 words). Excluded from search and stats unless --all-files.
FRAGMENT_WORDS = 1500

# Series are inferred from the manifest title; ordered so the more specific
# label wins ("God's Definition of Holy" is the Leviticus series' own title).
SERIES_PATTERNS = [
    ("leviticus", r"leviticus|definition of holy"),
    ("isaiah", r"\bisaiah\b"),
    ("nehemiah", r"\bnehemiah\b"),
    ("deuteronomy", r"\bdeuteronomy\b"),
    ("ezra", r"\bezra\b"),
    ("2-samuel", r"2 samuel|ii samuel"),
    ("1-samuel", r"1 samuel|i samuel"),
    ("minor-prophets", r"minor prophets"),
]


def _resolve_archive() -> Path:
    """Walk up from this script until we find speakers/josh-tolbert."""
    here = Path(__file__).resolve()
    rel = Path("speakers") / "josh-tolbert"
    for base in (here, *here.parents):
        if (base / rel).is_dir():
            return base / rel
    return here.parents[3] / rel  # best-effort fallback


ARCHIVE = _resolve_archive()
SERMONS = ARCHIVE / "sermons"
MANIFEST = ARCHIVE / "manifest.tsv"


def classify_series(title: str) -> str:
    lowered = title.lower()
    for name, pattern in SERIES_PATTERNS:
        if re.search(pattern, lowered):
            return name
    return "topical"


def load_manifest() -> dict[str, dict[str, str]]:
    """video id -> manifest row. Empty dict if the manifest is missing."""
    if not MANIFEST.exists():
        return {}
    with MANIFEST.open(encoding="utf-8", errors="replace") as handle:
        return {row["id"]: row for row in csv.DictReader(handle, delimiter="\t")}


def video_id(path: Path) -> str:
    """Filenames are <date>-<slug>-<videoid>.txt."""
    return path.stem.rsplit("-", 1)[-1]


def content_terms(terms: list[str]) -> list[str]:
    """Drop stopwords, unless the query is nothing but stopwords."""
    kept = [t for t in terms if t.lower() not in STOPWORDS and len(t) > 2]
    return kept or terms


def score_text(content: str, terms: list[str]) -> int:
    lowered = content.lower()
    return sum(lowered.count(term.lower()) for term in content_terms(terms))


def extract_snippet(content: str, terms: list[str], width: int = 240) -> tuple[str, int]:
    """Return (snippet, 1-based line number of the first match)."""
    lowered = content.lower()
    best = -1
    for term in content_terms(terms):
        pos = lowered.find(term.lower())
        if pos >= 0 and (best < 0 or pos < best):
            best = pos
    if best < 0:
        return re.sub(r"\s+", " ", content[:width]).strip(), 1
    line_no = content.count("\n", 0, best) + 1
    start = max(0, best - 60)
    end = min(len(content), best + width - 60)
    snippet = content[start:end]
    if start > 0:
        snippet = "..." + snippet
    if end < len(content):
        snippet = snippet + "..."
    return re.sub(r"\s+", " ", snippet).strip(), line_no


def gather(args, manifest) -> list[tuple[Path, dict[str, str], str, str, int]]:
    """-> [(path, row, title, series, words)] for transcripts passing filters."""
    out = []
    seen_hashes: set[int] = set()
    for path in sorted(SERMONS.glob("*.txt")):
        date_str = path.name[:8]
        if args.since and date_str < args.since.replace("-", "").ljust(8, "0"):
            continue
        if args.until and date_str > args.until.replace("-", "").ljust(8, "9"):
            continue
        row = manifest.get(video_id(path), {})
        title = row.get("title") or path.stem
        series = classify_series(title)
        if args.series and series != args.series.lower():
            continue
        content = path.read_text(encoding="utf-8", errors="replace")
        words = len(content.split())
        if not args.all_files:
            if words < FRAGMENT_WORDS:
                continue
            digest = hash(content)  # exact-duplicate guard (one id, two dates)
            if digest in seen_hashes:
                continue
            seen_hashes.add(digest)
        out.append((path, row, title, series, words))
    return out


def missing_transcripts_notice() -> None:
    sys.stdout.flush()
    print(
        f"No transcripts found at {SERMONS}.\n"
        "\n"
        "They are gitignored on purpose — verbatim transcriptions of another\n"
        "congregation's worship services, in a public repo. Rebuild them with:\n"
        "\n"
        "  bash speakers/josh-tolbert/fill_metadata.sh speakers/josh-tolbert/.all_ids.txt 2\n"
        "  bash speakers/josh-tolbert/run_final.sh\n"
        "\n"
        "See speakers/josh-tolbert/README.md for the runbook and the gotchas\n"
        "(notably: mlx_whisper needs --condition-on-previous-text False).",
        file=sys.stderr,
    )


def do_list(args, manifest) -> int:
    if SERMONS.is_dir() and any(SERMONS.glob("*.txt")):
        rows = gather(args, manifest)
        total_words = sum(words for *_, words in rows)
        header = f"{len(rows)} transcripts"
        if args.series:
            header += f" in series {args.series!r}"
        print(f"{header}, {total_words:,} words:\n")
        for path, row, title, series, words in rows:
            dur = row.get("duration_s") or "0"
            minutes = int(float(dur)) // 60 if dur else 0
            print(f"  {path.name[:8]}  {series:<15} {words:>6}w {minutes:>3}m  {title}")
        return 0

    # No transcripts on disk — fall back to the manifest, which IS tracked.
    if not manifest:
        missing_transcripts_notice()
        return 1
    josh = [r for r in manifest.values() if "Josh Tolbert" in (r.get("speakers") or "")]
    if args.series:
        josh = [r for r in josh if classify_series(r["title"]) == args.series.lower()]
    josh.sort(key=lambda r: r["upload_date"])
    hours = sum(float(r.get("duration_s") or 0) for r in josh) / 3600
    print(
        f"Transcripts are not on disk; listing from the manifest instead.\n"
        f"{len(josh)} recordings attributed to Josh Tolbert, {hours:.1f} hours:\n"
    )
    for row in josh:
        minutes = int(float(row.get("duration_s") or 0)) // 60
        print(f"  {row['upload_date']}  {classify_series(row['title']):<15} {minutes:>3}m  {row['title']}")
    print()
    missing_transcripts_notice()
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Search Josh Tolbert's transcript archive")
    parser.add_argument(
        "query",
        nargs="?",
        help="Search terms (space-separated; OR semantics, stopwords ignored)",
    )
    parser.add_argument("--top", type=int, default=5, help="Max results (default 5)")
    parser.add_argument(
        "--series",
        help="Filter by series: leviticus, isaiah, nehemiah, deuteronomy, ezra, "
        "1-samuel, 2-samuel, minor-prophets, topical",
    )
    parser.add_argument("--since", help="Filter recordings on/after YYYY[-MM[-DD]]")
    parser.add_argument("--until", help="Filter recordings on/before YYYY[-MM[-DD]]")
    parser.add_argument("--context", type=int, default=240, help="Snippet width (default 240)")
    parser.add_argument("--list", action="store_true", help="List the corpus instead of searching")
    parser.add_argument(
        "--all-files",
        action="store_true",
        help="Include aborted stream fragments and exact duplicates (excluded by default)",
    )
    args = parser.parse_args()

    if not ARCHIVE.is_dir():
        print(
            f"Archive not found at {ARCHIVE}\n"
            "Expected the SwiftBible repo with speakers/josh-tolbert/.",
            file=sys.stderr,
        )
        return 1

    manifest = load_manifest()

    if args.list:
        return do_list(args, manifest)

    if not args.query:
        parser.error("a query is required unless --list is given")

    if not SERMONS.is_dir() or not any(SERMONS.glob("*.txt")):
        missing_transcripts_notice()
        return 1

    terms = args.query.split()
    results = []
    for path, row, title, series, _words in gather(args, manifest):
        content = path.read_text(encoding="utf-8", errors="replace")
        score = score_text(content, terms)
        if score > 0:
            results.append((score, path, title, series, content))

    if not results:
        print(f"No matches for {args.query!r}.", file=sys.stderr)
        return 0

    results.sort(key=lambda r: -r[0])
    shown = results[: args.top]

    filters = ""
    if args.series:
        filters += f" --series {args.series}"
    if args.since:
        filters += f" since {args.since}"
    if args.until:
        filters += f" until {args.until}"
    print(f"Top {len(shown)} of {len(results)} matches for {args.query!r}{filters}:\n")
    for score, path, title, series, content in shown:
        snippet, line_no = extract_snippet(content, terms, args.context)
        print(f"  [{score}] {path.name}  (line {line_no}, series: {series})")
        print(f"        {title}")
        print(f"        {snippet}")
        print()
    print(
        "Reminder: these transcripts are NOT speaker-separated. Open the file at the\n"
        "line shown and read around it before attributing anything to Josh.",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
