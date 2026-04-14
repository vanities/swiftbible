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
    # Book of Jubilees (50 chapters) — also called "Little Genesis,"
    # a 2nd-century BC retelling of Genesis and the first half of
    # Exodus, framed as a revelation given to Moses on Sinai by the
    # angel of the presence. Distinctive for its 364-day solar
    # calendar, jubilee-of-years dating, and elaboration of festivals
    # and angelic lore. Each chapter is one chapter with many
    # paragraphs; we anchor a single whole-chapter summary at v1.
    "Book of Jubilees": {
        "1":  {"title": "Moses on Sinai; Israel's apostasy and restoration foretold", "passages": [{"startVerse": 1, "endVerse": None, "title": "Moses receives the prophecy of Israel's coming apostasy and exile, and of the eventual restoration when God will create a new spirit in his people."}]},
        "2":  {"title": "The angel dictates the creation week", "passages": [{"startVerse": 1, "endVerse": None, "title": "The angel of the presence narrates the six days of creation and the institution of the Sabbath, with each day's works enumerated."}]},
        "3":  {"title": "Adam in Eden; the naming of animals; the Fall", "passages": [{"startVerse": 1, "endVerse": None, "title": "Adam names the animals, Eve is formed, and the Fall is retold with added detail about Eden's geography and the angels' role."}]},
        "4":  {"title": "From Adam to Noah; Enoch's heavenly journeys", "passages": [{"startVerse": 1, "endVerse": None, "title": "The genealogy from Cain and Abel through Seth and Enoch, with extended attention to Enoch's translation and his role as a heavenly scribe."}]},
        "5":  {"title": "The Watchers, the Nephilim, and the Flood announced", "passages": [{"startVerse": 1, "endVerse": None, "title": "The fallen Watchers take human wives, the Nephilim corrupt the earth, and God resolves to bring the Flood; Noah alone finds favor."}]},
        "6":  {"title": "Noah's covenant; the feast of weeks instituted", "passages": [{"startVerse": 1, "endVerse": None, "title": "After the Flood, Noah builds an altar and receives a covenant; the feast of weeks and the 364-day calendar are revealed."}]},
        "7":  {"title": "Noah's vineyard and the division of the earth", "passages": [{"startVerse": 1, "endVerse": None, "title": "Noah plants a vineyard, drinks of its wine, and divides the earth among his three sons by lot."}]},
        "8":  {"title": "Genealogy of Arpachshad to Peleg; the earth divided", "passages": [{"startVerse": 1, "endVerse": None, "title": "The descendants of Shem are traced and the boundaries of the three sons' inheritances are set out in detail."}]},
        "9":  {"title": "Inheritances of Ham, Shem, and Japheth", "passages": [{"startVerse": 1, "endVerse": None, "title": "The further subdivision of the earth among the sons of Ham, Shem, and Japheth, with each region named and assigned."}]},
        "10": {"title": "Mastema and the unclean spirits; medicine given to Noah", "passages": [{"startVerse": 1, "endVerse": None, "title": "The unclean spirits begin to lead astray Noah's children; Mastema is permitted to keep a tenth, and angels teach Noah the use of medicines."}]},
        "11": {"title": "Reu, Serug, Nahor, Terah; the birth of Abram", "passages": [{"startVerse": 1, "endVerse": None, "title": "The line of Shem continues; Mastema's idolatry spreads through the nations; Abram is born and even as a child rejects idols."}]},
        "12": {"title": "Abram rejects idolatry and is called out of Ur", "passages": [{"startVerse": 1, "endVerse": None, "title": "Abram challenges his father Terah's idol-making, burns the family idols, and is called by God to leave his country."}]},
        "13": {"title": "Abram in Canaan and Egypt; separation from Lot", "passages": [{"startVerse": 1, "endVerse": None, "title": "Abram travels through Shechem and Bethel, descends to Egypt, and parts from Lot, who chooses the Jordan plain."}]},
        "14": {"title": "The covenant of pieces and the promise of a seed", "passages": [{"startVerse": 1, "endVerse": None, "title": "God appears to Abram in a vision, promises a son and an innumerable seed, and ratifies the covenant by passing between the divided animals."}]},
        "15": {"title": "Circumcision instituted as the sign of the covenant", "passages": [{"startVerse": 1, "endVerse": None, "title": "God commands circumcision as the sign of his covenant with Abraham and his descendants, with the eighth day fixed as the time."}]},
        "16": {"title": "Promise of Isaac; Sodom destroyed; Isaac is born", "passages": [{"startVerse": 1, "endVerse": None, "title": "The angels visit Abraham at Mamre, announce the birth of Isaac, and bring fire upon Sodom; Isaac is born the following year."}]},
        "17": {"title": "Isaac weaned; Hagar sent away; Mastema's challenge", "passages": [{"startVerse": 1, "endVerse": None, "title": "Isaac is weaned, Hagar and Ishmael are sent away, and Mastema challenges God concerning Abraham's loyalty — setting up the test on Moriah."}]},
        "18": {"title": "The binding of Isaac", "passages": [{"startVerse": 1, "endVerse": None, "title": "Abraham's faith is tested at Mount Moriah; Isaac is bound on the altar and a ram is provided in his place."}]},
        "19": {"title": "Sarah's death; Rebekah; Abraham instructs Jacob", "passages": [{"startVerse": 1, "endVerse": None, "title": "Sarah dies and is buried at Hebron; Rebekah is brought for Isaac; Abraham instructs and blesses his grandson Jacob."}]},
        "20": {"title": "Abraham gathers his sons and commands the covenant", "passages": [{"startVerse": 1, "endVerse": None, "title": "Abraham assembles all his sons and grandsons, charges them to keep the way of the LORD, and warns them against intermarriage with the Canaanites."}]},
        "21": {"title": "Abraham's testament to Isaac", "passages": [{"startVerse": 1, "endVerse": None, "title": "Abraham gives his deathbed instructions to Isaac on offerings, blood, and the avoidance of idolatry."}]},
        "22": {"title": "Abraham's last blessing of Jacob; his death", "passages": [{"startVerse": 1, "endVerse": None, "title": "At the feast of weeks Abraham gives a final blessing to Jacob and dies; he is buried beside Sarah at Hebron."}]},
        "23": {"title": "Lament for shortened lives; promise of restoration", "passages": [{"startVerse": 1, "endVerse": None, "title": "The narrator laments how human lifespans have shrunk, and prophesies an end-time restoration when the righteous will live to a great age."}]},
        "24": {"title": "Isaac after Abraham; the wells and the Beersheba covenant", "passages": [{"startVerse": 1, "endVerse": None, "title": "Isaac digs his father's wells, prospers, and makes a covenant of peace with Abimelech at Beersheba."}]},
        "25": {"title": "Rebekah charges Jacob not to marry a Canaanite", "passages": [{"startVerse": 1, "endVerse": None, "title": "Rebekah summons Jacob and binds him by oath not to take a Canaanite wife, then blesses him with words of prophecy."}]},
        "26": {"title": "Jacob receives Isaac's blessing", "passages": [{"startVerse": 1, "endVerse": None, "title": "At Rebekah's instigation Jacob takes the blessing intended for Esau, presenting himself before the blind Isaac with goat-skins on his hands."}]},
        "27": {"title": "Esau's wrath; Jacob sent to Laban", "passages": [{"startVerse": 1, "endVerse": None, "title": "Esau plots vengeance, and Rebekah hurries Jacob away to her brother Laban in Haran for safety and a wife."}]},
        "28": {"title": "Jacob serves Laban; marriages and children", "passages": [{"startVerse": 1, "endVerse": None, "title": "Jacob serves Laban for Rachel, is given Leah by deceit, and over twenty years his eleven sons and daughter Dinah are born."}]},
        "29": {"title": "Jacob departs from Laban and meets Esau", "passages": [{"startVerse": 1, "endVerse": None, "title": "Jacob slips away from Laban, is overtaken and reconciled, then meets Esau in fearful expectation."}]},
        "30": {"title": "Dinah and Shechem; warning against intermarriage", "passages": [{"startVerse": 1, "endVerse": None, "title": "The defilement of Dinah and the slaughter at Shechem are retold, and a long legal warning against marriage with Gentiles is added."}]},
        "31": {"title": "Jacob's return to Bethel; Isaac blesses Levi and Judah", "passages": [{"startVerse": 1, "endVerse": None, "title": "Jacob purifies his household and returns to Bethel; Isaac blesses Levi (the priesthood) and Judah (the kingship) above his other grandsons."}]},
        "32": {"title": "Levi consecrated as priest at Bethel", "passages": [{"startVerse": 1, "endVerse": None, "title": "At Bethel Levi is set apart for the eternal priesthood; Jacob tithes; the death of Rachel and the Reuben-Bilhah incident are noted."}]},
        "33": {"title": "Reuben and Bilhah; laws against incest", "passages": [{"startVerse": 1, "endVerse": None, "title": "Reuben's sin with Bilhah is retold and used as the occasion for an extended legal prohibition of incestuous unions."}]},
        "34": {"title": "Joseph's brothers attack the Amorites; Joseph sold", "passages": [{"startVerse": 1, "endVerse": None, "title": "Jubilees inserts a war between Jacob's sons and the Amorite kings, and then narrates Joseph's betrayal and sale into Egypt."}]},
        "35": {"title": "Rebekah's last words and death", "passages": [{"startVerse": 1, "endVerse": None, "title": "Rebekah charges Jacob and Esau to remain at peace with one another, blesses Jacob, and dies; she is buried at Hebron."}]},
        "36": {"title": "Isaac's testament; division of his property", "passages": [{"startVerse": 1, "endVerse": None, "title": "Isaac calls his two sons, divides his goods, charges them to brotherly love, and dies; he is buried with his fathers."}]},
        "37": {"title": "Esau's sons rouse him to war against Jacob", "passages": [{"startVerse": 1, "endVerse": None, "title": "Esau's sons stir up their father against Jacob over Isaac's blessing; war with hired Edomite forces is prepared."}]},
        "38": {"title": "Esau is slain; Edom subjected to Jacob", "passages": [{"startVerse": 1, "endVerse": None, "title": "Battle is joined at the city gate; Judah strikes down Esau, and the Edomites are placed under tribute to Jacob."}]},
        "39": {"title": "Joseph in Egypt; the test of Potiphar's wife", "passages": [{"startVerse": 1, "endVerse": None, "title": "Joseph rises in Potiphar's house and resists the seduction of his master's wife, and so is cast into prison."}]},
        "40": {"title": "Pharaoh's dreams interpreted; Joseph promoted", "passages": [{"startVerse": 1, "endVerse": None, "title": "Joseph interprets Pharaoh's dreams of plenty and famine and is set over all Egypt as second only to the king."}]},
        "41": {"title": "Judah and Tamar", "passages": [{"startVerse": 1, "endVerse": None, "title": "Judah's sons fail to give Tamar offspring, she conceives by Judah himself, and the affair is interpreted as ground for a legal warning."}]},
        "42": {"title": "Famine begins; the brothers travel to Egypt", "passages": [{"startVerse": 1, "endVerse": None, "title": "The famine drives Jacob's sons to Egypt for grain, where they are accused, tested, and sent home with Simeon held back."}]},
        "43": {"title": "Joseph's cup; Benjamin returned to his brothers", "passages": [{"startVerse": 1, "endVerse": None, "title": "The hidden cup ruse is played out and Joseph reveals himself to his brothers, weeping over them and providing for the family."}]},
        "44": {"title": "Jacob's journey to Egypt; sacrifices at Beersheba", "passages": [{"startVerse": 1, "endVerse": None, "title": "Jacob sets out for Egypt with his household, offers sacrifices at Beersheba, and is reassured by God in a night vision."}]},
        "45": {"title": "Israel settles in the land of Goshen", "passages": [{"startVerse": 1, "endVerse": None, "title": "Joseph receives his father in Egypt and settles the family in Goshen; Joseph manages the famine years for Pharaoh."}]},
        "46": {"title": "Death of Jacob; oppression of Israel begins", "passages": [{"startVerse": 1, "endVerse": None, "title": "After Jacob's death the Israelites multiply in Egypt, and a new king arises who reduces them to bondage."}]},
        "47": {"title": "Birth of Moses; his rescue and flight", "passages": [{"startVerse": 1, "endVerse": None, "title": "Moses is born under Pharaoh's edict, hidden in the river, raised in the palace, and flees to Midian after killing the Egyptian."}]},
        "48": {"title": "Moses returns; the plagues and the Exodus", "passages": [{"startVerse": 1, "endVerse": None, "title": "Moses returns to Egypt at God's call; the plagues fall, Mastema is restrained, and Israel goes out with a high hand."}]},
        "49": {"title": "Passover regulations expounded", "passages": [{"startVerse": 1, "endVerse": None, "title": "An extended legal section on the proper observance of the Passover — its date, the slaughter, the meal, and who may participate."}]},
        "50": {"title": "Sabbath and jubilee laws given on Sinai", "passages": [{"startVerse": 1, "endVerse": None, "title": "The closing chapter sets out the laws of the Sabbath and of the jubilee years, sealing the revelation Moses received on the mount."}]},
    },
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
