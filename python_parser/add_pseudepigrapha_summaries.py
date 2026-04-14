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
    # Testaments of the Twelve Patriarchs — twelve short pseudepigraphic
    # works, each a deathbed speech by one of Jacob's twelve sons,
    # cataloging a virtue learned or a vice repented of in that
    # patriarch's life. Each Testament is structured as one chapter with
    # multiple paragraphs; we add one whole-chapter summary anchored at
    # the opening paragraph (v1).
    "Testament of Reuben": {
        "1": {
            "title": "Reuben warns against fornication",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Reuben's deathbed confession of his sin with Bilhah, framed as a warning to his sons against the destructive power of lust.",
            }],
        },
    },
    "Testament of Simeon": {
        "1": {
            "title": "Simeon warns against envy",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Simeon repents of his envy toward Joseph and counsels his sons that envy poisons the soul and provokes God's discipline.",
            }],
        },
    },
    "Testament of Levi": {
        "1": {
            "title": "Levi on priesthood and apocalyptic visions",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Levi recounts heavenly visions of the priestly orders, the coming of the Messianic priest, and the moral demands of the priesthood.",
            }],
        },
    },
    "Testament of Judah": {
        "1": {
            "title": "Judah warns against love of money, wine, and lust",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Judah recalls his life of conquest and his fall through wine and the Tamar episode; he charges his sons against drunkenness, greed, and fornication.",
            }],
        },
    },
    "Testament of Issachar": {
        "1": {
            "title": "Issachar extols singleness of heart",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Issachar models the simple, hard-working farmer's life and commends to his sons singleness of heart and integrity in labor.",
            }],
        },
    },
    "Testament of Zebulun": {
        "1": {
            "title": "Zebulun extols compassion and mercy",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Zebulun, who alone wept over Joseph in the pit, urges his sons to practice compassion and almsgiving as the marks of a righteous life.",
            }],
        },
    },
    "Testament of Dan": {
        "1": {
            "title": "Dan warns against anger and lying",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Dan repents of his anger and hatred toward Joseph and warns his sons that anger and falsehood open the soul to the spirits of Beliar.",
            }],
        },
    },
    "Testament of Naphtali": {
        "1": {
            "title": "Naphtali on the order of nature and right conduct",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Naphtali instructs his sons to live according to the order God set in nature, with visions warning of Israel's apostasy and restoration.",
            }],
        },
    },
    "Testament of Gad": {
        "1": {
            "title": "Gad warns against hatred",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Gad confesses his hatred of Joseph and traces hatred itself as the root of murder, slander, and ruin; he commends love and forgiveness.",
            }],
        },
    },
    "Testament of Asher": {
        "1": {
            "title": "Asher on the two faces of every deed",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Asher's doctrine of 'two ways': every action springs from one of two minds, and the soul's posture toward good or evil determines its destiny.",
            }],
        },
    },
    "Testament of Joseph": {
        "1": {
            "title": "Joseph on chastity, patience, and forgiveness",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Joseph rehearses his trials — the pit, slavery, the Egyptian temptation, prison — as proof that chastity, patience, and forgiveness are vindicated by God.",
            }],
        },
    },
    "Testament of Benjamin": {
        "1": {
            "title": "Benjamin on the pure mind",
            "passages": [{
                "startVerse": 1, "endVerse": None,
                "title": "Benjamin commends the 'pure mind' that sees only good in others, modeling himself on the forgiving Joseph and pointing forward to the Messiah.",
            }],
        },
    },
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
