"""
Build red_letter_map.json — the word-level Words of Jesus map for KJV and ASV.

Where the markup comes from
---------------------------
KJV  Imported, not inferred, from two editions that mark Jesus's words on the
     KJV text itself:

       eng-kjv.osis.xml   seven1m/open-bibles, the upstream the ASV text also
                          comes from. <q who="Jesus">, word for word. The
                          fuller of the two: it marks glosses ("My God, my
                          God…") and Jesus quoted inside someone else's
                          sentence (John 8:33), and it carries verses with two
                          separate spans (Luke 8:45). It is also the sloppier —
                          it leaves quotations open across whole paragraphs of
                          narrative, and drops the KJV's italicised supplied
                          words out of the middle of a sentence.

       eng-kjv_usfx.xml   ebible.org, USFX <wj>. Independent, on the same text,
                          so its boundaries are exact rather than projected.
                          Cleaner, but it declines to mark glosses and quoted
                          speech at all.

     The first is the base; the second and WEB reconcile it. Every correction
     takes two witnesses, and the report says what moved and why.

ASV  No red letter edition of the ASV exists in any public domain format, so
     its spans are projected from the reconciled KJV by word alignment (the ASV
     is a revision of the KJV, so the two track each other closely) and then
     cross-checked against WEB. Verses where the two disagree are reported,
     loudly, rather than quietly shipped.

WEB  Needs nothing: parse_web.py carries its native <wj> tags straight into
     web.json. Here it is a witness, not an output.

Usage:
    python3 build_red_letter_map.py            # build the map + print the report
    python3 build_red_letter_map.py --report   # report only, write nothing
"""

import difflib
import hashlib
import io
import json
import os
import re
import sys
import urllib.request
import zipfile

from red_letter_common import WORD_PATTERN, strip_jesus_tags, verse_map

HERE = os.path.dirname(os.path.abspath(__file__))
TEXT_DIR = os.path.join(HERE, "..", "ios", "swiftbible", "Text")
OSIS_PATH = os.path.join(HERE, "sources", "eng-kjv.osis.xml")
USFX_PATH = os.path.join(HERE, "sources", "eng-kjv_usfx.xml")
MAP_PATH = os.path.join(HERE, "red_letter_map.json")
OVERRIDES_PATH = os.path.join(HERE, "red_letter_overrides.json")

# Pinned by content, since the raw host serves a moving branch. A mismatch is a
# warning, not a failure: upstream corrections are welcome, silent ones are not.
OSIS_URL = "https://raw.githubusercontent.com/seven1m/open-bibles/master/eng-kjv.osis.xml"
OSIS_SHA256 = "eeeae647fc28360ce47f9c0d5cc3b397b7fdd9913fe53dc9f44eb6deee50e253"

# The second witness on the KJV: ebible.org's edition marks Jesus's words with
# USFX <wj>, independently of the OSIS module and on the same text, so its
# boundaries need no alignment to compare.
USFX_URL = "https://ebible.org/Scriptures/eng-kjv_usfx.zip"
USFX_SHA256 = "2a4aa57b3ad1dab01f030c29b9e996be64c4957fcfba98fadd22457ce1b2868c"

# How far two sources may differ before the verse is worth a human's time. One
# or two words is boundary jitter — whether "Verily" or a closing "he said"
# falls inside — not a wrong speaker.
REVIEW_THRESHOLD = 4

# How much narrative a projected witness must see at a verse edge before an
# OSIS span is trimmed back off it. Below this it is jitter, not a swallowed
# introduction. The witness that marks the KJV text itself needs no such margin.
MIN_EDGE_WORDS = 3

# The longest stretch of unmarked words that may be rejoined to the speech
# around it — long enough for "I say unto thee," never long enough for a
# narrative aside.
MAX_CLOSED_GAP = 6

OSIS_BOOKS = {
    "Matt": "Matthew", "Mark": "Mark", "Luke": "Luke", "John": "John",
    "Acts": "Acts", "Rom": "Romans", "1Cor": "1 Corinthians",
    "2Cor": "2 Corinthians", "Gal": "Galatians", "Eph": "Ephesians",
    "Phil": "Philippians", "Col": "Colossians", "1Thess": "1 Thessalonians",
    "2Thess": "2 Thessalonians", "1Tim": "1 Timothy", "2Tim": "2 Timothy",
    "Titus": "Titus", "Phlm": "Philemon", "Heb": "Hebrews", "Jas": "James",
    "1Pet": "1 Peter", "2Pet": "2 Peter", "1John": "1 John", "2John": "2 John",
    "3John": "3 John", "Jude": "Jude", "Rev": "Revelation",
}

# OSIS marks both verses and quotations as milestones — empty elements carrying
# a start id (sID) and a matching end id (eID) — rather than as nesting.
# <transChange type="added"> wraps the words the KJV prints in italics because
# the translators supplied them; they matter here because the module often
# leaves them outside the quotation they belong to.
OSIS_TOKEN = re.compile(
    r'<verse osisID="([^"]+)"[^>]*sID[^>]*/>'
    r'|(<verse eID[^>]*/>)'
    r'|<q who="Jesus"[^>]*sID="([^"]+)"[^>]*/>'
    r'|<q eID="([^"]+)"[^>]*/>'
    r'|(<transChange[^>]*>)'
    r'|(</transChange>)'
    r'|<[^>]+>'
)


def fetch(url, expected_sha256, attempts=4):
    """Download a source, checking it against its pinned digest."""
    for attempt in range(1, attempts + 1):
        try:
            with urllib.request.urlopen(url, timeout=300) as response:
                data = response.read()
        except Exception as error:  # noqa: BLE001 — any transport failure retries
            print(f"  attempt {attempt} failed: {error}")
            continue
        digest = hashlib.sha256(data).hexdigest()
        if digest != expected_sha256:
            print(f"  NOTE: checksum is {digest}, expected {expected_sha256}.")
            print("  Upstream changed. Read the report below before committing the map.")
        return data
    raise SystemExit(f"could not download {url}")


def download_sources():
    """Fetch both KJV markup sources once, into sources/."""
    os.makedirs(os.path.join(HERE, "sources"), exist_ok=True)

    if not os.path.exists(OSIS_PATH):
        print(f"Downloading {OSIS_URL} ...")
        with open(OSIS_PATH, "wb") as f:
            f.write(fetch(OSIS_URL, OSIS_SHA256))
        print(f"  Saved to {OSIS_PATH}")

    if not os.path.exists(USFX_PATH):
        print(f"Downloading {USFX_URL} ...")
        archive = fetch(USFX_URL, USFX_SHA256)
        with zipfile.ZipFile(io.BytesIO(archive)) as bundle:
            name = next(n for n in bundle.namelist() if n.endswith("usfx.xml"))
            with open(USFX_PATH, "wb") as f:
                f.write(bundle.read(name))
        print(f"  Saved to {USFX_PATH}")


def read_osis_spans():
    """{(book, chapter, verse): [[word, ...], ...]} from <q who="Jesus"> markers."""
    with open(OSIS_PATH, "r", encoding="utf-8") as f:
        osis = f.read()

    # Per verse, every word with the two flags that decide whether it is spoken.
    tagged = {}
    verse, in_quote, in_added, position = None, False, False, 0

    def take(chunk):
        if verse:
            tagged.setdefault(verse, []).extend(
                (m.group(0).lower(), in_quote, in_added)
                for m in WORD_PATTERN.finditer(chunk)
            )

    for match in OSIS_TOKEN.finditer(osis):
        take(osis[position:match.start()])
        position = match.end()

        if match.group(1):
            verse, in_quote, in_added = match.group(1), False, False
        elif match.group(2):
            verse = None
        elif match.group(3):
            in_quote = True
        elif match.group(4):
            in_quote = False
        elif match.group(5):
            in_added = True
        elif match.group(6):
            in_added = False

    spans = {}
    for osis_id, words_ in tagged.items():
        book, chapter, verse_number = osis_id.split(".")
        if book not in OSIS_BOOKS:
            continue
        flags = claim_supplied_words(words_)
        ranges = spans_from_flags(flags)
        if ranges:
            key = (OSIS_BOOKS[book], int(chapter), int(verse_number))
            spans[key] = [[w for w, _, _ in words_[s:e]] for s, e in ranges]
    return spans


def claim_supplied_words(words_):
    """Italicised words the module left just outside a quotation are inside it.

    The KJV prints translator-supplied words in italics, and the module tends to
    close the quotation around them: John 18:5 marks "I am" and leaves "he"
    out, Luke 17:22 ends at "ye shall not see" and drops "it". Rendered, that is
    a red sentence with black holes in it. Such a word belongs to the speech
    when the speech runs up to it on either side — and never otherwise, so
    "The Son" in Matthew 22:42, supplied inside the crowd's answer, stays black.
    """
    flags = [in_quote for _, in_quote, _ in words_]

    index = 0
    while index < len(flags):
        if flags[index] or not words_[index][2]:
            index += 1
            continue
        end = index
        while end < len(flags) and words_[end][2] and not flags[end]:
            end += 1
        touches_speech = (index > 0 and flags[index - 1]) or (end < len(flags) and flags[end])
        if touches_speech:
            for i in range(index, end):
                flags[i] = True
        index = max(end, index + 1)

    return flags


USFX_BOOKS = {
    "MAT": "Matthew", "MRK": "Mark", "LUK": "Luke", "JHN": "John", "ACT": "Acts",
    "ROM": "Romans", "1CO": "1 Corinthians", "2CO": "2 Corinthians",
    "GAL": "Galatians", "EPH": "Ephesians", "PHP": "Philippians",
    "COL": "Colossians", "1TH": "1 Thessalonians", "2TH": "2 Thessalonians",
    "1TI": "1 Timothy", "2TI": "2 Timothy", "TIT": "Titus", "PHM": "Philemon",
    "HEB": "Hebrews", "JAS": "James", "1PE": "1 Peter", "2PE": "2 Peter",
    "1JN": "1 John", "2JN": "2 John", "3JN": "3 John", "JUD": "Jude",
    "REV": "Revelation",
}

USFX_TOKEN = re.compile(
    r'<v id="[^"]*" bcv="([^"]+)"\s*/>'
    r'|(<wj>)'
    r'|(</wj>)'
    r'|<[^>]+>'
)


def read_usfx_spans():
    """{(book, chapter, verse): [[word, ...], ...]} from ebible.org's <wj>."""
    with open(USFX_PATH, "r", encoding="utf-8") as f:
        usfx = f.read()

    spans, ref, inside, buffer, position = {}, None, False, [], 0

    def close():
        if ref and buffer:
            spans.setdefault(ref, []).append(list(buffer))
        buffer.clear()

    for match in USFX_TOKEN.finditer(usfx):
        if ref and inside:
            buffer.extend(m.group(0).lower() for m in WORD_PATTERN.finditer(usfx[position:match.start()]))
        position = match.end()

        if match.group(1):
            close()  # a quotation running past a verse boundary ends with it
            book, chapter, verse = match.group(1).split(".")
            name = USFX_BOOKS.get(book)
            ref = (name, int(chapter), int(verse)) if name else None
        elif match.group(2):
            inside, buffer = True, []
        elif match.group(3):
            close()
            inside = False

    return spans


def words(text):
    return [m.group(0).lower() for m in WORD_PATTERN.finditer(text)]


def locate_all(spans_by_ref, verse_text):
    """Turn a source's spans into per-word flags on the shipped KJV text."""
    flags = {}
    for ref, span_words in spans_by_ref.items():
        text = verse_text.get(ref)
        if text is None:
            continue
        verse_words = words(text)
        marks, cursor, found = [False] * len(verse_words), 0, False
        for span in span_words:
            if not span:
                continue
            located = locate(span, verse_words, cursor)
            if located is None:
                continue
            for index in range(*located):
                marks[index] = True
            cursor, found = located[1], True
        if found:
            flags[ref] = marks
    return flags


def locate(span_words, verse_words, after=0):
    """Find a span's word range inside the verse. Returns (start, end) or None.

    OSIS emits spans in document order, so the search starts where the previous
    span ended: Mark 5:41 marks a bare "Damsel," that also appears earlier in
    the verse's narrative ("he took the damsel by the hand"), and only ordering
    tells the two apart.

    Exact first. The two KJV editions differ in a handful of spellings
    ("cloke"/"cloak"), so fall back to anchoring on the span's first and last
    words — still a located range, never a guessed one.
    """
    width = len(span_words)
    for start in range(after, len(verse_words) - width + 1):
        if verse_words[start:start + width] == span_words:
            return start, start + width

    try:
        start = verse_words.index(span_words[0], after)
        end = len(verse_words) - verse_words[::-1].index(span_words[-1])
    except ValueError:
        return None
    if start < end and abs((end - start) - width) <= 2:
        return start, end
    return None


def reconcile(osis_flags, web_flags_on_kjv, usfx_flags=None):
    """Trim an OSIS span that ran over a verse edge into narrative.

    The OSIS module places its <q who="Jesus"> milestone at the start of the
    paragraph in a number of places, so the span swallows the narrative
    introduction with it — Mark 8:34 opens "And when he had called the people
    unto him ... he said unto them," all inside the quote. The same happens at
    the far end (Luke 17:14 keeps "And it came to pass, that, as they went,
    they were cleansed.").

    Both are structural: the span reaches a verse edge that is plainly
    narrative. Trimming takes two independent witnesses, so a single noisy
    reading can never move a boundary, and a boundary in the middle of a verse
    is never touched.

    ebible.org's KJV is the better witness where it has an opinion: it marks
    the same text, so its boundary is exact rather than projected, and a single
    word of narrative is enough to act on. What it will not do is mark a gloss
    — it leaves "which is, being interpreted, My God, my God…" black — and a
    gloss follows the words it explains. So the two edges are not judged alike:

      start  the exact witness decides alone. Its blind spot trails a
             quotation, it does not open a verse, and it is right in every one
             of these — including "Saying," in Mark 10:33 and "And he said also
             to the people," in Luke 12:54, where WEB opens its own quotation
             just as early and would veto the cut.
      end    the exact witness needs WEB to second it, since this is exactly
             where a gloss it declined to mark would be, and Mark 15:34 would
             otherwise lose half its verse.

    Where ebible has nothing to say, WEB decides alone and its projected
    boundary needs the wider margin.

    Returns (flags, "start"/"end"/"both"/None).
    """
    if not any(osis_flags) or not any(web_flags_on_kjv):
        return osis_flags, None

    flags = list(osis_flags)
    exact = usfx_flags if usfx_flags and any(usfx_flags) else None
    witness = exact or web_flags_on_kjv
    margin = 1 if exact else MIN_EDGE_WORDS

    start = witness.index(True)
    end = len(witness) - witness[::-1].index(True)
    trimmed = None

    # Opening narrative the span swallowed.
    seconded = exact is not None or not web_flags_on_kjv[0]
    if flags[0] and not witness[0] and seconded and start >= margin:
        for index in range(start):
            flags[index] = False
        trimmed = "start"

    # Trailing narrative — here a second opinion is always required.
    if (flags[-1] and not witness[-1] and not web_flags_on_kjv[-1]
            and len(flags) - end >= margin):
        for index in range(end, len(flags)):
            flags[index] = False
        trimmed = "both" if trimmed else "end"

    return (flags, trimmed) if any(flags) else (osis_flags, None)


def close_gaps(flags, web_flags_on_kjv):
    """Rejoin spans the module split around words it left unmarked.

    Mark 5:41 marks "Damsel," and "arise." but not the "I say unto thee,"
    between them, which reads as one sentence flickering in and out of red. The
    gap closes only when WEB marks it as spoken too — a gap both sources leave
    black, like "which is, being interpreted," in Mark 15:34, stays black.
    """
    ranges = spans_from_flags(flags)
    if len(ranges) < 2 or not any(web_flags_on_kjv):
        return flags, False

    closed = list(flags)
    joined = False
    for (_, gap_start), (gap_end, _) in zip(ranges, ranges[1:]):
        if gap_end - gap_start > MAX_CLOSED_GAP:
            continue
        if all(web_flags_on_kjv[gap_start:gap_end]):
            for index in range(gap_start, gap_end):
                closed[index] = True
            joined = True
    return closed, joined


def apply_overrides(spans, verse_text, overrides_path=None):
    """Fold red_letter_overrides.json into the KJV spans. Returns what changed.

    Each override quotes the KJV's own wording, so it is located the same way
    an OSIS span is. A quotation that no longer matches the text is reported
    rather than applied — an override that has gone stale must not stay
    invisible.
    """
    path = overrides_path or OVERRIDES_PATH
    if not os.path.exists(path):
        return []

    with open(path, "r", encoding="utf-8") as f:
        overrides = json.load(f)

    applied = []
    for reference, entry in sorted(overrides.get("kjv", {}).items()):
        book, _, numbers = reference.rpartition(" ")
        chapter, _, verse = numbers.partition(":")
        ref = (book, int(chapter), int(verse))

        text = verse_text.get(ref)
        if text is None:
            applied.append((ref, "MISSING: no such verse"))
            continue

        replacing = "set" in entry
        quotations = entry["set"] if replacing else entry.get("add", [])

        verse_words = words(text)
        ranges, cursor, failed = [], 0, None
        for quotation in quotations:
            located = locate(words(quotation), verse_words, cursor)
            if located is None:
                failed = quotation[:60]
                break
            ranges.append(located)
            cursor = located[1]

        if failed:
            applied.append((ref, f"STALE: no longer matches {failed!r}"))
            continue

        existing = [] if replacing else spans.get(ref, [])
        spans[ref] = spans_from_flags(
            flags_from_spans(sorted(existing + ranges), len(verse_words))
        )
        applied.append((ref, entry.get("reason", "")))
    return applied


def build_kjv_spans():
    """KJV word ranges from OSIS, reconciled against WEB.

    Returns (spans, unlocated, trimmed, disputed).
    """
    osis_spans = read_osis_spans()
    verse_text = verse_map(os.path.join(TEXT_DIR, "bible.json"))
    web_text = verse_map(os.path.join(TEXT_DIR, "web.json"), strip=False)
    usfx_flags = locate_all(read_usfx_spans(), verse_text)

    spans, unlocated, trimmed, dropped, disputed, joined = {}, [], [], [], [], []
    for ref, texts in sorted(osis_spans.items()):
        text = verse_text.get(ref)
        if text is None:
            unlocated.append((ref, "verse not found in bible.json"))
            continue
        verse_words = words(text)
        found, cursor = [], 0
        for span_words in texts:
            if not span_words:
                continue
            located = locate(span_words, verse_words, cursor)
            if located is None:
                unlocated.append((ref, " ".join(span_words)[:70]))
                continue
            found.append(located)
            cursor = located[1]
        if not found:
            continue

        flags = flags_from_spans(sorted(found), len(verse_words))
        web_verse = web_text.get(ref)

        if web_verse is not None and "<JESUS>" not in web_verse and all(flags):
            # The module leaves a quotation open across whole paragraphs of
            # narrative — every verse of Luke 7:1-8 and Matthew 24:1 is marked
            # start to finish. A verse that OSIS reddens entirely and WEB does
            # not redden at all is that bleed, not a translation difference:
            # a real full-verse quotation is one in both.
            dropped.append((ref, len(verse_words)))
            continue

        if web_verse and "<JESUS>" in web_verse:
            on_kjv = project(words(strip_jesus_tags(web_verse)), web_flags(web_verse),
                             verse_words, text)
            flags, edge = reconcile(flags, on_kjv, usfx_flags.get(ref))
            if edge:
                trimmed.append((ref, edge))
            flags, gap = close_gaps(flags, on_kjv)
            if gap:
                joined.append(ref)
            difference = sum(1 for a, b in zip(flags, on_kjv) if a != b)
            if difference >= REVIEW_THRESHOLD:
                # Left as OSIS has it — the KJV's own markup is the authority
                # for the KJV — but recorded so a source change is not silent.
                disputed.append((ref, difference, len(verse_words)))

        spans[ref] = spans_from_flags(flags)

    added = apply_overrides(spans, verse_text)
    return spans, unlocated, trimmed, dropped, joined, disputed, added


def flags_from_spans(ranges, length):
    flags = [False] * length
    for start, end in ranges:
        for i in range(start, min(end, length)):
            flags[i] = True
    return flags


def spans_from_flags(flags):
    ranges, start = [], None
    for i, flag in enumerate(flags):
        if flag and start is None:
            start = i
        elif not flag and start is not None:
            ranges.append((start, i))
            start = None
    if start is not None:
        ranges.append((start, len(flags)))
    return ranges


def project(source_words, source_flags, target_words, target_text=None):
    """Carry per-word red letter flags across two wordings of the same verse."""
    target_flags = [False] * len(target_words)
    decided = [False] * len(target_words)
    anchored = [False] * len(target_words)
    matched = [False] * len(target_words)

    matcher = difflib.SequenceMatcher(None, source_words, target_words, autojunk=False)
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag == "equal":
            for offset in range(i2 - i1):
                target_flags[j1 + offset] = source_flags[i1 + offset]
                decided[j1 + offset] = True
                matched[j1 + offset] = True
                anchored[j1 + offset] = source_flags[i1 + offset]
        elif tag == "replace" and i2 > i1:
            # A reworded stretch takes the flag of the words it replaced.
            red = sum(source_flags[i1:i2]) * 2 > (i2 - i1)
            for j in range(j1, j2):
                target_flags[j] = red
                decided[j] = True
        # "insert" leaves target words undecided; "delete" adds none.

    # Words the target adds with no counterpart inherit the flag when the
    # decided words on both sides agree — an alignment gap is not a change of
    # speaker. Words outside any red run, and gaps *between* two separate
    # spans, are left alone.
    for j, settled in enumerate(decided):
        if settled:
            continue
        before = next((target_flags[k] for k in range(j - 1, -1, -1) if decided[k]), None)
        after = next((target_flags[k] for k in range(j + 1, len(target_flags)) if decided[k]), None)
        if before is None or after is None:
            # No decided word on one side: this is a leading or trailing run
            # the two wordings order differently ("him ye believe not" against
            # "you don't believe him"). It takes the flag the source verse
            # itself starts or ends on — the alternative is reading a
            # reordering as a change of speaker.
            target_flags[j] = source_flags[0] if before is None else source_flags[-1]
        else:
            target_flags[j] = before and after

    # A span held up by nothing but reworded and inserted words is not a
    # projection, it is a guess. The ASV drops the KJV's second "Who touched
    # me?" in Luke 8:45 altogether, and without this the span lands on
    # whatever words took its place.
    for start, end in spans_from_flags(target_flags):
        if not any(anchored[start:end]):
            for j in range(start, end):
                target_flags[j] = False

    if target_text is not None:
        snap_to_clause(target_text, target_words, target_flags, matched)

    return target_flags


def snap_to_clause(text, target_words, flags, matched):
    """Pull a span's start back over words the alignment could not place.

    Where the two translations reorder a clause, the opening words of the
    speech have no counterpart to inherit from and are left out: the ASV's
    "Jesus said unto him, Therefore the sons are free" keeps only "are free",
    because the KJV puts it "Then are the children free". Those words join the
    speech when a clause boundary — the introduction's own comma — sits right
    in front of them. The walk stops at the first word the alignment actually
    matched, so it crosses only guesswork, never a word placed as narrative on
    the evidence of both texts.
    """
    positions = [m.start() for m in WORD_PATTERN.finditer(text)]
    if len(positions) != len(target_words):
        return

    for start, _ in spans_from_flags(flags):
        cursor = start
        while cursor > 0 and not matched[cursor - 1]:
            cursor -= 1
        if cursor == start or cursor == 0:
            continue
        preceding = text[:positions[cursor]].rstrip()
        if preceding.endswith((",", ";", ":", "—", "--")):
            for j in range(cursor, start):
                flags[j] = True


def web_flags(text):
    """Per-word flags from web.json's native <wj>-derived tags."""
    flags, inside = [], False
    for match in re.finditer(r"<JESUS>|</JESUS>|[A-Za-z]+", text):
        token = match.group(0)
        if token == "<JESUS>":
            inside = True
        elif token == "</JESUS>":
            inside = False
        else:
            flags.append(inside)
    return flags


def build_asv_spans(kjv_spans):
    """ASV word ranges, projected from the KJV and checked against WEB."""
    kjv_text = verse_map(os.path.join(TEXT_DIR, "bible.json"))
    asv_text = verse_map(os.path.join(TEXT_DIR, "asv.json"))
    # WEB keeps its tags: they are the second opinion being checked against.
    web_text = verse_map(os.path.join(TEXT_DIR, "web.json"), strip=False)

    spans, review, agreed, checked = {}, [], 0, 0

    for ref, ranges in sorted(kjv_spans.items()):
        target = asv_text.get(ref)
        source = kjv_text.get(ref)
        if target is None or source is None:
            continue
        target_words = words(target)
        if not target_words:
            continue

        source_words = words(source)
        from_kjv = project(source_words, flags_from_spans(ranges, len(source_words)),
                           target_words, target)
        if not any(from_kjv):
            continue

        web_verse = web_text.get(ref)
        if web_verse and "<JESUS>" in web_verse:
            checked += 1
            plain = strip_jesus_tags(web_verse)
            from_web = project(words(plain), web_flags(web_verse), target_words, target)
            difference = sum(1 for a, b in zip(from_kjv, from_web) if a != b)
            if difference == 0:
                agreed += 1
            elif difference >= REVIEW_THRESHOLD:
                review.append((ref, difference, len(target_words)))

        spans[ref] = spans_from_flags(from_kjv)

    # Where the KJV has nothing to project, WEB still might: the KJV reports
    # Mark 10:49 indirectly ("commanded him to be called") while the ASV quotes
    # Jesus outright ("Call ye him."), as WEB does. WEB is the ASV's other
    # parent, so it answers for the verses its ancestor cannot.
    from_web_only = 0
    for ref, web_verse in sorted(web_text.items()):
        if ref in spans or "<JESUS>" not in web_verse:
            continue
        target = asv_text.get(ref)
        if target is None:
            continue
        target_words = words(target)
        if not target_words:
            continue
        projected = project(
            words(strip_jesus_tags(web_verse)), web_flags(web_verse), target_words, target
        )
        if any(projected):
            spans[ref] = spans_from_flags(projected)
            from_web_only += 1

    return spans, review, agreed, checked, from_web_only


def nest(spans):
    """{(book, ch, verse): ranges} -> {book: {chapter: {verse: ranges}}}"""
    out = {}
    for (book, chapter, verse), ranges in sorted(spans.items()):
        out.setdefault(book, {}).setdefault(str(chapter), {})[str(verse)] = [
            list(r) for r in ranges
        ]
    return out


def main():
    report_only = "--report" in sys.argv

    download_sources()

    print("Reading OSIS <q who=\"Jesus\"> markers ...")
    kjv_spans, unlocated, trimmed, dropped, joined, disputed, added = build_kjv_spans()
    total_spans = sum(len(v) for v in kjv_spans.values())
    multi = sum(1 for v in kjv_spans.values() if len(v) > 1)
    print(f"  KJV: {len(kjv_spans)} verses, {total_spans} spans "
          f"({multi} verses carry more than one)")
    if unlocated:
        print(f"  UNLOCATED ({len(unlocated)}) — these verses keep no tags:")
        for ref, detail in unlocated:
            print(f"    {ref[0]} {ref[1]}:{ref[2]}  {detail}")
    print(f"  dropped as narrative WEB reddens nowhere: {len(dropped)}")
    for ref, length in dropped:
        print(f"    {ref[0]} {ref[1]}:{ref[2]} ({length} words)")
    print(f"  trimmed off a narrative verse edge, WEB concurring: {len(trimmed)}")
    for ref, edge in trimmed:
        print(f"    {ref[0]} {ref[1]}:{ref[2]} ({edge})")
    print(f"  spans rejoined across an unmarked gap, WEB concurring: {len(joined)}")
    for ref in joined:
        print(f"    {ref[0]} {ref[1]}:{ref[2]}")
    print(f"  hand-reviewed overrides applied: {len(added)}")
    for ref, note in added:
        print(f"    {ref[0]} {ref[1]}:{ref[2]}  {note[:90]}")
    if disputed:
        print(f"  still differing from WEB by {REVIEW_THRESHOLD}+ words "
              f"({len(disputed)}) — kept as OSIS has them:")
        for ref, difference, length in disputed:
            print(f"    {ref[0]} {ref[1]}:{ref[2]}  {difference} of {length} words")

    print("Projecting onto the ASV and cross-checking against WEB ...")
    asv_spans, review, agreed, checked, from_web_only = build_asv_spans(kjv_spans)
    print(f"  ASV: {len(asv_spans)} verses, "
          f"{sum(len(v) for v in asv_spans.values())} spans")
    if checked:
        print(f"  cross-checked against WEB on {checked} verses: "
              f"{agreed} identical ({100 * agreed / checked:.1f}%), "
              f"{len(review)} differ by {REVIEW_THRESHOLD}+ words")
    print(f"  {from_web_only} verses taken from WEB, the KJV having no quotation there")

    if review:
        print(f"\n  For review — KJV and WEB disagree materially:")
        for ref, difference, length in review:
            print(f"    {ref[0]} {ref[1]}:{ref[2]}  {difference} of {length} words")

    if report_only:
        return

    payload = {
        "_comment": (
            "Word-level Words of Jesus spans, as [start, end) indices into each "
            "verse's letter-run word list. Built by build_red_letter_map.py; do "
            "not hand-edit. KJV is imported from OSIS <q who=\"Jesus\">; ASV is "
            "projected from the KJV and cross-checked against WEB. WEB is not "
            "listed because web.json carries its own native tags."
        ),
        "sources": {
            "kjv": OSIS_URL,
            "asv": "projected from kjv, cross-checked against web.json",
        },
        "spans": {"kjv": nest(kjv_spans), "asv": nest(asv_spans)},
    }
    with open(MAP_PATH, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1, sort_keys=False)
    print(f"\nWrote {MAP_PATH}")


if __name__ == "__main__":
    main()
