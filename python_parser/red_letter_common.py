"""
Shared pieces for the red letter (Words of Jesus) pipeline.

Both the map builder and the tag applier have to agree, exactly, on two things:
where one verse ends and the next begins inside a KJV-style multi-verse
paragraph, and how a verse's text is cut into words. Spans are stored as word
index ranges, so any disagreement here silently moves the tags.
"""

import json
import re

# Words are letter runs. Digits are deliberately excluded so the inline
# "9:28" verse markers in KJV paragraphs cannot shift a span's indices, and
# so punctuation and spelling of the surrounding text stay irrelevant.
WORD_PATTERN = re.compile(r"[A-Za-z]+")

# Punctuation that belongs to the speech it closes: "…do this?" keeps its
# question mark. Deliberately no opening bracket — Matthew 9:6 ends a span at
# "to forgive sins, (" and the matching ")" is three words into the narrative
# aside that follows.
TRAILING_PUNCTUATION = re.compile(r"[.,;:!?…—\-)\]}]*")

# ...and the mirror: a bracket hugging the first word opens the speech with it,
# so the ASV's "[If any man hath ears to hear, let him hear.]" is red on both
# sides rather than losing its opening bracket to the narrative.
LEADING_PUNCTUATION = "([{"

INLINE_VERSE_PATTERN = re.compile(r"\b(\d+):(\d+[a-z]?)\b")


def strip_jesus_tags(text):
    """Remove existing <JESUS> tags from text."""
    return text.replace("<JESUS>", "").replace("</JESUS>", "")


def verse_segments(text, chapter_number, starting_verse):
    """Cut a paragraph into (verse_number, start, end) character ranges.

    KJV and ASV paragraphs hold several verses, separated by inline markers
    like "9:28". The markers belong to no verse and are left out of every
    range, so tags never land on one. `text` must already have its <JESUS>
    tags stripped.
    """
    segments = []
    current, position = starting_verse, 0
    for match in INLINE_VERSE_PATTERN.finditer(text):
        if int(match.group(1)) != chapter_number:
            continue  # a cross-reference to another chapter, not a marker
        segments.append((current, position, match.start()))
        current = int(re.match(r"\d+", match.group(2)).group())
        position = match.end()
    segments.append((current, position, len(text)))
    return [s for s in segments if text[s[1]:s[2]].strip()]


def paragraph_segments(paragraph, chapter_number, strip=True):
    """verse_segments() applied to a paragraph dict.

    `strip=False` keeps any <JESUS> tags in place, for reading a translation
    that already carries them (web.json) rather than writing them.
    """
    text = paragraph["text"]
    if strip:
        text = strip_jesus_tags(text)
    return text, verse_segments(text, chapter_number, paragraph["startingVerse"])


def words_in(text):
    """The word tokens of a verse, as (word, start, end) triples."""
    return [(m.group(0), m.start(), m.end()) for m in WORD_PATTERN.finditer(text)]


def iter_verses(bible_path, strip=True):
    """Yield (book, chapter, verse, text) for every verse in a bible JSON file."""
    with open(bible_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    for book in data:
        for chapter in book["chapters"]:
            for paragraph in chapter["paragraphs"]:
                text, segments = paragraph_segments(paragraph, chapter["number"], strip)
                for verse, start, end in segments:
                    yield book["name"], chapter["number"], verse, text[start:end]


def verse_map(bible_path, strip=True):
    """{(book, chapter, verse): text} for a whole bible JSON file."""
    return {
        (book, chapter, verse): text
        for book, chapter, verse, text in iter_verses(bible_path, strip)
    }
