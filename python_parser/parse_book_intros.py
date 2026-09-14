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

Outputs (the iOS bundle and the Android assets get byte-identical copies):
  ios/swiftbible/Text/book_intros_{mhcc,jfb}.json
  android/app/src/main/assets/book_intros_{mhcc,jfb}.json

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
import parse_mhc_unabridged

REPO = Path(__file__).resolve().parents[1]
TEXT_DIR = REPO / "ios" / "swiftbible" / "Text"
# The apps bundle byte-identical copies; both must be regenerated together so
# iOS and Android never drift (see cross-platform-parity).
ANDROID_ASSET_DIR = REPO / "android" / "app" / "src" / "main" / "assets"

JFB_SOURCE = parse_jfb.SOURCE

# iOS Text/ + Android assets/ — same filename, written to both.
MHCC_OUTPUTS = [TEXT_DIR / "book_intros_mhcc.json", ANDROID_ASSET_DIR / "book_intros_mhcc.json"]
JFB_OUTPUTS = [TEXT_DIR / "book_intros_jfb.json", ANDROID_ASSET_DIR / "book_intros_jfb.json"]

# "About this book" Matthew Henry intros come from his full, unabridged
# Exposition (parse_mhc_unabridged), NOT the Concise abridgment — the Concise
# opens each book with a sentence or two, whereas these are the full essays.
# (The Concise text is still the source for the per-chapter summaries that
# parse_mhcc.py / generate_chapter_summaries.py produce — that's untouched.)
MHCC_SOURCE_INFO = parse_mhc_unabridged.SOURCE_INFO

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
# false splits before digits, e.g. "about A. D. 97," and "ch. 21:22". Henry
# also runs sentences together with a dash and no space: "perishes in a
# night.--The Bible began".
_BOUNDARY_RE = re.compile(r'[.!?]["”\')\]]?\s+(?=["“\'(]?[A-Z])|[.!?]--(?=[A-Z])')

# Both commentaries number the points of an introduction, nesting roman, arabic
# and bracketed markers: "...we must enquire, I. Into the divine authority of
# it; ... II. As to the divine amanuensis...". A marker belongs to the point it
# opens, but it trails a sentence-ending period, so the splitter above reads it
# as the close of the point before — which strands a bare "II." at the end of a
# paragraph. These two patterns recognise one so it can be carried forward.
_ENUMERATOR_RE = re.compile(r"^[\[(]?([0-9]{1,3}|[A-Za-z]+)[.)\]]{1,2}$")
_ROMAN_RE = re.compile(r"(?i)^(?=[mdclxvi]+$)m*(?:c[md]|d?c{0,3})(?:x[cl]|l?x{0,3})(?:i[xv]|v?i{0,3})$")


def _is_enumerator(token: str) -> bool:
    match = _ENUMERATOR_RE.match(token)
    if match is None:
        return False
    word = match.group(1)
    # A number, a single letter, or a roman numeral — but not a one-word
    # sentence that happens to stand alone ("No.", "Ill.").
    return word.isdigit() or len(word) == 1 or _ROMAN_RE.match(word) is not None


def _ends_sentence(text: str, dot: int) -> bool:
    """Whether the punctuation char at index `dot` actually ends a sentence
    (vs. trailing an abbreviation, an initial, or a cited chapter number)."""
    if text[dot] != ".":
        return True  # "!" and "?" are unambiguous
    k = dot - 1
    while k >= 0 and text[k].isalpha():
        k -= 1
    token = text[k + 1:dot]
    if len(token) == 1 and token.isupper():
        return False  # initial: "A.", "D.", "R."
    if _ROMAN_RE.match(token):
        return False  # "ch. xi.", "Hos. viii. 12." — a citation, not a close
    if not token and _is_inline_enumerator(text, dot):
        return False  # "we may observe, 1. That he relates..."
    return token.lower() not in _ABBREVIATIONS


# A marker introduced by a comma — "we may observe, 1. That..." — sits
# mid-sentence, the arabic twin of "we must enquire, I. Into...". A verse list
# ("ch. xxvii. 2, 3.") also puts a number after a comma, but a number or roman
# numeral precedes that comma rather than a word.
_INLINE_ENUMERATOR_RE = re.compile(r"(?:^|\s)([A-Za-z]+),\s+\d{1,3}$")


def _is_inline_enumerator(text: str, dot: int) -> bool:
    match = _INLINE_ENUMERATOR_RE.search(text[max(0, dot - 40):dot])
    return match is not None and _ROMAN_RE.match(match.group(1)) is None


def split_sentences(text: str) -> list[str]:
    cuts = [0]
    for m in _BOUNDARY_RE.finditer(text):
        if _ends_sentence(text, m.start()):
            cuts.append(m.end())
    cuts.append(len(text))
    sentences = [text[a:b].strip() for a, b in zip(cuts, cuts[1:]) if text[a:b].strip()]
    return _carry_enumerators_forward(sentences)


def _trailing_enumerator(sentence: str) -> tuple[str, str]:
    """Peel a trailing enumerator off a sentence: the marker opens the point
    that follows, so "...two hundred years. 2." splits into the sentence and
    the "2." that belongs with what comes next. A numeral finishing a citation
    ("Hos. viii. 12.") is left alone — what precedes it is not a full stop."""
    head, _, last = sentence.rpartition(" ")
    if not _is_enumerator(last):
        return sentence, ""
    if _CHAPTER_RANGE_RE.search(head):
        return head, last  # "ch. xiii.-xxi. 4." — a range takes no verse number
    # The point before may close inside a quotation: 'saying the same?" 2.'
    closed = head.rstrip("\"”')]")
    if head and not (closed.endswith((".", "!", "?")) and _ends_sentence(closed, len(closed) - 1)):
        return sentence, ""
    return head, last


_CHAPTER_RANGE_RE = re.compile(r"(?i)\b[mdclxvi]+\.-[mdclxvi]+\.$")


def _carry_enumerators_forward(sentences: list[str]) -> list[str]:
    out: list[str] = []
    carried = ""
    for sentence in sentences:
        head, enumerator = _trailing_enumerator(sentence)
        if head:
            out.append(f"{carried} {head}".strip() if carried else head)
            carried = enumerator
        else:  # the whole sentence was a marker — keep collecting
            carried = f"{carried} {enumerator}".strip()
    if carried:  # nothing followed it; leave it where it was
        if out:
            out[-1] = f"{out[-1]} {carried}"
        else:
            out.append(carried)
    return out


def soft_wrap(text: str) -> list[str]:
    """Split an over-long paragraph into sentence-aligned chunks ~TARGET_CHARS."""
    if len(text) <= SOFT_MAX_CHARS:
        return [text]
    chunks: list[str] = []
    current = ""
    for sentence in split_sentences(text):
        # Never close a runt chunk either — a lone run-in head ("Design.--")
        # would be split from the section it heads.
        if len(current) >= MIN_TAIL_CHARS and len(current) + 1 + len(sentence) > TARGET_CHARS:
            chunks.append(current)
            current = sentence
        else:
            current = f"{current} {sentence}".strip()
    if current:
        chunks.append(current)
    # Fold a too-short tail back into the prior chunk. Pop first: `chunks[-2]`
    # on the left of the assignment is resolved after the right side has
    # already shortened the list, so folding in one statement writes the merged
    # text over the wrong chunk — dropping one and duplicating another.
    if len(chunks) > 1 and len(chunks[-1]) < MIN_TAIL_CHARS:
        tail = chunks.pop()
        chunks[-1] = f"{chunks[-1]} {tail}"
    return chunks


def readable_paragraphs(paragraphs: list[str]) -> list[str]:
    """Flatten blank-line paragraphs into reader-friendly, length-bounded ones."""
    out: list[str] = []
    for paragraph in paragraphs:
        out.extend(soft_wrap(paragraph))
    return out


# ---------------------------------------------------------------------------
# Typography
#
# The plain-text sources flatten what the printed commentaries showed with type:
# JFB's run-in section heads ("Where Job Lived.--"), its small-caps emphasis
# ("The TIME OF WRITING was"), both authors' numbered points, and the em dash
# typed as "--". The re-flowed paragraphs get a deliberately tiny markup the
# apps render (BookIntroView on iOS, BookIntroScreen on Android):
#
#   "## Heading"   a whole paragraph that is a section heading
#   "**text**"     bold, inline
#
# and "--" becomes "—". Formatting never changes a word: plain_text() strips it
# back off, and the tests hold the result to the unformatted text.
# ---------------------------------------------------------------------------

# "Where Job Lived.--Uz, according to..." — a run-in head, optionally numbered
# ("II. Inspiration and Authorship.--"). No period inside the head itself.
_RUN_IN_HEAD_RE = re.compile(r"^((?:[IVX]+\. )?[A-Z][^.]{1,70}?)\.--\s*(.+)$", re.S)

# Small-caps emphasis, flattened to capitals: a run of all-caps words. Roman
# numerals and "LXX" (the Septuagint) are genuinely capitals, not emphasis.
_CAPS_RUN_RE = re.compile(r"\b[A-Z]{2,}(?:\s+[A-Z]{2,})*\b")
_TRUE_CAPITALS = {"LXX", "MS", "MSS", "KJV"}

# A numbered point: "I.", "12.", "[1.]", "(1)".
_MARKER = r"(?:[IVX]{1,4}\.|\d{1,2}\.|\[\d{1,2}\.?\]|\(\d{1,2}\))"
_MARKER_RE = re.compile(rf"(?:(?<=^)|(?<=\s)|(?<=—)){_MARKER}(?=\s+[\"“(]?[A-Za-z])")


def _is_true_capital(word: str) -> bool:
    return word in _TRUE_CAPITALS or _ROMAN_RE.match(word) is not None


def _small_caps_to_bold(text: str) -> str:
    def replace(match: re.Match) -> str:
        run = match.group(0)
        if all(_is_true_capital(w) for w in run.split()):
            return run
        return f"**{run.lower()}**"

    return _CAPS_RUN_RE.sub(replace, text)


def _opens_point(text: str, start: int, marker: str) -> bool:
    """Whether the marker at `start` numbers a point, rather than finishing a
    citation ("Hos. viii. 12. The") or a count ("in all 299. It")."""
    before = text[:start].rstrip()
    if not before:
        return True  # opens the paragraph
    after = text[start + len(marker):].lstrip("\"“( ")
    if marker.startswith("("):
        # JFB cites as "Ps 18:1", so "(4) Prophetic" is always a list item.
        return before[-1] in ":;,.—" or after[:1].isupper()
    last = before[-1]
    if last == "." and re.fullmatch(r"[IVX]+\.", marker):
        # Henry cites chapters in lowercase roman, so a capital numeral after
        # one opens the next point of his outline: "ch. xv. and xvi. V. Elijah's".
        return True
    if last in ",;:—":
        # "we must enquire, I. Into" / "we may observe, 1. That" — but not a
        # verse list, "ch. xxvii. 2, 3.", where a number precedes the comma.
        word = re.search(r"(\S+)[,;:—]$", before)
        return word is not None and not re.search(r"\d|^[ivxlc]+\.?$", word.group(1))
    if last in "!?\"”')":
        return True
    if last == ".":
        # "two hundred years. 2. He" — or "ch. xiii.-xxi. 4. In", since a range
        # of chapters takes no verse number.
        return _ends_sentence(before, len(before) - 1) or _CHAPTER_RANGE_RE.search(before) is not None
    return False


def _bold_markers(text: str) -> str:
    out: list[str] = []
    cursor = 0
    for match in _MARKER_RE.finditer(text):
        if _opens_point(text, match.start(), match.group(0)):
            out.append(text[cursor:match.start()])
            out.append(f"**{match.group(0)}**")
            cursor = match.end()
    out.append(text[cursor:])
    return "".join(out)


def _format_body(text: str) -> str:
    text = text.replace("--", "—")
    # A dash that only joins punctuation to what follows — the old colon-dash
    # ("thus briefly given:—David") or a sentence run into the next ("in a
    # night.—The Bible") — reads as a typo on screen; the punctuation suffices.
    text = re.sub(r"([.!?:])—\s*", r"\1 ", text).strip()
    return _bold_markers(_small_caps_to_bold(text))


def format_intro(paragraphs: list[str], run_in_heads: bool = False) -> list[str]:
    """Apply the intro markup to re-flowed paragraphs. Only JFB sets run-in
    heads; in Henry a short sentence run on with a dash ("It is so.--The
    book...") would look like one, so heads are recognised only when asked."""
    out: list[str] = []
    for paragraph in paragraphs:
        head = _RUN_IN_HEAD_RE.match(paragraph) if run_in_heads else None
        if head:
            title, body = head.group(1), head.group(2)
            # "The OBJECT OF THE EPISTLE" is a head set in small caps, not
            # emphasis within one; and the body's first word is often set in
            # capitals as a typographic opening ("AS the Epistle is written").
            title = re.sub(r"\b[A-Z]{2,}\b", lambda m: m.group(0) if _is_true_capital(m.group(0)) else m.group(0).lower(), title)
            body = re.sub(r"^([A-Z])([A-Z]+)\b", lambda m: m.group(1) + m.group(2).lower(), body)
            out.append(f"## {title[0].upper()}{title[1:]}")
            out.append(_format_body(body))
        else:
            out.append(_format_body(paragraph))
    return out


def plain_text(paragraphs: list[str]) -> str:
    """Undo format_intro, for comparing words against the source."""
    text = " ".join(p.removeprefix("## ") for p in paragraphs)
    return " ".join(text.replace("**", "").replace("—", "--").split())

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
    """Book intros from Matthew Henry's unabridged Exposition. The structural
    extraction (and its canonical-count assertion) lives in
    parse_mhc_unabridged; here we apply the shared readability re-flow."""
    intros: dict[str, dict] = {}
    for book, paragraphs in parse_mhc_unabridged.parse_raw_intros().items():
        if sum(len(p) for p in paragraphs) < MIN_INTRO_CHARS:
            continue
        intros[book] = {
            "title": f"Introduction to {book}",
            "paragraphs": format_intro(readable_paragraphs(paragraphs)),
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
            "paragraphs": format_intro(readable_paragraphs(paragraphs), run_in_heads=True),
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
    return {"title": f"Introduction to {book}", "paragraphs": format_intro(readable_paragraphs(paragraphs), run_in_heads=True)}


# ---------------------------------------------------------------------------

def write_output(paths: list[Path], source_info: dict, intros: dict[str, dict]) -> None:
    payload = json.dumps({"source": source_info, "bookIntros": intros}, indent=2, ensure_ascii=False) + "\n"
    for path in paths:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(payload, encoding="utf-8")


def main() -> None:
    mhcc = parse_mhcc_intros()
    write_output(MHCC_OUTPUTS, MHCC_SOURCE_INFO, mhcc)
    print(f"MHCC (unabridged): {len(mhcc)} book intros → {', '.join(str(p.relative_to(REPO)) for p in MHCC_OUTPUTS)}")

    jfb = parse_jfb_intros()
    write_output(JFB_OUTPUTS, JFB_SOURCE_INFO, jfb)
    print(f"JFB:  {len(jfb)} book intros → {', '.join(str(p.relative_to(REPO)) for p in JFB_OUTPUTS)}")


if __name__ == "__main__":
    main()
