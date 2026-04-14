"""
Inject hand-written chapter titles and passage summaries for the pseudepigrapha
and other non-canonical books into swiftbible/Text/summaries_swiftbible.json.

Background
----------
Matthew Henry's Concise Commentary covers only the 66 canonical Protestant books,
leaving the Apocrypha, the Book of Enoch, 2 Enoch, Jubilees, 1 Clement, the
Didache, and the Testaments of the Twelve Patriarchs uncovered by any source in
the app. This script adds entries for those books to the SwiftBible Curated
source so the picker has meaningful content for them as well — the SwiftBible
source effectively becomes the "everything" source while Matthew Henry remains
the canonical-only default.

The data is stored as Python literals in this file so it's reproducible,
auditable, and survives JSON regeneration. Run from python_parser/:

    uv run python3 add_pseudepigrapha_summaries.py

The script is **idempotent**: it only adds entries for chapters that don't
already have content in the target JSON. Existing entries (whether from
the original migration or a previous run of this script) are never overwritten,
so it's safe to re-run after extending PSEUDEPIGRAPHA_DATA.

Style guide for the summaries
-----------------------------
- Voice matches Matthew Henry's Concise Commentary: short, declarative,
  present-tense, theme-focused. NOT a quotation or paraphrase of the verse.
- Chapter title: 3-8 words capturing the main theme.
- Passage summary: one sentence (~15-25 words) describing what happens
  or what the chapter teaches, without recycling the verse's vocabulary.
"""
from __future__ import annotations

import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SUMMARIES = REPO / "swiftbible" / "Text" / "summaries_swiftbible.json"


# Pseudepigrapha + non-canonical book summaries.
#
# Schema:
#     {
#       "<Book Name>": {
#         "<chapter str>": {
#           "title": "<chapter list label>",
#           "passages": [
#             {"startVerse": N, "endVerse": N|None, "title": "<passage description>"}
#           ]
#         }
#       }
#     }
#
# Each book is added book-by-book over multiple commits. Books not yet
# represented here remain blank in the SwiftBible source — the runtime
# fallback chain still works, it just shows no entry for those chapters.
PSEUDEPIGRAPHA_DATA: dict[str, dict[str, dict]] = {
    # Didache (16 chapters) — earliest known Christian church manual,
    # late 1st / early 2nd century. Each chapter is one paragraph.
    "Didache": {
        "1": {
            "title": "The Two Ways: love and generosity",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "The 'Two Ways' framework introduced — the way of life summarized as love of God, love of neighbor, and radical generosity toward enemies.",
            }],
        },
        "2": {
            "title": "The second commandment: prohibitions of evil",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "An expanded decalogue: the prohibitions of murder, adultery, theft, magic, abortion, false speech, and double-mindedness.",
            }],
        },
        "3": {
            "title": "Avoiding the small steps that lead to great sins",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Pastoral warnings against the small habits — anger, lust, omens, lies, murmuring — that grow into the great sins.",
            }],
        },
        "4": {
            "title": "Honor of teachers, generosity, household duties",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Practical instructions on honoring teachers, sharing possessions, training children, and the mutual duties of slaves and masters.",
            }],
        },
        "5": {
            "title": "The way of death: a catalog of vices",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "A comprehensive list of the vices and dispositions that mark the way of death; readers are urged to escape from them.",
            }],
        },
        "6": {
            "title": "Closing the moral instruction; food offered to idols",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Closing exhortation to the moral teaching; permission for varied observance levels, but a firm warning against meat sacrificed to idols.",
            }],
        },
        "7": {
            "title": "Instructions for baptism",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Practical instructions for baptism: the trinitarian formula, preferred forms of water, and the fast that precedes the rite.",
            }],
        },
        "8": {
            "title": "Fasting and prayer practices",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Distinguishes Christian fasting and prayer from contemporary practice; appoints Wednesday and Friday fasts and the Lord's Prayer thrice daily.",
            }],
        },
        "9": {
            "title": "Eucharistic prayers over cup and bread",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "The earliest known Eucharistic liturgy: prayers over the cup and the broken bread, with the rule that only the baptized may receive.",
            }],
        },
        "10": {
            "title": "The thanksgiving after the Eucharist",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "The post-communion thanksgiving: praise for God's care of the Church and a final petition that grace come and the world pass away.",
            }],
        },
        "11": {
            "title": "Discerning true teachers and prophets from false",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Tests for traveling teachers, apostles, and prophets — including how long they may stay and what counts as a sign of fraud.",
            }],
        },
        "12": {
            "title": "Receiving and testing travelers",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "How to receive Christian travelers: hospitable but not indefinitely, and never supporting the idle who use the faith for gain.",
            }],
        },
        "13": {
            "title": "Supporting prophets and teachers with firstfruits",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "The provision for resident prophets and teachers, who receive the firstfruits as Israel's priests once did.",
            }],
        },
        "14": {
            "title": "The Lord's day assembly",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Sunday gathering for thanksgiving and breaking of bread, with reconciliation required before the offering can be pure.",
            }],
        },
        "15": {
            "title": "Appointment of bishops and deacons",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Appointment of bishops and deacons; manner of reproving fellow believers; their place alongside prophets and teachers.",
            }],
        },
        "16": {
            "title": "Watch for the coming of the Lord",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Apocalyptic warning to remain watchful: false prophets and the world-deceiver will arise, but those who endure will see the Lord come on the clouds.",
            }],
        },
    },
}


def main() -> None:
    if not SUMMARIES.exists():
        raise SystemExit(f"missing {SUMMARIES}")

    data = json.loads(SUMMARIES.read_text())

    titles_added = 0
    titles_kept = 0
    passages_added = 0
    passages_kept = 0

    for book, chapters in PSEUDEPIGRAPHA_DATA.items():
        data["chapterTitles"].setdefault(book, {})
        data["passageSummaries"].setdefault(book, {})
        for chap, entry in chapters.items():
            if chap in data["chapterTitles"][book] and data["chapterTitles"][book][chap]:
                titles_kept += 1
            else:
                data["chapterTitles"][book][chap] = entry["title"]
                titles_added += 1
            if chap in data["passageSummaries"][book] and data["passageSummaries"][book][chap]:
                passages_kept += 1
            else:
                data["passageSummaries"][book][chap] = entry["passages"]
                passages_added += 1

    SUMMARIES.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")

    print(f"Wrote {SUMMARIES.relative_to(REPO)}")
    print(f"  chapter titles added: {titles_added}  kept: {titles_kept}")
    print(f"  passage chapters added: {passages_added}  kept: {passages_kept}")


if __name__ == "__main__":
    main()
