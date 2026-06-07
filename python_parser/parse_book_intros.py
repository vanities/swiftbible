"""
Extract per-book INTRODUCTIONS from the Matthew Henry (MHCC) and
Jamieson-Fausset-Brown (JFB) plain-text editions and emit them as the
`book_intros_<source>.json` resources the iOS app loads for the
"About this book" row.

Both commentaries open every book with a short essay covering authorship,
date, the historical setting, and the occasion/purpose of the writing — the
exact "about this book" content we want to surface. The existing summary
parsers (parse_mhcc.py / parse_jfb.py) keep only the chapter outlines and
discard these introductions; this script recovers them from the same source
texts.

Inputs (git-LFS; run `git lfs pull` first):
  python_parser/sources/mhcc/mhcc.txt
  python_parser/sources/jfb/jfb.txt

Outputs:
  ios/swiftbible/Text/book_intros_mhcc.json
  ios/swiftbible/Text/book_intros_jfb.json

The SwiftBible-curated intros for the apocrypha / pseudepigrapha (which MHCC
and JFB don't cover) live in a hand-authored file and are NOT generated here:
  ios/swiftbible/Text/book_intros_swiftbible.json

Emitted schema (matches BookIntrosFile in SummariesService.swift):
    {
      "source": {name, shortName, year, license, attribution},
      "bookIntros": {
        "<Book Name>": {
          "title": "Introduction to <Book Name>",
          "paragraphs": ["...", "..."]
        }
      }
    }
"""
from __future__ import annotations

import json
import re
from pathlib import Path

import parse_jfb
import parse_mhcc

REPO = Path(__file__).resolve().parents[1]
TEXT_DIR = REPO / "ios" / "swiftbible" / "Text"

MHCC_SOURCE = parse_mhcc.SOURCE
JFB_SOURCE = parse_jfb.SOURCE

MHCC_OUTPUT = TEXT_DIR / "book_intros_mhcc.json"
JFB_OUTPUT = TEXT_DIR / "book_intros_jfb.json"

MHCC_SOURCE_INFO = {
    "name": "Matthew Henry's Concise Commentary",
    "shortName": "Matthew Henry",
    "year": 1706,
    "license": "Public Domain",
    "attribution": (
        "Matthew Henry (1662–1714). Concise Commentary on the Bible, "
        "sourced from the Christian Classics Ethereal Library (CCEL)."
    ),
}

JFB_SOURCE_INFO = {
    "name": "Jamieson, Fausset & Brown — Commentary on the Whole Bible",
    "shortName": "Jamieson-Fausset-Brown",
    "year": 1871,
    "license": "Public Domain",
    "attribution": (
        "Robert Jamieson, A. R. Fausset, and David Brown. Commentary "
        "Critical and Explanatory on the Whole Bible (1871), sourced from "
        "the Christian Classics Ethereal Library (CCEL)."
    ),
}

# CCEL plain-text uses a run of underscores as a horizontal rule between
# sections. We drop these wholesale when collecting prose.
SEPARATOR_RE = re.compile(r"^_+$")

# JFB marks each book's essay with a bare "INTRODUCTION" line.
JFB_INTRO_RE = re.compile(r"^\s*INTRODUCTION\s*$")
# Lines that terminate a JFB intro body — the first structural marker that
# starts the actual commentary.
JFB_BODY_STOP = (
    parse_jfb.CHAPTER_RE,
    parse_jfb.PSALM_RE,
    parse_jfb.SECTION_RE,
    parse_jfb.SINGLE_CHAPTER_SECTION_RE,
)

# Minimum prose length (chars) for an intro to be considered real. Guards
# against a stray "INTRODUCTION" header with no body slipping through.
MIN_INTRO_CHARS = 120

# Readability re-flow. The CCEL intros arrive either as a single very long
# paragraph (MHCC keeps each book's intro as one block) or as a handful of
# enormous ones (JFB has individual paragraphs of 5,000–8,000 chars). Rendered
# verbatim in BookIntroView they're an unbroken wall of text, so we split any
# paragraph longer than SOFT_MAX_CHARS into sentence-aligned chunks of roughly
# TARGET_CHARS, never breaking mid-sentence. Shorter paragraphs pass through
# untouched (e.g. the ~530-char Genesis intro stays a single paragraph).
SOFT_MAX_CHARS = 700
TARGET_CHARS = 480
# Don't leave a runt final chunk; fold it back into the previous one.
MIN_TAIL_CHARS = 160

# Lowercased words that end in a period without ending a sentence. Single
# letters (initials like "A. D.", "A. R. Fausset", "i. e.") are handled
# separately by length, so they're not listed here.
_ABBREVIATIONS = {
    "ad", "bc", "am", "ch", "chap", "cf", "viz", "cir", "ver", "vers",
    "vs", "st", "mr", "mrs", "dr", "rev", "vol", "no", "etc", "ie", "eg",
    "messrs", "jun", "sen", "pp",
}

# A sentence-ending punctuation mark (optionally followed by a closing quote)
# then whitespace then the start of the next sentence (a capital, optionally
# behind an opening quote/paren). Restricting the next char to a capital avoids
# false splits before digits, e.g. "about A. D. 97," and "ch. 21:22".
_BOUNDARY_RE = re.compile(r'[.!?]["”\')\]]?\s+(?=["“\'(]?[A-Z])')


def _ends_sentence(text: str, dot: int) -> bool:
    """Whether the punctuation char at index `dot` actually ends a sentence
    (vs. trailing an abbreviation or an initial)."""
    if text[dot] != ".":
        return True  # "!" and "?" are unambiguous
    k = dot - 1
    while k >= 0 and text[k].isalpha():
        k -= 1
    token = text[k + 1:dot]
    if len(token) == 1 and token.isupper():
        return False  # initial: "A.", "D.", "R."
    return token.lower() not in _ABBREVIATIONS


def split_sentences(text: str) -> list[str]:
    cuts = [0]
    for m in _BOUNDARY_RE.finditer(text):
        if _ends_sentence(text, m.start()):
            cuts.append(m.end())
    cuts.append(len(text))
    return [text[a:b].strip() for a, b in zip(cuts, cuts[1:]) if text[a:b].strip()]


def soft_wrap(text: str) -> list[str]:
    """Split an over-long paragraph into sentence-aligned chunks ~TARGET_CHARS."""
    if len(text) <= SOFT_MAX_CHARS:
        return [text]
    chunks: list[str] = []
    current = ""
    for sentence in split_sentences(text):
        if current and len(current) + 1 + len(sentence) > TARGET_CHARS:
            chunks.append(current)
            current = sentence
        else:
            current = f"{current} {sentence}".strip()
    if current:
        chunks.append(current)
    # Fold a too-short tail back into the prior chunk.
    if len(chunks) > 1 and len(chunks[-1]) < MIN_TAIL_CHARS:
        chunks[-2] = f"{chunks[-2]} {chunks.pop()}"
    return chunks


def readable_paragraphs(paragraphs: list[str]) -> list[str]:
    """Flatten blank-line paragraphs into reader-friendly, length-bounded ones."""
    out: list[str] = []
    for paragraph in paragraphs:
        out.extend(soft_wrap(paragraph))
    return out

# A "Commentary by ..." byline sits directly under every JFB book-title header.
# If one appears between an INTRODUCTION and the chapter anchor, the
# INTRODUCTION belongs to an earlier book (or to the front matter, as with
# Genesis, which has no intro of its own) — not the book we're anchoring on.
JFB_BYLINE_RE = re.compile(r"^\s*Commentary by\b")


def collect_paragraphs(lines: list[str], start: int, end: int) -> list[str]:
    """
    Gather the prose in [start, end) into blank-line-delimited paragraphs,
    dropping CCEL underscore rules and collapsing intra-paragraph whitespace.
    """
    paragraphs: list[str] = []
    current: list[str] = []
    for i in range(start, end):
        stripped = lines[i].strip()
        if SEPARATOR_RE.match(stripped):
            continue
        if not stripped:
            if current:
                paragraphs.append(" ".join(current))
                current = []
            continue
        current.append(stripped)
    if current:
        paragraphs.append(" ".join(current))
    return [p for p in paragraphs if p]


# ---------------------------------------------------------------------------
# Matthew Henry
# ---------------------------------------------------------------------------

def parse_mhcc_intros() -> dict[str, dict]:
    lines = MHCC_SOURCE.read_text(encoding="utf-8").splitlines()
    book_starts = parse_mhcc.find_book_start_indices(lines)
    ordered = sorted(book_starts.items(), key=lambda kv: kv[1])

    intros: dict[str, dict] = {}
    for idx, (book, start) in enumerate(ordered):
        book_end = ordered[idx + 1][1] if idx + 1 < len(ordered) else len(lines)
        # Intro runs from just after the centered book header to the first
        # "Chapter 1" marker.
        chapter_one = None
        for i in range(start + 1, book_end):
            if parse_mhcc.CHAPTER_RE.match(lines[i].strip()):
                chapter_one = i
                break
        if chapter_one is None:
            continue
        paragraphs = collect_paragraphs(lines, start + 1, chapter_one)
        if sum(len(p) for p in paragraphs) < MIN_INTRO_CHARS:
            continue
        intros[book] = {
            "title": f"Introduction to {book}",
            "paragraphs": readable_paragraphs(paragraphs),
        }
    return intros


# ---------------------------------------------------------------------------
# Jamieson-Fausset-Brown
# ---------------------------------------------------------------------------

def nearest_intro_above(lines: list[str], anchor: int) -> int | None:
    """Return the index of the closest 'INTRODUCTION' line strictly above
    `anchor`, or None if none is found before the previous chapter marker."""
    for i in range(anchor - 1, -1, -1):
        if JFB_INTRO_RE.match(lines[i]):
            return i
        # Don't cross a chapter/psalm marker — that would belong to the prior
        # book and means this book simply has no INTRODUCTION block.
        if parse_jfb.CHAPTER_RE.match(lines[i]) or parse_jfb.PSALM_RE.match(lines[i]):
            return None
    return None


def jfb_body_end(lines: list[str], intro_line: int, hard_end: int) -> int:
    for i in range(intro_line + 1, hard_end):
        line = lines[i].rstrip()
        if any(rx.match(line) for rx in JFB_BODY_STOP):
            return i
    return hard_end


def parse_jfb_intros() -> dict[str, dict]:
    lines = JFB_SOURCE.read_text(encoding="utf-8").splitlines(keepends=True)
    boundaries = parse_jfb.find_chaptered_book_boundaries(lines)

    # Build a list of (book, start_anchor) pairs. start_anchor is the line the
    # intro immediately precedes: CHAPTER 1 for chaptered books, PSALM 1 for
    # Psalms, the title-header for single-chapter books.
    anchors: list[tuple[str, int]] = []
    for book, start, _end in boundaries:
        anchors.append((book, start))  # `start` is the book's CHAPTER 1 line

    # Psalms — anchored on its first PSALM marker.
    psalms_slice = parse_jfb.find_psalms_slice(lines, boundaries)
    if psalms_slice is not None:
        anchors.append(("Psalms", psalms_slice[0]))

    intros: dict[str, dict] = {}
    for book, anchor in anchors:
        intro_line = nearest_intro_above(lines, anchor)
        if intro_line is None:
            continue
        # Reject when a book-title byline sits between the INTRODUCTION and the
        # anchor — that means this INTRODUCTION introduces an earlier book (or
        # front matter), and the anchored book simply has no intro of its own.
        if any(JFB_BYLINE_RE.match(lines[i]) for i in range(intro_line + 1, anchor)):
            continue
        end = jfb_body_end(lines, intro_line, anchor)
        paragraphs = collect_paragraphs(lines, intro_line + 1, end)
        if sum(len(p) for p in paragraphs) < MIN_INTRO_CHARS:
            continue
        intros[book] = {
            "title": f"Introduction to {book}",
            "paragraphs": readable_paragraphs(paragraphs),
        }

    # Single-chapter books (Philemon, Jude, 2 John, 3 John) have no CHAPTER/
    # PSALM marker. Anchor on the ALL-CAPS title header, take the INTRODUCTION
    # just below it, and read until the first verse-commentary section header.
    for book, title_tokens in JFB_SINGLE_CHAPTER_TITLES.items():
        intro = extract_jfb_single_chapter(lines, title_tokens, book)
        if intro is not None:
            intros[book] = intro

    return intros


# Distinctive title-line text (uppercased) that sits directly above the
# INTRODUCTION for each single-chapter book. The combined "SECOND AND THIRD
# EPISTLES" header carries the 2 John intro; 3 John reuses the SwiftBible
# fallback when JFB folds it into that combined essay.
JFB_SINGLE_CHAPTER_TITLES: dict[str, str] = {
    "Philemon": "PHILEMON",
    "Jude": "JUDE",
    "2 John": "THE SECOND AND THIRD EPISTLES GENERAL OF",
}

JFB_SINGLE_CHAPTER_ABBREV = {
    "Philemon": "Phm",
    "Jude": "Jude",
    "2 John": "2Jo",
}


def extract_jfb_single_chapter(lines: list[str], title_token: str, book: str) -> dict | None:
    title_idx = None
    for i, line in enumerate(lines):
        if line.strip().upper() == title_token:
            title_idx = i
            break
    if title_idx is None:
        return None
    # First INTRODUCTION below the title.
    intro_line = None
    for i in range(title_idx + 1, min(title_idx + 12, len(lines))):
        if JFB_INTRO_RE.match(lines[i]):
            intro_line = i
            break
    if intro_line is None:
        return None
    # Body ends at the first section header for this book's abbreviation.
    abbrev = JFB_SINGLE_CHAPTER_ABBREV[book]
    end = len(lines)
    for i in range(intro_line + 1, len(lines)):
        m = parse_jfb.SINGLE_CHAPTER_SECTION_RE.match(lines[i].rstrip())
        if m and m.group(1).strip() == abbrev:
            end = i
            break
    paragraphs = collect_paragraphs(lines, intro_line + 1, end)
    if sum(len(p) for p in paragraphs) < MIN_INTRO_CHARS:
        return None
    return {"title": f"Introduction to {book}", "paragraphs": readable_paragraphs(paragraphs)}


# ---------------------------------------------------------------------------

def write_output(path: Path, source_info: dict, intros: dict[str, dict]) -> None:
    payload = {"source": source_info, "bookIntros": intros}
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main() -> None:
    mhcc = parse_mhcc_intros()
    write_output(MHCC_OUTPUT, MHCC_SOURCE_INFO, mhcc)
    print(f"MHCC: {len(mhcc)} book intros → {MHCC_OUTPUT.relative_to(REPO)}")

    jfb = parse_jfb_intros()
    write_output(JFB_OUTPUT, JFB_SOURCE_INFO, jfb)
    print(f"JFB:  {len(jfb)} book intros → {JFB_OUTPUT.relative_to(REPO)}")


if __name__ == "__main__":
    main()
