"""
Audit passage summaries against the verse text they describe.

The user complaint that motivated this script: "some [passage summaries]
are just repeating the words and those aren't really great." This catches
exactly that failure mode by computing token overlap between each summary
and its corresponding verse text — high overlap means the summary is
recycling words instead of describing what's happening.

Inputs
------
- swiftbible/Text/summaries_swiftbible.json  (the source we audit)
- swiftbible/Text/summaries_mhcc.json        (also audited; cross-source comparison)
- swiftbible/Text/bible.json                 (KJV verse text)

Output
------
- Console report grouped by book, listing every passage summary whose
  Jaccard similarity against its verse text exceeds the threshold.
- Optionally writes summary_quality_report.json next to this script for
  programmatic use (--json flag).

Usage
-----
    uv run python3 check_summary_quality.py
    uv run python3 check_summary_quality.py --threshold 0.5
    uv run python3 check_summary_quality.py --source mhcc
    uv run python3 check_summary_quality.py --json

Notes on the metric
-------------------
We use Jaccard similarity over lowercased word *types* (set intersection
over set union), with a small stopword filter so common articles and
copulas don't inflate the score. Jaccard is symmetric, bounded [0, 1],
and intuitive: 0.6 means "60% of the unique meaningful words appear in
both the summary and the verse text". Empirically:
- 0.0–0.2: paraphrase or theme statement (good)
- 0.2–0.4: descriptive but reuses some content words (acceptable)
- 0.4–0.6: heavy overlap (suspect)
- 0.6+:    summary is essentially restating the verse (replace)
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Iterable

REPO = Path(__file__).resolve().parents[1]
TEXT_DIR = REPO / "swiftbible" / "Text"
DEFAULT_THRESHOLD = 0.6

# Tiny stopword set — just the highest-frequency function words. Keeping it
# small so theme verbs like "create", "give", "speak" still count.
STOPWORDS = {
    "a", "an", "the",
    "and", "or", "but", "if", "so", "as",
    "is", "are", "was", "were", "be", "been", "being",
    "of", "to", "in", "on", "at", "by", "for", "from", "with",
    "this", "that", "these", "those", "it", "its",
    "he", "she", "him", "her", "his", "hers", "they", "them", "their",
    "i", "me", "my", "we", "us", "our", "you", "your",
    "shall", "will", "may", "can", "do", "did", "does",
    "not", "no",
}

WORD_RE = re.compile(r"[a-z']+")


def tokenize(text: str) -> set[str]:
    """Lowercased word tokens with stopwords removed."""
    return {
        w for w in WORD_RE.findall(text.lower())
        if w not in STOPWORDS and len(w) > 1
    }


def jaccard(a: set[str], b: set[str]) -> float:
    if not a or not b:
        return 0.0
    intersection = len(a & b)
    union = len(a | b)
    return intersection / union if union else 0.0


def load_bible_text() -> dict[str, dict[str, str]]:
    """
    Return {book_name: {"chapter:verse": "verse text"}} so we can look up
    the actual prose for any (book, chapter, startVerse) triple.
    """
    path = TEXT_DIR / "bible.json"
    books = json.loads(path.read_text())
    out: dict[str, dict[str, str]] = {}
    for book in books:
        per_chap: dict[str, str] = {}
        for chapter in book["chapters"]:
            chap_num = chapter["number"]
            for paragraph in chapter["paragraphs"]:
                key = f"{chap_num}:{paragraph['startingVerse']}"
                per_chap[key] = paragraph["text"]
        out[book["name"]] = per_chap
    return out


def load_source(source_name: str) -> dict:
    """Load summaries_<source>.json by short name."""
    path = TEXT_DIR / f"summaries_{source_name}.json"
    if not path.exists():
        raise SystemExit(f"missing {path}")
    return json.loads(path.read_text())


def audit_source(
    source_name: str,
    threshold: float,
) -> list[dict]:
    """
    Walk every passage summary in the source and emit a report row for
    each one whose Jaccard score against the verse text exceeds the
    threshold. Returns a list of dicts ready to print or serialize.
    """
    summary_data = load_source(source_name)
    bible = load_bible_text()

    rows: list[dict] = []
    for book, chapters in summary_data["passageSummaries"].items():
        if book not in bible:
            # Pseudepigrapha / apocrypha — no canonical KJV reference text
            # to compare against. Skip them silently.
            continue
        for chap_num, entries in chapters.items():
            for entry in entries:
                verse_key = f"{chap_num}:{entry['startVerse']}"
                verse_text = bible[book].get(verse_key)
                if not verse_text:
                    continue
                summary_tokens = tokenize(entry["title"])
                verse_tokens = tokenize(verse_text)
                score = jaccard(summary_tokens, verse_tokens)
                if score >= threshold:
                    rows.append({
                        "source": source_name,
                        "book": book,
                        "chapter": int(chap_num),
                        "startVerse": entry["startVerse"],
                        "score": round(score, 3),
                        "summary": entry["title"],
                        "verse_text": verse_text.strip()[:140],
                    })
    rows.sort(key=lambda r: (-r["score"], r["book"], r["chapter"], r["startVerse"]))
    return rows


def print_report(rows: list[dict], threshold: float) -> None:
    if not rows:
        print(f"No passage summaries exceed the {threshold:.0%} overlap threshold. ✨")
        return

    print(f"\nFound {len(rows)} passage summaries with ≥{threshold:.0%} word overlap")
    print(f"against their verse text (sorted by severity).\n")

    current_book = None
    for row in rows:
        if row["book"] != current_book:
            current_book = row["book"]
            print(f"\n=== {current_book} ===")
        ref = f"{row['chapter']}:{row['startVerse']}"
        bar = "█" * int(row["score"] * 20)
        print(f"  {ref:>8}  {row['score']:.2f}  {bar}")
        print(f"           summary: {row['summary']}")
        print(f"           verse:   {row['verse_text']}")


def main(argv: Iterable[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source",
        choices=["swiftbible", "mhcc"],
        default="swiftbible",
        help="Which summary source to audit (default: swiftbible).",
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=DEFAULT_THRESHOLD,
        help=f"Jaccard similarity above which to flag (default: {DEFAULT_THRESHOLD}).",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Also write summary_quality_report.json.",
    )
    args = parser.parse_args(list(argv) if argv else None)

    rows = audit_source(args.source, args.threshold)
    print_report(rows, args.threshold)

    if args.json:
        out = Path(__file__).parent / "summary_quality_report.json"
        out.write_text(json.dumps({
            "source": args.source,
            "threshold": args.threshold,
            "flagged_count": len(rows),
            "rows": rows,
        }, indent=2, ensure_ascii=False))
        print(f"\nWrote {out.name}")


if __name__ == "__main__":
    main()
