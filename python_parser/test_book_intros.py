"""
Tests for the "About this book" introduction pipeline (parse_book_intros.py).

Two things are pinned here. First, the re-flow that turns a commentary's
wall-of-text intro into readable paragraphs must never change the text — it
only chooses where the breaks go. It silently dropped a paragraph (and
duplicated another) in 22 of the shipped intros before the tail-fold below was
fixed, which no assertion caught. Second, an enumerator ("II.", "[1.]") opens
the point it numbers, so it must never be left stranded at the end of a
paragraph.

Run with:
    python3 -m unittest discover -s python_parser
"""

import json
import os
import unittest

from parse_book_intros import (
    MIN_TAIL_CHARS,
    SOFT_MAX_CHARS,
    readable_paragraphs,
    soft_wrap,
    split_sentences,
    _trailing_enumerator,
)

HERE = os.path.dirname(os.path.abspath(__file__))
TEXT_DIR = os.path.join(HERE, "..", "ios", "swiftbible", "Text")
ANDROID_ASSET_DIR = os.path.join(HERE, "..", "android", "app", "src", "main", "assets")
INTRO_FILES = ["book_intros_mhcc.json", "book_intros_jfb.json", "book_intros_swiftbible.json"]


def words(text):
    return " ".join(text.split())


class ReflowTests(unittest.TestCase):
    """Breaking a long paragraph into readable ones."""

    def test_a_short_paragraph_is_left_alone(self):
        short = "Concerning this epistle we must enquire into its authority."
        self.assertEqual(soft_wrap(short), [short])

    def test_every_word_survives_the_re_flow(self):
        # Sentences sized so the last chunk falls under MIN_TAIL_CHARS and is
        # folded back — the case that used to overwrite the wrong chunk.
        body = " ".join(f"This is sentence number {n} of the introduction, and it runs on for a while." for n in range(12))
        tail = "A short closing remark."
        paragraph = f"{body} {tail}"
        self.assertGreater(len(paragraph), SOFT_MAX_CHARS)

        chunks = soft_wrap(paragraph)
        self.assertGreater(len(chunks), 1)
        self.assertEqual(words(" ".join(chunks)), words(paragraph))

    def test_a_runt_tail_is_folded_into_the_chunk_before_it(self):
        sentences = [f"Sentence {n} is long enough to matter here and carries real weight." for n in range(9)]
        paragraph = " ".join(sentences) + " A short tail."
        chunks = soft_wrap(paragraph)
        self.assertTrue(chunks[-1].endswith("A short tail."))
        self.assertGreaterEqual(len(chunks[-1]), MIN_TAIL_CHARS)
        self.assertEqual(words(" ".join(chunks)), words(paragraph))

    def test_chunks_break_between_sentences_never_inside_one(self):
        paragraph = " ".join(f"Sentence {n} says something worth saying about the book." for n in range(20))
        for chunk in soft_wrap(paragraph):
            self.assertTrue(chunk.endswith("."), chunk)

    def test_paragraph_boundaries_from_the_source_are_kept(self):
        first = "A short opening paragraph."
        second = "A second, separate paragraph."
        self.assertEqual(readable_paragraphs([first, second]), [first, second])


class SentenceSplitTests(unittest.TestCase):
    """What counts as the end of a sentence in 18th-century commentary prose."""

    def test_an_abbreviation_does_not_end_a_sentence(self):
        text = "It was written about A. D. 97, in the reign of Domitian. The church received it."
        self.assertEqual(len(split_sentences(text)), 2)

    def test_a_cited_chapter_does_not_end_a_sentence(self):
        text = "He was fed by that word, Hab. ii. 4. The prophet says so."
        first, second = split_sentences(text)
        self.assertTrue(first.endswith("Hab. ii. 4."))
        self.assertEqual(second, "The prophet says so.")

    def test_an_enumerator_opens_the_point_it_numbers(self):
        text = (
            "Concerning this epistle we must enquire, I. Into the divine authority of it. "
            "II. As to the divine amanuensis, we are not so certain."
        )
        sentences = split_sentences(text)
        self.assertTrue(sentences[0].endswith("authority of it."))
        self.assertTrue(sentences[1].startswith("II. As to"))

    def test_an_arabic_enumerator_is_carried_forward_too(self):
        text = "His length of life is patriarchal, two hundred years. 2. He speaks of the earliest idolatry."
        sentences = split_sentences(text)
        self.assertTrue(sentences[0].endswith("two hundred years."))
        self.assertTrue(sentences[1].startswith("2. He speaks"))

    def test_a_bracketed_enumerator_is_carried_forward_too(self):
        text = "One copy inscribes it to Luke the Evangelist. [1.] The first head is this."
        sentences = split_sentences(text)
        self.assertTrue(sentences[0].endswith("Luke the Evangelist."))
        self.assertTrue(sentences[1].startswith("[1.] The first head"))

    def test_a_verse_number_closing_a_citation_stays_put(self):
        # "12." here finishes "Hos. viii. 12.", it does not open a new point.
        text = "Counted as a strange thing, Hos. viii. 12. The prophet complains of it."
        self.assertEqual(_trailing_enumerator("Counted as a strange thing, Hos. viii. 12."), ("Counted as a strange thing, Hos. viii. 12.", ""))
        self.assertEqual(len(split_sentences(text)), 2)

    def test_a_one_word_sentence_is_not_mistaken_for_an_enumerator(self):
        self.assertEqual(_trailing_enumerator("He asked whether it was canonical. No."), ("He asked whether it was canonical. No.", ""))


class ShippedIntroTests(unittest.TestCase):
    """Invariants of the JSON the apps actually bundle."""

    @classmethod
    def setUpClass(cls):
        cls.intros = {}
        for name in INTRO_FILES:
            with open(os.path.join(TEXT_DIR, name), encoding="utf-8") as handle:
                cls.intros[name] = json.load(handle)["bookIntros"]

    def test_no_paragraph_is_left_holding_a_bare_enumerator(self):
        for name, books in self.intros.items():
            for book, intro in books.items():
                for paragraph in intro["paragraphs"]:
                    _, stranded = _trailing_enumerator(paragraph)
                    self.assertEqual(stranded, "", f"{name} / {book}: paragraph ends on {stranded!r}")

    def test_no_paragraph_is_empty(self):
        for name, books in self.intros.items():
            for book, intro in books.items():
                self.assertTrue(intro["paragraphs"], f"{name} / {book}: no paragraphs")
                for paragraph in intro["paragraphs"]:
                    self.assertTrue(paragraph.strip(), f"{name} / {book}: empty paragraph")
                    self.assertEqual(paragraph, paragraph.strip(), f"{name} / {book}: unstripped paragraph")

    def test_no_paragraph_repeats_the_opening_of_another(self):
        # The shape the mis-folded tail left behind: one chunk written over its
        # neighbour, so two paragraphs of a book start with the same text and a
        # third is gone entirely. It hit 22 books before the fold was fixed.
        for name, books in self.intros.items():
            for book, intro in books.items():
                openings = [p[:120] for p in intro["paragraphs"] if len(p) >= 120]
                self.assertEqual(len(openings), len(set(openings)), f"{name} / {book}: paragraph repeated")

    def test_ios_and_android_bundle_the_same_bytes(self):
        for name in INTRO_FILES:
            with open(os.path.join(TEXT_DIR, name), "rb") as ios, \
                    open(os.path.join(ANDROID_ASSET_DIR, name), "rb") as android:
                self.assertEqual(ios.read(), android.read(), f"{name} differs between iOS and Android")


if __name__ == "__main__":
    unittest.main()
