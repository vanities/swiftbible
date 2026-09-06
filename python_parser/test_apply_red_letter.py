"""
Tests for the red letter (Words of Jesus) pipeline.

The tags in bible.json and asv.json are no longer inferred from the text: they
come from red_letter_map.json, built from the KJV's own OSIS <q who="Jesus">
markup. So there are two things to pin — that a span becomes the right
characters of a verse, and that the shipped files still say what the map says.

Run with:
    python3 -m unittest discover -s python_parser
"""

import json
import os
import re
import unittest

from apply_red_letter import load_spans, tag_text
from red_letter_common import paragraph_segments, verse_map

HERE = os.path.dirname(os.path.abspath(__file__))
TEXT_DIR = os.path.join(HERE, "..", "ios", "swiftbible", "Text")


class TagPlacementTests(unittest.TestCase):
    """Turning a word range into <JESUS> tags."""

    def test_span_keeps_the_punctuation_that_closes_it(self):
        verse = (
            "And when he was come into the house, the blind men came to him: "
            "and Jesus saith unto them, Believe ye that I am able to do this? "
            "They said unto him, Yea, Lord. "
        )
        self.assertEqual(
            tag_text(verse, [[19, 28]]),
            "And when he was come into the house, the blind men came to him: "
            "and Jesus saith unto them, "
            "<JESUS>Believe ye that I am able to do this?</JESUS>"
            " They said unto him, Yea, Lord. ",
        )

    def test_two_spans_in_one_verse(self):
        """Luke 8:45 quotes Jesus twice, with the crowd in between."""
        verse = (
            "And Jesus said, Who touched me? When all denied, Peter and they "
            "that were with him said, Master, and sayest thou, Who touched me? "
        )
        tagged = tag_text(verse, [[3, 6], [21, 24]])
        self.assertEqual(tagged.count("<JESUS>"), 2)
        self.assertIn("<JESUS>Who touched me?</JESUS> When all denied", tagged)
        self.assertTrue(tagged.rstrip().endswith("<JESUS>Who touched me?</JESUS>"))

    def test_a_phrase_quoted_inside_someone_elses_sentence(self):
        """John 8:33 — the crowd speaks, quoting four words of Jesus."""
        verse = (
            "They answered him, We be Abraham's seed, and were never in bondage "
            "to any man: how sayest thou, Ye shall be made free? "
        )
        tagged = tag_text(verse, [[19, 24]])
        self.assertIn("how sayest thou, <JESUS>Ye shall be made free?</JESUS>", tagged)
        self.assertNotIn("<JESUS>They answered", tagged)

    def test_a_span_ending_before_an_inline_verse_marker(self):
        """The marker between two verses must stay outside the tags."""
        verse = "Follow me. "
        self.assertEqual(tag_text(verse, [[0, 2]]), "<JESUS>Follow me.</JESUS> ")

    def test_a_verse_with_no_spans_is_untouched(self):
        verse = "And he did not many mighty works there because of their unbelief. "
        self.assertEqual(tag_text(verse, []), verse)

    def test_out_of_range_spans_are_ignored_rather_than_crashing(self):
        verse = "Peace, be still. "
        self.assertEqual(tag_text(verse, [[0, 99]]), verse)


class ShippedTextTests(unittest.TestCase):
    """The tags in the app's JSON must be exactly what the map says.

    This is the guard against the files and the map drifting apart — someone
    hand-editing a verse, or rebuilding one without the other.
    """

    @classmethod
    def setUpClass(cls):
        cls.files = {
            "kjv": os.path.join(TEXT_DIR, "bible.json"),
            "asv": os.path.join(TEXT_DIR, "asv.json"),
        }

    def test_every_shipped_tag_comes_from_the_map(self):
        for version, path in self.files.items():
            with self.subTest(version=version):
                spans = load_spans(version)
                with open(path, "r", encoding="utf-8") as f:
                    data = json.load(f)

                seen = 0
                for book in data:
                    for chapter in book["chapters"]:
                        for paragraph in chapter["paragraphs"]:
                            plain, segments = paragraph_segments(paragraph, chapter["number"])
                            tagged, _ = paragraph_segments(
                                paragraph, chapter["number"], strip=False
                            )
                            for verse, start, end in segments:
                                ranges = spans.get((book["name"], chapter["number"], verse))
                                if not ranges:
                                    continue
                                self.assertIn(
                                    tag_text(plain[start:end], ranges).strip(),
                                    tagged,
                                    f"{book['name']} {chapter['number']}:{verse} "
                                    f"does not match the map — rerun apply_red_letter.py",
                                )
                                seen += 1
                self.assertGreater(seen, 2000)

    def test_tags_are_balanced_and_never_empty(self):
        for version, path in self.files.items():
            with self.subTest(version=version):
                with open(path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                for book in data:
                    for chapter in book["chapters"]:
                        for paragraph in chapter["paragraphs"]:
                            text = paragraph["text"]
                            self.assertEqual(
                                text.count("<JESUS>"), text.count("</JESUS>"),
                                f"unbalanced tags in {book['name']} {chapter['number']}",
                            )
                            for match in re.finditer(r"<JESUS>(.*?)</JESUS>", text, re.S):
                                self.assertTrue(
                                    match.group(1).strip(),
                                    f"empty tag in {book['name']} {chapter['number']}",
                                )


class KnownVerseTests(unittest.TestCase):
    """The verses that drove this pipeline, checked against the shipped text."""

    @classmethod
    def setUpClass(cls):
        cls.kjv = verse_map(os.path.join(TEXT_DIR, "bible.json"), strip=False)

    def test_the_blind_mens_answer_is_not_in_red(self):
        """Matthew 9:28 — the bug that started this."""
        verse = self.kjv[("Matthew", 9, 28)]
        self.assertIn("<JESUS>Believe ye that I am able to do this?</JESUS>", verse)
        self.assertNotIn("<JESUS>Yea, Lord.", verse)

    def test_a_verse_carrying_two_separate_quotations(self):
        """Luke 8:45 — one span the old single-span model could not express."""
        self.assertEqual(self.kjv[("Luke", 8, 45)].count("<JESUS>"), 2)

    def test_only_the_quoted_phrase_of_an_opponents_speech(self):
        """John 8:33 — the crowd's words are theirs; four of them are Jesus's."""
        verse = self.kjv[("John", 8, 33)]
        self.assertIn("<JESUS>Ye shall be made free?</JESUS>", verse)
        self.assertNotIn("<JESUS>They answered", verse)

    def test_narrative_after_the_last_words_stays_black(self):
        """John 19:30 — "and he bowed his head" is the evangelist, not Jesus."""
        verse = self.kjv[("John", 19, 30)]
        self.assertIn("<JESUS>It is finished:</JESUS>", verse)
        self.assertNotIn("bowed his head</JESUS>", verse)

    def test_a_narrative_verse_the_source_reddened_by_mistake(self):
        """Matthew 24:1 — an OSIS quotation left open over a whole paragraph."""
        self.assertNotIn("<JESUS>", self.kjv[("Matthew", 24, 1)])

    def test_a_quotation_the_source_omits_is_restored_by_override(self):
        """Matthew 13:57 — red_letter_overrides.json puts it back."""
        self.assertIn("<JESUS>A prophet is not without honour",
                      self.kjv[("Matthew", 13, 57)])


if __name__ == "__main__":
    unittest.main()
