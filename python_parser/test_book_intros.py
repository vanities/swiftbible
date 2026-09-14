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
import re
import unittest

from parse_book_intros import (
    MIN_TAIL_CHARS,
    SOFT_MAX_CHARS,
    format_intro,
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

    def test_a_short_opening_sentence_is_not_left_as_its_own_chunk(self):
        long_sentence = "The design of the epistle " + "is to show the superiority of Christ, " * 20 + "and so on."
        chunks = soft_wrap(f"Design.--{long_sentence} {long_sentence}")
        self.assertTrue(chunks[0].startswith("Design.-- The design"), chunks[0][:40])

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

    def test_an_enumerator_after_a_closing_quote_is_carried_forward(self):
        # Micah: the point before ends on a quoted question.
        text = 'Why then should we punish Jeremiah for saying the same?" 2. Another is a prediction.'
        sentences = split_sentences(text)
        self.assertTrue(sentences[0].endswith('the same?"'))
        self.assertTrue(sentences[1].startswith("2. Another"))

    def test_an_enumerator_introduced_by_a_comma_stays_inline(self):
        # John: "we may observe, 1. That he relates..." — like "enquire, I. Into",
        # the marker sits mid-sentence and must not be read as a full stop.
        text = "Comparing his gospel with theirs, we may observe, 1. That he relates what they had omitted."
        self.assertEqual(split_sentences(text), [text])

    def test_a_verse_list_closing_a_citation_still_ends_the_sentence(self):
        # "2, 3." is a verse list, not a comma-introduced marker; the "3." after
        # it opens the next point.
        text = "It was written upon great stones, ch. xxvii. 2, 3. 3. It was to be read publicly."
        sentences = split_sentences(text)
        self.assertTrue(sentences[0].endswith("ch. xxvii. 2, 3."))
        self.assertTrue(sentences[1].startswith("3. It was"))

    def test_a_number_after_a_chapter_range_opens_the_next_point(self):
        # Joshua: "ch. xiii.-xxi. 4." — a range of chapters takes no verse
        # number, so the "4." numbers the point that follows.
        text = "In the distribution of the land, ch. xiii.-xxi. 4. In the settlement of religion, ch. xxii.-xxiv."
        sentences = split_sentences(text)
        self.assertTrue(sentences[0].endswith("ch. xiii.-xxi."))
        self.assertTrue(sentences[1].startswith("4. In the settlement"))

    def test_a_one_word_sentence_is_not_mistaken_for_an_enumerator(self):
        self.assertEqual(_trailing_enumerator("He asked whether it was canonical. No."), ("He asked whether it was canonical. No.", ""))


class TypographyTests(unittest.TestCase):
    """The markup format_intro adds: "## " headings, **bold**, em dashes."""

    def test_a_run_in_head_becomes_a_heading_paragraph(self):
        self.assertEqual(
            format_intro(['Where Job Lived.--"Uz," according to Gesenius, means a light soil.'], run_in_heads=True),
            ["## Where Job Lived", '"Uz," according to Gesenius, means a light soil.'],
        )

    def test_a_numbered_run_in_head_keeps_its_number(self):
        self.assertEqual(
            format_intro(["II. Inspiration and Authorship.--With no important exception, it is received."], run_in_heads=True)[0],
            "## II. Inspiration and Authorship",
        )

    def test_a_head_set_in_small_caps_reads_in_sentence_case(self):
        self.assertEqual(
            format_intro(["The OBJECT OF THE EPISTLE.--Thessalonica was at this time capital."], run_in_heads=True),
            ["## The object of the epistle", "Thessalonica was at this time capital."],
        )

    def test_a_capitalised_opening_word_is_not_emphasis(self):
        self.assertEqual(format_intro(["Date of writing.--AS the Epistle is written jointly."], run_in_heads=True)[1], "As the Epistle is written jointly.")

    def test_small_caps_emphasis_becomes_bold(self):
        self.assertEqual(
            format_intro(["The TIME OF WRITING was after Pentecost."]),
            ["The **time of writing** was after Pentecost."],
        )

    def test_true_capitals_are_left_alone(self):
        text = "The LXX renders it so, and Psalm CXIX. agrees."
        self.assertEqual(format_intro([text]), [text])

    def test_double_hyphens_become_em_dashes(self):
        self.assertEqual(format_intro(["As to the name Job--repentance--it was common."]), ["As to the name Job—repentance—it was common."])

    def test_only_jfb_sets_run_in_heads(self):
        text = "It is so.--The book was thus entitled."
        self.assertEqual(format_intro([text]), ["It is so. The book was thus entitled."])

    def test_a_dash_joining_punctuation_is_dropped(self):
        self.assertEqual(format_intro(["They may be thus briefly given:--David the devout."]), ["They may be thus briefly given: David the devout."])
        self.assertEqual(format_intro(["It perishes in a night.-- The Bible began."]), ["It perishes in a night. The Bible began."])

    def test_a_sentence_run_on_with_a_dash_can_be_split(self):
        self.assertEqual(split_sentences("It perishes in a night.--The Bible began."), ["It perishes in a night.--", "The Bible began."])

    def test_point_markers_are_bold(self):
        self.assertEqual(
            format_intro(["Concerning this epistle we must enquire, I. Into its authority. 2. Into its penman. [3.] Its scope: (1) the Jews."]),
            ["Concerning this epistle we must enquire, **I.** Into its authority. **2.** Into its penman. **[3.]** Its scope: **(1)** the Jews."],
        )

    def test_an_outline_point_after_a_chapter_citation_is_bold(self):
        self.assertEqual(
            format_intro(["Their reigns, ch. xv. and xvi. V. Elijah's miracles, ch. xvii.-xix."]),
            ["Their reigns, ch. xv. and xvi. **V.** Elijah's miracles, ch. xvii.-xix."],
        )

    def test_a_parenthesised_point_after_a_word_is_bold(self):
        self.assertEqual(format_intro(["Devotional, expressive of (1) Penitence."]), ["Devotional, expressive of **(1)** Penitence."])
        self.assertEqual(format_intro(["Psalms 18 (1) of them."]), ["Psalms 18 (1) of them."])

    def test_citations_are_not_mistaken_for_markers(self):
        for text in [
            "Counted as a strange thing, Hos. viii. 12. The prophet complains.",
            "Written upon great stones, ch. xxvii. 2, 3. It was read.",
            "About A.D. 57. Paul left Ephesus.",
            "The number of them in all 299. It was so.",
            "See 1 Sam. ii. 7, 8; Ps. cxiii. 7-9.",
        ]:
            self.assertEqual(format_intro([text]), [text], text)

    def test_a_number_after_a_chapter_range_is_a_marker(self):
        self.assertEqual(
            format_intro(["In their conquest, ch. vi.-xii. 3. In the distribution."]),
            ["In their conquest, ch. vi.-xii. **3.** In the distribution."],
        )


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

    def test_no_paragraph_ends_on_a_marker_after_a_word(self):
        # Independent of _trailing_enumerator, which the check above shares with
        # the parser and so cannot see its blind spots. A numeral closing a
        # paragraph is a citation only when a reference precedes it ("viii. 12.",
        # "2, 3.", "A.D. 57."); after a plain word, comma, closing quote or chapter
        # range it is a stranded marker ("we may observe, 1.", 'the same?" 2.',
        # "ch. xiii.-xxi. 4.").
        stranded_re = re.compile(r'(?:[a-z]{2,},|["”]|[ivxlc]+\.-[ivxlc]+\.)\s+(?:\d{1,3}|[IVX]+)\.$')
        for name, books in self.intros.items():
            for book, intro in books.items():
                for paragraph in intro["paragraphs"]:
                    self.assertIsNone(stranded_re.search(paragraph), f"{name} / {book}: …{paragraph[-60:]}")

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

    def test_markup_is_well_formed(self):
        # The apps parse exactly two constructs; anything else would render as
        # literal punctuation.
        for name, books in self.intros.items():
            for book, intro in books.items():
                for paragraph in intro["paragraphs"]:
                    where = f"{name} / {book}: {paragraph[:60]}"
                    self.assertEqual(paragraph.count("**") % 2, 0, where)
                    self.assertNotIn("--", paragraph, where)
                    self.assertNotIn("****", paragraph, where)
                    if paragraph.startswith("## "):
                        self.assertLessEqual(len(paragraph), 80, where)
                        self.assertNotIn("**", paragraph, where)
                    else:
                        self.assertNotIn("## ", paragraph, where)

    def test_ios_and_android_bundle_the_same_bytes(self):
        for name in INTRO_FILES:
            with open(os.path.join(TEXT_DIR, name), "rb") as ios, \
                    open(os.path.join(ANDROID_ASSET_DIR, name), "rb") as android:
                self.assertEqual(ios.read(), android.read(), f"{name} differs between iOS and Android")


if __name__ == "__main__":
    unittest.main()
