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
    # 2 Enoch (Secrets of Enoch / Slavonic Enoch) — 68 chapters. Late
    # Second Temple Jewish work surviving in Slavonic. Frames Enoch's
    # ascent through ten heavens, God's first-person dictation of the
    # creation, Enoch's return to instruct his sons, and his final
    # translation. Each chapter is one paragraph; we anchor a single
    # whole-chapter summary at v1.
    "2 Enoch (Secrets of Enoch)": {
        "1":  {"title": "Enoch is summoned to ascend the heavens", "passages": [{"startVerse": 1, "endVerse": None, "title": "The frame story: God conceives love for the wise Enoch and sends two angels to bring him up to behold the heavenly dwellings."}]},
        "2":  {"title": "Enoch's last instruction to his sons", "passages": [{"startVerse": 1, "endVerse": None, "title": "Before he is taken away, Enoch warns his sons not to turn from the God who made heaven and earth."}]},
        "3":  {"title": "The first heaven: clouds and seas above", "passages": [{"startVerse": 1, "endVerse": None, "title": "The angels carry Enoch on their wings to the first heaven, where he beholds the upper waters and the firmament."}]},
        "4":  {"title": "Two hundred angels who rule the stars", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch is presented to the rulers of the stellar orders — two hundred angels who govern the host of heaven."}]},
        "5":  {"title": "The treasure-houses of the snow", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch is shown the storehouses of snow and the angels who guard them."}]},
        "6":  {"title": "The treasure-houses of dew and rain", "passages": [{"startVerse": 1, "endVerse": None, "title": "He sees further treasure-houses of dew and rain, kept by their own attendant angels."}]},
        "7":  {"title": "The second heaven and the apostate angels", "passages": [{"startVerse": 1, "endVerse": None, "title": "In the second heaven Enoch sees the prison of the angels who rebelled and now await the great judgement."}]},
        "8":  {"title": "The third heaven: paradise of the righteous", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch is shown paradise in the third heaven — the place prepared for the righteous, with rivers of milk, honey, oil, and wine."}]},
        "9":  {"title": "The blessedness of the righteous in paradise", "passages": [{"startVerse": 1, "endVerse": None, "title": "An angel explains that paradise is the inheritance of those who endured offences and walked in righteousness on earth."}]},
        "10": {"title": "The northern hell: place of the wicked", "passages": [{"startVerse": 1, "endVerse": None, "title": "On the northern side of the third heaven Enoch sees a place of cruel torments prepared for the wicked."}]},
        "11": {"title": "The fourth heaven: courses of sun and moon", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch is taken into the fourth heaven and shown the orderly paths of the sun and moon."}]},
        "12": {"title": "The phoenixes and chalkydri of the sun", "passages": [{"startVerse": 1, "endVerse": None, "title": "He sees the strange winged elements of the sun — phoenixes and chalkydri — that escort the daystar through the heavens."}]},
        "13": {"title": "The eastern gates of the sun", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch is brought to the gates by which the sun rises in its appointed seasons."}]},
        "14": {"title": "The western gates of the sun", "passages": [{"startVerse": 1, "endVerse": None, "title": "He is shown the corresponding gates in the west by which the sun sets each day of the year."}]},
        "15": {"title": "The morning song of the phoenixes", "passages": [{"startVerse": 1, "endVerse": None, "title": "At the rising of the sun the phoenixes and chalkydri break forth in song, and all earthly birds answer in their flight."}]},
        "16": {"title": "The twelve gates of the moon", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch is shown the gates by which the moon enters and leaves heaven through the cycle of the year."}]},
        "17": {"title": "Heavenly armies of singers", "passages": [{"startVerse": 1, "endVerse": None, "title": "In the midst of the heavens Enoch sees armed angelic hosts who serve the Lord in unending sacred song."}]},
        "18": {"title": "The fifth heaven: the Grigori (Watchers)", "passages": [{"startVerse": 1, "endVerse": None, "title": "In the fifth heaven Enoch finds the Grigori — the Watchers — sorrowing in silence over their fallen brethren."}]},
        "19": {"title": "The sixth heaven: seven bands of bright angels", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch sees seven companies of glorious angels in the sixth heaven, ordering the seasons and the moral life of mankind."}]},
        "20": {"title": "The seventh heaven: throngs around the throne", "passages": [{"startVerse": 1, "endVerse": None, "title": "Reaching the seventh heaven, Enoch sees archangels, dominions, cherubim, and seraphim ranged about the divine throne."}]},
        "21": {"title": "The cherubim and seraphim worship continually", "passages": [{"startVerse": 1, "endVerse": None, "title": "The six-winged seraphim and the cherubim never depart from the throne, covering it with their wings and singing."}]},
        "22": {"title": "Enoch is brought before the Lord in the tenth heaven", "passages": [{"startVerse": 1, "endVerse": None, "title": "On Aravoth, the tenth heaven, Enoch sees the face of the Lord like glowing iron and is anointed with oil of glory."}]},
        "23": {"title": "Enoch becomes a heavenly scribe", "passages": [{"startVerse": 1, "endVerse": None, "title": "An archangel teaches Enoch all the works of heaven and earth so that he may write them down for his sons."}]},
        "24": {"title": "The Lord summons Enoch to his left hand", "passages": [{"startVerse": 1, "endVerse": None, "title": "God calls Enoch to sit at his left hand beside Gabriel and prepares to reveal the secret of creation."}]},
        "25": {"title": "Adoil emerges from the invisible", "passages": [{"startVerse": 1, "endVerse": None, "title": "God commands the lower invisible realm to bring forth Adoil, a great light from whose belly all visible creation begins."}]},
        "26": {"title": "Archas emerges and the lower world is fixed", "passages": [{"startVerse": 1, "endVerse": None, "title": "A second invisible being, Archas, comes forth hard from the deep, becoming the foundation of the lower world."}]},
        "27": {"title": "Light and darkness become water; firmament fixed", "passages": [{"startVerse": 1, "endVerse": None, "title": "From light and darkness God forms the waters above and the firmament that divides them."}]},
        "28": {"title": "The dry land appears", "passages": [{"startVerse": 1, "endVerse": None, "title": "God gathers the lower waters together and the chaos becomes dry — the third day of creation in 2 Enoch's voice."}]},
        "29": {"title": "Angels and the fall of Satanail", "passages": [{"startVerse": 1, "endVerse": None, "title": "God forms the heavenly hosts from fire; one of the archangels, Satanail, is cast down for ambition against his Maker."}]},
        "30": {"title": "Plants, paradise, and the creation of man", "passages": [{"startVerse": 1, "endVerse": None, "title": "On the third day God commands the earth to bring forth herb and tree; paradise is planted and Adam is shaped on the sixth day."}]},
        "31": {"title": "Adam in Eden and the testament given him", "passages": [{"startVerse": 1, "endVerse": None, "title": "God places Adam in Eden in the east, charging him to keep the commandment and the testament."}]},
        "32": {"title": "Adam's fall and the promise of return", "passages": [{"startVerse": 1, "endVerse": None, "title": "Earth Adam is, and to earth Adam shall return, but God promises not to destroy him utterly."}]},
        "33": {"title": "The eighth day and the great Sabbath of God", "passages": [{"startVerse": 1, "endVerse": None, "title": "God appoints the eighth day as a sign of the world to come, when the sevens of history are fulfilled."}]},
        "34": {"title": "The Lord laments mankind's idolatry", "passages": [{"startVerse": 1, "endVerse": None, "title": "Looking down from heaven God grieves over the rejection of his commandments and the rise of idolatry."}]},
        "35": {"title": "A future faithful generation foretold", "passages": [{"startVerse": 1, "endVerse": None, "title": "From the seed of the unfaithful God will yet raise up another generation, faithful and discerning."}]},
        "36": {"title": "Enoch given thirty days to teach his sons", "passages": [{"startVerse": 1, "endVerse": None, "title": "God grants Enoch thirty days to return home, gather his household, and pass on the books before being taken up forever."}]},
        "37": {"title": "An angel cools Enoch's face for the journey", "passages": [{"startVerse": 1, "endVerse": None, "title": "Because Enoch's face has been transformed by the divine glory, an icy angel is sent to cool it so men can bear his appearance."}]},
        "38": {"title": "Enoch is sent down to earth", "passages": [{"startVerse": 1, "endVerse": None, "title": "The Lord commissions the two angels to bring Enoch back to the earth and stand beside him until his term is up."}]},
        "39": {"title": "Enoch begins his exhortation to his children", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch opens his fatherly admonition to his children, charging them to receive the will of the Lord."}]},
        "40": {"title": "Enoch claims first-hand knowledge of all things", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch tells his sons that what he speaks comes from the Lord's own lips, which his eyes have seen from beginning to end."}]},
        "41": {"title": "Enoch sees the forefathers in their dishonour", "passages": [{"startVerse": 1, "endVerse": None, "title": "He weeps over Adam, Eve, and all who fell into ruin and dishonour through disobedience."}]},
        "42": {"title": "Vision of the gate-keepers of hell and paradise", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch describes the serpentine guardians of hell and the contrasting blessedness of paradise."}]},
        "43": {"title": "Enoch the recorder of every righteous deed", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch declares that he has measured and written down every deed and every righteous judgement on earth."}]},
        "44": {"title": "Man made in God's likeness; mercy commanded", "passages": [{"startVerse": 1, "endVerse": None, "title": "Because every man bears God's likeness, contempt or harm shown to one's neighbor is contempt shown to the Lord himself."}]},
        "45": {"title": "Acceptable offerings and right intent", "passages": [{"startVerse": 1, "endVerse": None, "title": "Offerings made in haste and sincerity are received; God values the heart of the giver more than the size of the gift."}]},
        "46": {"title": "A solemn call to listen", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch calls his people once again to take in the words of his lips with full attention."}]},
        "47": {"title": "These words come from the Lord, not from Enoch", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch insists that everything he hands on derives from the Lord's lips and not from his own invention."}]},
        "48": {"title": "The sun's circuit through the heavenly thrones", "passages": [{"startVerse": 1, "endVerse": None, "title": "An astronomical interlude on the sun's path through 182 thrones north and south through the year."}]},
        "49": {"title": "Swear no oaths but only Yes and No", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch forbids swearing by heaven, earth, or any creature, anticipating the saying later given by Christ."}]},
        "50": {"title": "Every deed is recorded; nothing hidden", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch warns that no work of any man can stay concealed; every act is written in the heavenly books."}]},
        "51": {"title": "Almsgiving to the poor commended", "passages": [{"startVerse": 1, "endVerse": None, "title": "Stretch out your hands to the poor according to your strength — almsgiving is the surest investment with God."}]},
        "52": {"title": "Beatitudes on praise and silence", "passages": [{"startVerse": 1, "endVerse": None, "title": "A series of beatitudes blessing those who praise God, keep peace, judge justly, and refrain from cursing."}]},
        "53": {"title": "No one can pray for another's sin after death", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch warns his children that no father can intercede for their sins once they have passed; each soul is accountable for itself."}]},
        "54": {"title": "The books left as an inheritance of peace", "passages": [{"startVerse": 1, "endVerse": None, "title": "The written books of Enoch are entrusted to his children as a permanent inheritance of peace and instruction."}]},
        "55": {"title": "Enoch announces the day of his departure", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch tells his children that the day appointed for his removal from the earth has drawn near."}]},
        "56": {"title": "Methuselah asks his father for a final blessing", "passages": [{"startVerse": 1, "endVerse": None, "title": "Methuselah requests that his father bless their dwellings and household before his departure."}]},
        "57": {"title": "Enoch summons all his household and the elders", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch instructs Methuselah to gather all his brothers and the people for a final farewell address."}]},
        "58": {"title": "Listen, my children — the great commands", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch begins his great farewell discourse on right conduct toward God, neighbor, and beast."}]},
        "59": {"title": "Defiling the soul of beasts is self-defilement", "passages": [{"startVerse": 1, "endVerse": None, "title": "Cruelty even to animals defiles the soul that does it; the responsibility extends beyond human society."}]},
        "60": {"title": "Murder ruins both body and soul", "passages": [{"startVerse": 1, "endVerse": None, "title": "He who takes a man's life kills also his own soul; no remedy remains for him in time or eternity."}]},
        "61": {"title": "Treat every soul as you would your own", "passages": [{"startVerse": 1, "endVerse": None, "title": "Whatever a man wishes for himself from God, that he should do for every living soul — the golden rule in Enoch's voice."}]},
        "62": {"title": "Patient gifts brought in faith are accepted", "passages": [{"startVerse": 1, "endVerse": None, "title": "Blessed is the man who brings his offerings in patience and faith; he shall find pardon and reward."}]},
        "63": {"title": "Clothing the naked, feeding the hungry", "passages": [{"startVerse": 1, "endVerse": None, "title": "When a man clothes the naked and fills the hungry, his recompense is sure with God."}]},
        "64": {"title": "The people's plea: Enoch about to be taken", "passages": [{"startVerse": 1, "endVerse": None, "title": "Hearing that Enoch is to be taken up, the people gather and beg one final word of blessing."}]},
        "65": {"title": "Enoch on creation, time, and the world to come", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch summarises God's making of the visible from the invisible and his appointment of times for every creature."}]},
        "66": {"title": "Final exhortation: walk in the Lord's way", "passages": [{"startVerse": 1, "endVerse": None, "title": "His parting charge: keep your souls from injustice, walk before the Lord with fear, and serve no other god."}]},
        "67": {"title": "Enoch is taken up to the highest heaven", "passages": [{"startVerse": 1, "endVerse": None, "title": "While the people watch, the Lord sends darkness, and Enoch is borne away by the angels into the highest heaven."}]},
        "68": {"title": "The dates of Enoch's birth and translation", "passages": [{"startVerse": 1, "endVerse": None, "title": "A closing chronological note: Enoch was born and translated on the same day of the same month, having lived 365 years."}]},
    },
    # 1 Enoch — five composite books, 108 chapters total. The most
    # important Jewish apocalyptic work outside the canon, quoted by
    # Jude. Each chapter gets a list-view title and a single
    # whole-chapter summary anchored at v1.
    "The Book of the Watchers": {
        "1":  {"title": "Enoch's opening blessing on the elect", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch opens the book with a blessing for the elect of the last days and a vision of the Holy One coming forth in judgement."}]},
        "2":  {"title": "The order of the heavenly luminaries", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch contemplates the unchanging order of sun, moon, and stars as a witness to God's faithful governance."}]},
        "3":  {"title": "The trees in winter", "passages": [{"startVerse": 1, "endVerse": None, "title": "The trees obey their seasons except for the few evergreens — a parable of the unfaithful and the faithful."}]},
        "4":  {"title": "The summer heat and God's appointed seasons", "passages": [{"startVerse": 1, "endVerse": None, "title": "The summer's burning heat is set as another reminder that creation moves only by God's appointment."}]},
        "5":  {"title": "Creation obeys God; man does not", "passages": [{"startVerse": 1, "endVerse": None, "title": "All creation obeys its appointed law, but mankind has transgressed; therefore the curse falls and the elect alone are spared."}]},
        "6":  {"title": "The Watchers descend and lust after women", "passages": [{"startVerse": 1, "endVerse": None, "title": "Two hundred angels under Semjaza descend to Mount Hermon and bind themselves by oath to take human wives."}]},
        "7":  {"title": "The giants are born; the earth is corrupted", "passages": [{"startVerse": 1, "endVerse": None, "title": "From the Watchers and women come the giants, who devour the produce of men, then men themselves, and finally one another."}]},
        "8":  {"title": "Forbidden arts taught by the fallen Watchers", "passages": [{"startVerse": 1, "endVerse": None, "title": "Azazel teaches weapon-making and ornament; other Watchers teach sorceries, astrology, and divination — and the earth fills with godlessness."}]},
        "9":  {"title": "The four archangels intercede for the earth", "passages": [{"startVerse": 1, "endVerse": None, "title": "Michael, Uriel, Raphael, and Gabriel see the bloodshed below and bring the cry of the earth before the throne of God."}]},
        "10": {"title": "God's commands against the Watchers", "passages": [{"startVerse": 1, "endVerse": None, "title": "God dispatches each archangel: Uriel warns Noah, Raphael binds Azazel, Gabriel turns the giants on each other, Michael binds Semjaza."}]},
        "11": {"title": "Promise of blessing after the cleansing", "passages": [{"startVerse": 1, "endVerse": None, "title": "When the earth is purged, God will pour out the storehouses of blessing, and truth and peace will reign."}]},
        "12": {"title": "Enoch is summoned to confront Azazel", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch, hidden among the holy ones, is commissioned by the Watchers of heaven to bring a verdict to the fallen Watchers below."}]},
        "13": {"title": "Enoch declares Azazel's sentence", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch announces to Azazel and the others their judgement; the Watchers ask him to write a petition for forgiveness on their behalf."}]},
        "14": {"title": "Enoch's vision of the heavenly throne", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch is taken in vision into a house of crystal and fire and stands before the throne of the Great Glory."}]},
        "15": {"title": "God's reply: no peace for the Watchers", "passages": [{"startVerse": 1, "endVerse": None, "title": "God's verdict: the Watchers have abandoned their station; their offspring will be evil spirits on the earth and they themselves will find no peace."}]},
        "16": {"title": "The fate of the spirits of the giants", "passages": [{"startVerse": 1, "endVerse": None, "title": "The spirits that came forth from the giants will continue to corrupt the earth until the day of the great consummation."}]},
        "17": {"title": "Enoch's first journey: fire and storehouses", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch is led by angels to a place of flaming fire, to the mouths of the rivers of the abyss, and to the storehouses of the winds."}]},
        "18": {"title": "The pillars of heaven and the fallen stars", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch sees the four winds, the cornerstone of the earth, and the prison of the disobedient stars beyond the ends of the world."}]},
        "19": {"title": "Uriel explains the punishment of the Watchers", "passages": [{"startVerse": 1, "endVerse": None, "title": "Uriel shows Enoch where the Watchers stand who led mankind into idolatry, and tells him their judgement is fixed."}]},
        "20": {"title": "The seven holy archangels and their offices", "passages": [{"startVerse": 1, "endVerse": None, "title": "A formal list of the seven holy angels who watch — Uriel, Raphael, Raguel, Michael, Saraqael, Gabriel, Remiel — and their respective charges."}]},
        "21": {"title": "The prison of the disobedient stars", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch sees a chaotic place beyond the heavens where the seven stars that transgressed are bound until the appointed time."}]},
        "22": {"title": "The four hollow places of the dead", "passages": [{"startVerse": 1, "endVerse": None, "title": "An angel shows Enoch the chambers of the dead, divided into four hollows where the souls of the righteous and the wicked await the judgement."}]},
        "23": {"title": "The fire that runs without rest", "passages": [{"startVerse": 1, "endVerse": None, "title": "At the western edge of the world Enoch sees a stream of fire that never pauses — the source of the lights of heaven."}]},
        "24": {"title": "The seven mountains and the tree of life", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch sees the seven mountains of precious stone and a fragrant tree like none other; the angels begin to explain its purpose."}]},
        "25": {"title": "The tree's destiny: food for the elect", "passages": [{"startVerse": 1, "endVerse": None, "title": "Michael tells Enoch that the fragrant tree will be transplanted to the holy place after the judgement and given to the righteous as food."}]},
        "26": {"title": "The middle of the earth and the holy mountain", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch sees the holy mountain at the center of the earth and the accursed valley beside it."}]},
        "27": {"title": "The accursed valley reserved for judgement", "passages": [{"startVerse": 1, "endVerse": None, "title": "Uriel explains that the accursed valley is the place where the wicked will be assembled in the day of judgement."}]},
        "28": {"title": "The desert wilderness and its waters", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch travels eastward into a wilderness of trees and finds a stream that flows continually."}]},
        "29": {"title": "The aromatic trees of the eastern desert", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch sees trees that exhale frankincense and myrrh — the source of the fragrances of paradise."}]},
        "30": {"title": "Further fragrant valleys of the east", "passages": [{"startVerse": 1, "endVerse": None, "title": "Beyond the first valley Enoch finds another with mastic-like trees and waters running through it."}]},
        "31": {"title": "Mountains flowing with nectar and galbanum", "passages": [{"startVerse": 1, "endVerse": None, "title": "Mountains in the east yield nectar, galbanum, and other costly substances that anoint the inhabited world."}]},
        "32": {"title": "The seven mountains of nard and cinnamon", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch sees the eastern paradise where the trees of choice spices grow, and learns it was the Garden of Righteousness."}]},
        "33": {"title": "The beasts and birds at the ends of the earth", "passages": [{"startVerse": 1, "endVerse": None, "title": "At the eastern edge of the earth Enoch beholds great beasts and birds in their varied kinds, each one lovely in voice and form."}]},
        "34": {"title": "Northern portals of the heaven", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch travels to the north and is shown the three open portals from which the cold winds and frost go forth."}]},
        "35": {"title": "Western portals of the heaven", "passages": [{"startVerse": 1, "endVerse": None, "title": "At the west he finds three portals like those in the east, perfectly mirroring the heavenly order."}]},
        "36": {"title": "Southern portals; the journey is complete", "passages": [{"startVerse": 1, "endVerse": None, "title": "The southern portals send forth dew and rain; Enoch blesses God for the order of his works as the journey closes."}]},
    },
    "The Book of Parables": {
        "37": {"title": "Introduction to the second vision of wisdom", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch introduces a second vision — the Parables of wisdom — given for the eternal benefit of all the generations to come."}]},
        "38": {"title": "First Parable: the appearing of the righteous", "passages": [{"startVerse": 1, "endVerse": None, "title": "The first Parable announces the day when the righteous shall appear and sinners be driven from the face of the earth."}]},
        "39": {"title": "Enoch translated to the dwelling of the righteous", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch is taken up in vision to the dwelling place of the elect, where they ask blessing on humankind without ceasing."}]},
        "40": {"title": "The four faces around the throne", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch sees thousands upon thousands before the Lord of Spirits, and the four named voices that bless, plead, repel evil, and guard the elect."}]},
        "41": {"title": "Secrets of the heavens and the weighing of deeds", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch sees how human deeds are weighed in a balance and how the houses of the elect and the houses of sinners are kept apart."}]},
        "42": {"title": "Wisdom finds no dwelling on earth", "passages": [{"startVerse": 1, "endVerse": None, "title": "Wisdom went out and found no place among men, so she returned to her seat in heaven; iniquity took her place below."}]},
        "43": {"title": "The lights and stars are weighed and named", "passages": [{"startVerse": 1, "endVerse": None, "title": "The stars are likened to the souls of the holy, each weighed and named according to its faithfulness."}]},
        "44": {"title": "Stars that become lightnings", "passages": [{"startVerse": 1, "endVerse": None, "title": "A brief vision of stars whose form is changed; they become flashes of lightning bound to a new course."}]},
        "45": {"title": "Second Parable: the lot of the elect and the wicked", "passages": [{"startVerse": 1, "endVerse": None, "title": "The second Parable opens with the contrast between those who deny the Lord of Spirits and those whom he transforms."}]},
        "46": {"title": "The Son of Man before the Head of Days", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch sees the Head of Days and beside him a Son of Man whose face is full of grace — the central christological passage of Enoch."}]},
        "47": {"title": "The prayer and blood of the righteous reach the throne", "passages": [{"startVerse": 1, "endVerse": None, "title": "The prayers of the righteous and the cry of their blood ascend to the Lord of Spirits, and the books are opened for judgement."}]},
        "48": {"title": "The fountain of righteousness; the Son of Man named", "passages": [{"startVerse": 1, "endVerse": None, "title": "The Son of Man is revealed as the one chosen before creation, the staff of the righteous and the light of the nations."}]},
        "49": {"title": "The Spirit of wisdom rests on the Elect One", "passages": [{"startVerse": 1, "endVerse": None, "title": "Wisdom is poured out on the Elect One, the spirit of insight rests upon him, and his glory shall not fail."}]},
        "50": {"title": "Repentance offered before the day of the Elect", "passages": [{"startVerse": 1, "endVerse": None, "title": "A change is announced for the holy and elect; even sinners are offered repentance before the appointed day."}]},
        "51": {"title": "The earth and Sheol give up their dead", "passages": [{"startVerse": 1, "endVerse": None, "title": "On the day of resurrection the earth, Sheol, and hell yield up what they have received, and the Elect One sits upon his throne."}]},
        "52": {"title": "The mountains of metal that melt before the Elect", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch sees seven mountains of iron, copper, silver, gold, lead, and tin that melt away before the Elect One like wax."}]},
        "53": {"title": "The valley of judgement for the kings of the earth", "passages": [{"startVerse": 1, "endVerse": None, "title": "A deep valley with open mouths is prepared for the kings and mighty who oppress the elect."}]},
        "54": {"title": "The valley of fire for the hosts of Azazel", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch sees the burning valley into which the hosts of Azazel are cast, and the chains made for the kings of the earth."}]},
        "55": {"title": "The Head of Days repents of the Flood", "passages": [{"startVerse": 1, "endVerse": None, "title": "The Lord of Spirits swears never again to destroy the earth as in the Flood, and seats the Elect One upon the throne of his glory."}]},
        "56": {"title": "Angels of punishment and the gathering of nations", "passages": [{"startVerse": 1, "endVerse": None, "title": "The angels of punishment go forth with their scourges, and the kings of the east set themselves in motion against Israel."}]},
        "57": {"title": "The host of wagons from the east", "passages": [{"startVerse": 1, "endVerse": None, "title": "A great host comes riding in chariots from the east, west, and south as a sign of the gathering of the nations for judgement."}]},
        "58": {"title": "Third Parable opens: peace for the righteous", "passages": [{"startVerse": 1, "endVerse": None, "title": "The third Parable begins by announcing the inheritance of light and peace prepared for the righteous and elect."}]},
        "59": {"title": "Lightnings, thunders, and their secrets", "passages": [{"startVerse": 1, "endVerse": None, "title": "A short interlude on the secrets of lightning and thunder, which serve either as blessing or as judgement at God's command."}]},
        "60": {"title": "Noah's vision of the great quaking", "passages": [{"startVerse": 1, "endVerse": None, "title": "In the year 500 of Enoch's life Noah is shown the heavens shaking and the powers of nature being marshalled — a Noachic insertion."}]},
        "61": {"title": "Measuring lines for the righteous", "passages": [{"startVerse": 1, "endVerse": None, "title": "Angels go forth with measuring lines to gather the righteous and the just, and the Elect One pronounces blessing upon them."}]},
        "62": {"title": "Judgement of the kings before the Elect One", "passages": [{"startVerse": 1, "endVerse": None, "title": "The kings and mighty of the earth are arraigned before the Elect One; in terror they fall down and are delivered to the angels of punishment."}]},
        "63": {"title": "The kings beg for respite and confess too late", "passages": [{"startVerse": 1, "endVerse": None, "title": "The condemned kings plead for a moment's respite to confess and worship the Lord of Spirits, but their petition is denied."}]},
        "64": {"title": "The fallen angels seen in their punishment", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch is shown the angels who descended and seduced mankind, now bound and held under judgement."}]},
        "65": {"title": "Noah seeks Enoch on the eve of the Flood", "passages": [{"startVerse": 1, "endVerse": None, "title": "Noah, seeing the earth trembling toward destruction, hurries to the ends of the earth to call upon his great-grandfather Enoch."}]},
        "66": {"title": "The angels prepare the waters of judgement", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch is shown the angels of punishment readying the subterranean waters to be unleashed upon the earth."}]},
        "67": {"title": "The Lord assures Noah; the ark is built", "passages": [{"startVerse": 1, "endVerse": None, "title": "God speaks to Noah, declaring his lot blameless; the angels begin building the wooden ark for him."}]},
        "68": {"title": "The book of secrets passed to Methuselah", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch hands on to Methuselah the secrets contained in the Parables and the names of the angels he has seen."}]},
        "69": {"title": "The names and works of the chief fallen angels", "passages": [{"startVerse": 1, "endVerse": None, "title": "A list of the leaders of the Watchers and the secrets they betrayed, ending in the trembling of all creation before the Elect One."}]},
        "70": {"title": "Enoch's name raised to the Son of Man", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch's name is lifted from the earth to be among the heavenly beings around the Lord of Spirits."}]},
        "71": {"title": "Enoch's translation and identification with the Son of Man", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch is taken up in spirit, sees the throne and the holy ones, and is hailed as the Son of Man born to righteousness."}]},
    },
    "The Astronomical Book": {
        "72": {"title": "The courses of the sun through twelve portals", "passages": [{"startVerse": 1, "endVerse": None, "title": "Uriel teaches Enoch the laws governing the sun's annual course through the twelve portals of the heaven."}]},
        "73": {"title": "The phases of the moon", "passages": [{"startVerse": 1, "endVerse": None, "title": "A description of the moon's circumference, her chariot, and the changing measure of her light through the month."}]},
        "74": {"title": "The lunar revolution charted in detail", "passages": [{"startVerse": 1, "endVerse": None, "title": "The monthly revolution of the moon is set out under Uriel's hand, with each phase counted and named."}]},
        "75": {"title": "The four intercalary days and their leaders", "passages": [{"startVerse": 1, "endVerse": None, "title": "The leaders of thousands among the host of heaven preside over the four intercalary days that complete the solar year of 364."}]},
        "76": {"title": "The twelve portals of the winds", "passages": [{"startVerse": 1, "endVerse": None, "title": "Twelve portals at the ends of the earth open in turn to release the winds in their seasons."}]},
        "77": {"title": "The four quarters of the earth and the seven mountains", "passages": [{"startVerse": 1, "endVerse": None, "title": "The four quarters of the heaven are named, the seven great mountains, the seven rivers, and the seven islands of the sea."}]},
        "78": {"title": "Names of sun and moon; their light measured", "passages": [{"startVerse": 1, "endVerse": None, "title": "The various names of the sun and moon, and the proportions by which the moon's light waxes and wanes."}]},
        "79": {"title": "The complete law of the luminaries summarized", "passages": [{"startVerse": 1, "endVerse": None, "title": "Uriel's full disclosure of every star and luminary's law is brought to a close, leaving Enoch with the complete order of the heavens."}]},
        "80": {"title": "Last days: nature itself disordered", "passages": [{"startVerse": 1, "endVerse": None, "title": "Uriel announces a future day when the laws of nature will be disordered as a sign of the unrighteousness of men."}]},
        "81": {"title": "The heavenly tablets shown to Enoch", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch is shown the heavenly tablets, on which all human deeds and the destiny of every generation are written."}]},
        "82": {"title": "Enoch instructs Methuselah in the calendar", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch hands the calendar revelation on to his son Methuselah, charging him to preserve the books for future generations."}]},
    },
    "The Book of Dream Visions": {
        "83": {"title": "The first dream: the destruction of the earth", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch tells Methuselah of his first dream — a vision of the heavens collapsing into the abyss, foreshadowing the Flood."}]},
        "84": {"title": "Enoch's prayer for the remnant", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch lifts his hands and prays the Lord to spare a remnant of righteous flesh through the coming destruction."}]},
        "85": {"title": "The second dream begins: history in animal form", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch begins the Animal Apocalypse — a vision of human history retold in the symbolism of bulls, sheep, and beasts of prey."}]},
        "86": {"title": "Stars fallen among the cattle: the Watchers' sin", "passages": [{"startVerse": 1, "endVerse": None, "title": "Stars fall from heaven and mate with the cows, producing elephants, camels, and asses — the Watchers and the Nephilim."}]},
        "87": {"title": "The four white men sent down for judgement", "passages": [{"startVerse": 1, "endVerse": None, "title": "Four heavenly figures descend from heaven and seize the fallen stars, beginning the work of restraining the corruption."}]},
        "88": {"title": "The first star bound in the abyss", "passages": [{"startVerse": 1, "endVerse": None, "title": "One of the four binds the first fallen star and casts it into a narrow, dark abyss — the prison of the Watchers."}]},
        "89": {"title": "From Noah to the building of the temple", "passages": [{"startVerse": 1, "endVerse": None, "title": "The vision moves through the Flood, the patriarchs, the Exodus, and the conquest, to the building of Solomon's house — all in animal symbolism."}]},
        "90": {"title": "The seventy shepherds and the new Jerusalem", "passages": [{"startVerse": 1, "endVerse": None, "title": "Israel is given over to seventy angelic shepherds; the vision climaxes in the judgement of the wicked and the appearing of the white bull."}]},
    },
    "The Epistle of Enoch": {
        "91": {"title": "Enoch summons Methuselah and his sons", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch gathers Methuselah and his brothers to receive the final exhortation and the prophecy of the seven weeks of history."}]},
        "92": {"title": "The book of righteousness for all generations", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch dedicates the written book to all the children of righteousness who will come after him in the latter days."}]},
        "93": {"title": "The Apocalypse of Weeks (first portion)", "passages": [{"startVerse": 1, "endVerse": None, "title": "The first half of the Apocalypse of Weeks: history is divided into ten weeks, of which seven have already run their course."}]},
        "94": {"title": "Two paths set before the children of men", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch urges his children to walk in righteousness, contrasting the secure paths of the just with the sudden ruin of the unrighteous."}]},
        "95": {"title": "Enoch laments and pronounces the first woes", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch weeps over coming judgement and begins a series of woes against those who pervert truth, oppress the poor, and trust in iniquity."}]},
        "96": {"title": "Hope for the righteous; woes against sinners", "passages": [{"startVerse": 1, "endVerse": None, "title": "The righteous are encouraged to hope, while sinners are warned that their feasting and ill-gotten gains will be turned to shame."}]},
        "97": {"title": "The day of unrighteousness will overturn them", "passages": [{"startVerse": 1, "endVerse": None, "title": "The wealthy and the cruel are reminded that no riches can purchase deliverance in the day of the great judgement."}]},
        "98": {"title": "Sworn warnings to the wise and the foolish", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch swears to wise and foolish alike that the earth will be made witness against them and their secret sins will be exposed."}]},
        "99": {"title": "Woes against godless innovators and idolaters", "passages": [{"startVerse": 1, "endVerse": None, "title": "Woes are pronounced upon those who alter the words of righteousness, who fashion idols, and who revile what is holy."}]},
        "100": {"title": "Civil war and bloodshed in the last days", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch foretells a time when fathers and sons will kill one another and the streams of the earth will run with blood."}]},
        "101": {"title": "The fear of the Most High commended", "passages": [{"startVerse": 1, "endVerse": None, "title": "Heaven and earth themselves obey the Most High; how much more should the children of heaven fear and serve him."}]},
        "102": {"title": "Where will the wicked flee?", "passages": [{"startVerse": 1, "endVerse": None, "title": "When the fire and the Word of God go forth, the wicked have nowhere to flee; the righteous, though they die, are remembered."}]},
        "103": {"title": "The hidden mystery of the righteous dead", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch swears by the heavenly tablets that the souls of the righteous are kept in joy, contrary to all that the world supposes."}]},
        "104": {"title": "The names of the elect written in heaven", "passages": [{"startVerse": 1, "endVerse": None, "title": "The angels remember the elect before the throne, and their names are written above; the righteous are urged to be hopeful."}]},
        "105": {"title": "The wisdom of Enoch declared to the nations", "passages": [{"startVerse": 1, "endVerse": None, "title": "The Lord commands that Enoch's wisdom be carried to the children of earth, with him as guide and his sons as witnesses."}]},
        "106": {"title": "The wonder of Noah's birth", "passages": [{"startVerse": 1, "endVerse": None, "title": "Methuselah recounts how the infant Lamech was born radiant white with eyes like the sun — the Noah-birth narrative."}]},
        "107": {"title": "Enoch interprets Noah's birth", "passages": [{"startVerse": 1, "endVerse": None, "title": "Enoch reads the heavenly tablets and assures Methuselah that the marvellous child is no Watcher's son but the deliverer of his generation."}]},
        "108": {"title": "Final book: the rewards of the righteous", "passages": [{"startVerse": 1, "endVerse": None, "title": "A closing book Enoch wrote for those who keep the law in the last days, promising reward and the inheritance of the elect."}]},
    },
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
