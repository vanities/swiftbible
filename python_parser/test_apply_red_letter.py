"""
Tests for the red letter post-processor's speaker attribution.

KJV and ASV have no native red letter markup, so apply_red_letter.py infers
where Jesus's words start and end from the speech-introducing verbs, using WEB's
<wj> tags only for *which* verses contain them. The failure mode these pin down
is a verse ending in someone else's reply — Matthew 9:28's "They said unto him,
Yea, Lord." — where the last speech verb belongs to the other speaker and the
reply, not Jesus's question, ended up in red.

Run with:
    python3 -m unittest discover -s python_parser
"""

import unittest

from apply_red_letter import tag_verse_text


class ReplyAttributionTests(unittest.TestCase):
    """Verses that end with another speaker answering Jesus."""

    def test_blind_mens_answer_stays_out_of_red(self):
        """The reported bug: Matthew 9:28 put "Yea, Lord." on Jesus."""
        verse = (
            "And when he was come into the house, the blind men came to him: "
            "and Jesus saith unto them, Believe ye that I am able to do this? "
            "They said unto him, Yea, Lord. "
        )
        self.assertEqual(
            tag_verse_text(verse, "both"),
            "And when he was come into the house, the blind men came to him: "
            "and Jesus saith unto them, "
            "<JESUS>Believe ye that I am able to do this?</JESUS>"
            " They said unto him, Yea, Lord. ",
        )

    def test_reply_opening_the_trail_pattern_does_not_know(self):
        """Matthew 13:51 answers with "They say", not "They said"."""
        verse = (
            "Jesus saith unto them, Have ye understood all these things? "
            "They say unto him, Yea, Lord. "
        )
        self.assertEqual(
            tag_verse_text(verse, "both"),
            "Jesus saith unto them, "
            "<JESUS>Have ye understood all these things?</JESUS>"
            " They say unto him, Yea, Lord. ",
        )

    def test_reply_introduced_by_a_named_disciple(self):
        """Luke 9:20 — "Peter answering said," is a reply, not Jesus."""
        verse = (
            "He said unto them, But whom say ye that I am? "
            "Peter answering said, The Christ of God. "
        )
        self.assertEqual(
            tag_verse_text(verse, "both"),
            "He said unto them, <JESUS>But whom say ye that I am?</JESUS>"
            " Peter answering said, The Christ of God. ",
        )

    def test_reply_introduced_by_a_pronoun(self):
        """Mark 9:21 — the father answers, and both intros are "he"."""
        verse = (
            "And he asked his father, How long is it ago since this came unto him? "
            "And he said, Of a child. "
        )
        self.assertEqual(
            tag_verse_text(verse, "both"),
            "And he asked his father, "
            "<JESUS>How long is it ago since this came unto him?</JESUS>"
            " And he said, Of a child. ",
        )

    def test_jesus_speaking_last_is_left_alone(self):
        """John 18:5 — the crowd answers first and Jesus speaks last.

        The trailing narrative ("And Judas also...") is not one the trail
        pattern recognises, so the tagger finds no speech end. That must not be
        read as evidence of a reply: the last verb names Jesus.
        """
        verse = (
            "They answered him, Jesus of Nazareth. Jesus saith unto them, "
            "I am he.  And Judas also, which betrayed him, stood with them. "
        )
        self.assertIn(
            "<JESUS>I am he.",
            tag_verse_text(verse, "both"),
        )


class UnchangedBehaviourTests(unittest.TestCase):
    """The paths the reply handling must not disturb."""

    def test_full_verse_is_tagged_whole(self):
        verse = "Come unto me, all ye that labour and are heavy laden. "
        self.assertEqual(
            tag_verse_text(verse, "full"),
            f"<JESUS>{verse}</JESUS>",
        )

    def test_narrative_intro_then_speech_to_the_end(self):
        verse = "And he said unto them, Follow me, and I will make you fishers of men. "
        self.assertEqual(
            tag_verse_text(verse, "intro_only"),
            "And he said unto them, "
            "<JESUS>Follow me, and I will make you fishers of men. </JESUS>",
        )

    def test_recognised_trailing_narrative_still_ends_the_speech(self):
        verse = "And he saith unto them, Why are ye fearful, O ye of little faith? Then he arose. "
        self.assertEqual(
            tag_verse_text(verse, "both"),
            "And he saith unto them, "
            "<JESUS>Why are ye fearful, O ye of little faith?</JESUS>"
            " Then he arose. ",
        )

    def test_answered_and_said_takes_the_later_verb(self):
        """"answered and said," is one introduction, not two speakers."""
        verse = "But he answered and said unto them, An evil generation seeketh after a sign. "
        self.assertEqual(
            tag_verse_text(verse, "intro_only"),
            "But he answered and said unto them, "
            "<JESUS>An evil generation seeketh after a sign. </JESUS>",
        )

    def test_speech_first_then_narrative(self):
        verse = "Peace, be still. And the wind ceased, and there was a great calm. "
        self.assertEqual(
            tag_verse_text(verse, "trail_only"),
            "<JESUS>Peace, be still.</JESUS>"
            " And the wind ceased, and there was a great calm. ",
        )

    def test_verse_with_no_speech_intro_falls_back_to_the_whole_verse(self):
        verse = "For the Son of man is Lord even of the sabbath day. "
        self.assertEqual(
            tag_verse_text(verse, "intro_only"),
            f"<JESUS>{verse}</JESUS>",
        )


if __name__ == "__main__":
    unittest.main()
