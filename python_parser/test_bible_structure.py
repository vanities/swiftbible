"""Structure of the shipped Bible texts, and the KJV parser that builds bible.json.

parse_kjv.py once started a chapter only at the beginning of a line, and
kjv.txt opens 33 chapters mid-line ("how shall ye believe my words? 6:1 After
these things..."). Both apps render an inline marker as a bare verse number,
so 48 verses sat at the end of the previous chapter and John 6 began at
verse 2 (reported 2026-11-19).
"""

import contextlib
import hashlib
import io
import json
import os
import re
import tempfile
import unittest

from parse_kjv import parse_bible_file
from red_letter_common import strip_jesus_tags

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
TEXT = os.path.join(REPO, "ios", "swiftbible", "Text")

# The inline marker both apps render (iOS ParagraphParser.verseRegex, Android
# INLINE_VERSE_MARKER). Neither shows the marker's chapter, only its verse.
MARKER = re.compile(r"\b(\d+):(\d+)([a-z]?)\b")

VERSES_IN_THE_BIBLE = 31102

# Verses the WEB's source text leaves out, as modern critical editions do. The
# KJV and ASV carry them.
WEB_OMITS = {("Luke", 17, 36), ("Acts", 8, 37), ("Acts", 15, 34), ("Acts", 24, 7)}

# Copies of the iOS texts that ship elsewhere, byte for byte.
COPIES = {
    "bible.json": [
        "android/app/src/main/assets/bible.json",
        "supabase/functions/daily-devotional/bible.json",
    ],
    "asv.json": ["android/app/src/main/assets/asv.json"],
    "web.json": ["android/app/src/main/assets/web.json"],
}

GENESIS = "The First Book of Moses: Called Genesis"


def load(name):
    with open(os.path.join(TEXT, name), encoding="utf-8") as f:
        return json.load(f)


def verse_numbers(chapter):
    """The chapter's verse numbers in reading order, and markers from other chapters."""
    numbers, foreign = [], []
    for paragraph in chapter["paragraphs"]:
        numbers.append(paragraph["startingVerse"])
        for marker in MARKER.finditer(strip_jesus_tags(paragraph["text"])):
            if int(marker.group(1)) == chapter["number"]:
                numbers.append(int(marker.group(2)))
            else:
                foreign.append(marker.group(0))
    return numbers, foreign


def quietly_parse(path):
    """parse_bible_file() without its per-book progress lines."""
    with contextlib.redirect_stdout(io.StringIO()):
        return parse_bible_file(path)


def parse_text(text):
    with tempfile.TemporaryDirectory() as tmp:
        path = os.path.join(tmp, "kjv.txt")
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        return quietly_parse(path)


class ShippedTextTests(unittest.TestCase):
    def test_every_chapter_runs_from_verse_1_in_order(self):
        for name, omitted in (("bible.json", set()), ("asv.json", set()), ("web.json", WEB_OMITS)):
            with self.subTest(translation=name):
                out_of_order, foreign, total = [], [], 0
                for book in load(name):
                    for chapter in book["chapters"]:
                        where = f"{book['name']} {chapter['number']}"
                        numbers, strays = verse_numbers(chapter)
                        foreign += [f"{where} holds {s}" for s in strays]
                        expected = [
                            v for v in range(1, max(numbers) + 1)
                            if (book["name"], chapter["number"], v) not in omitted
                        ]
                        if numbers != expected:
                            out_of_order.append(f"{where} starts {numbers[:3]}")
                        total += len(numbers)
                self.assertEqual(foreign, [], "verse markers from another chapter")
                self.assertEqual(out_of_order, [], "chapters whose verses do not run 1..N")
                self.assertEqual(total, VERSES_IN_THE_BIBLE - len(omitted))

    def test_john_6_opens_with_verse_1(self):
        for name in ("bible.json", "asv.json", "web.json"):
            with self.subTest(translation=name):
                john = next(b for b in load(name) if b["name"] == "John")
                chapters = {c["number"]: c for c in john["chapters"]}
                first = chapters[6]["paragraphs"][0]
                self.assertEqual(first["startingVerse"], 1)
                self.assertIn("After these things", first["text"])
                self.assertNotIn("6:1", chapters[5]["paragraphs"][-1]["text"])

    def test_every_copy_matches_the_ios_text(self):
        for name, copies in COPIES.items():
            with open(os.path.join(TEXT, name), "rb") as f:
                expected = hashlib.sha256(f.read()).hexdigest()
            for copy in copies:
                with self.subTest(copy=copy):
                    with open(os.path.join(REPO, copy), "rb") as f:
                        actual = hashlib.sha256(f.read()).hexdigest()
                    self.assertEqual(actual, expected, f"{copy} differs from ios/swiftbible/Text/{name}")


class ParseKjvTests(unittest.TestCase):
    def test_a_chapter_opening_mid_line_starts_its_chapter(self):
        bible = parse_text(
            f"{GENESIS}\n\n"
            "1:1 First verse.\n\n"
            "1:2 Ends here? 2:1 The next chapter\n"
            "goes on.\n\n"
            "2:2 More 2:3 inline.\n"
        )
        one, two = bible[0]["chapters"]
        self.assertEqual(one["paragraphs"][-1], {"startingVerse": 2, "text": "Ends here? "})
        self.assertEqual(two["number"], 2)
        self.assertEqual(two["paragraphs"][0], {"startingVerse": 1, "text": "The next chapter goes on. "})
        # Within a chapter a mid-line marker stays inline: the apps render it.
        self.assertEqual(two["paragraphs"][1], {"startingVerse": 2, "text": "More 2:3 inline. "})

    def test_a_chapter_opening_at_the_end_of_a_line_takes_the_next_line(self):
        bible = parse_text(f"{GENESIS}\n\n1:1 How are the mighty fallen! 2:1\nAnd it came to pass.\n")
        one, two = bible[0]["chapters"]
        self.assertEqual(one["paragraphs"], [{"startingVerse": 1, "text": "How are the mighty fallen! "}])
        self.assertEqual(two["paragraphs"], [{"startingVerse": 1, "text": "And it came to pass. "}])

    def test_an_unexpected_chapter_jump_raises(self):
        with self.assertRaises(ValueError):
            parse_text(f"{GENESIS}\n\n1:1 Text 3:1 skips a chapter.\n")

    def test_shipped_kjv_is_the_parser_output(self):
        source = os.path.join(HERE, "kjv.txt")
        with open(source, "rb") as f:
            if f.read(40).startswith(b"version https://git-lfs"):
                self.skipTest("kjv.txt is a Git LFS pointer here (CI checks out without LFS)")
        parsed = {
            (book["name"], chapter["number"]): chapter["paragraphs"]
            for book in quietly_parse(source)
            for chapter in book["chapters"]
        }
        shipped = {
            (book["name"], chapter["number"]): [
                {**p, "text": strip_jesus_tags(p["text"])} for p in chapter["paragraphs"]
            ]
            for book in load("bible.json")
            for chapter in book["chapters"]
        }
        self.assertEqual(sorted(parsed), sorted(shipped))
        differing = [f"{b} {c}" for (b, c), paragraphs in shipped.items() if parsed[(b, c)] != paragraphs]
        self.assertEqual(
            differing, [],
            "bible.json is not what parse_kjv.py makes of kjv.txt: rerun it, then apply_red_letter.py",
        )


if __name__ == "__main__":
    unittest.main()
