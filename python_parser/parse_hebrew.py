"""
Parser for Hebrew Old Testament from Open Scriptures Hebrew Bible (morphhb).
Source: https://github.com/openscriptures/morphhb
Text: Westminster Leningrad Codex (WLC) - Public Domain
"""

import json
import xml.etree.ElementTree as ET
import os

OSIS_NS = "http://www.bibletechnologies.net/2003/OSIS/namespace"

# Map morphhb XML filenames to standard book names (matching app's Testament.oldNames)
BOOK_FILE_ORDER = [
    ("Gen.xml", "Genesis"),
    ("Exod.xml", "Exodus"),
    ("Lev.xml", "Leviticus"),
    ("Num.xml", "Numbers"),
    ("Deut.xml", "Deuteronomy"),
    ("Josh.xml", "Joshua"),
    ("Judg.xml", "Judges"),
    ("Ruth.xml", "Ruth"),
    ("1Sam.xml", "1 Samuel"),
    ("2Sam.xml", "2 Samuel"),
    ("1Kgs.xml", "1 Kings"),
    ("2Kgs.xml", "2 Kings"),
    ("1Chr.xml", "1 Chronicles"),
    ("2Chr.xml", "2 Chronicles"),
    ("Ezra.xml", "Ezra"),
    ("Neh.xml", "Nehemiah"),
    ("Esth.xml", "Esther"),
    ("Job.xml", "Job"),
    ("Ps.xml", "Psalms"),
    ("Prov.xml", "Proverbs"),
    ("Eccl.xml", "Ecclesiastes"),
    ("Song.xml", "Song of Solomon"),
    ("Isa.xml", "Isaiah"),
    ("Jer.xml", "Jeremiah"),
    ("Lam.xml", "Lamentations"),
    ("Ezek.xml", "Ezekiel"),
    ("Dan.xml", "Daniel"),
    ("Hos.xml", "Hosea"),
    ("Joel.xml", "Joel"),
    ("Amos.xml", "Amos"),
    ("Obad.xml", "Obadiah"),
    ("Jonah.xml", "Jonah"),
    ("Mic.xml", "Micah"),
    ("Nah.xml", "Nahum"),
    ("Hab.xml", "Habakkuk"),
    ("Zeph.xml", "Zephaniah"),
    ("Hag.xml", "Haggai"),
    ("Zech.xml", "Zechariah"),
    ("Mal.xml", "Malachi"),
]

# Hebrew book descriptions
BOOK_DESCRIPTIONS = {
    "Genesis": "בראשית — Bereshit",
    "Exodus": "שמות — Shemot",
    "Leviticus": "ויקרא — Vayikra",
    "Numbers": "במדבר — Bemidbar",
    "Deuteronomy": "דברים — Devarim",
    "Joshua": "יהושע — Yehoshua",
    "Judges": "שופטים — Shoftim",
    "Ruth": "רות — Rut",
    "1 Samuel": "שמואל א — Shmuel Alef",
    "2 Samuel": "שמואל ב — Shmuel Bet",
    "1 Kings": "מלכים א — Melakhim Alef",
    "2 Kings": "מלכים ב — Melakhim Bet",
    "1 Chronicles": "דברי הימים א — Divrei HaYamim Alef",
    "2 Chronicles": "דברי הימים ב — Divrei HaYamim Bet",
    "Ezra": "עזרא — Ezra",
    "Nehemiah": "נחמיה — Nechemyah",
    "Esther": "אסתר — Ester",
    "Job": "איוב — Iyov",
    "Psalms": "תהלים — Tehillim",
    "Proverbs": "משלי — Mishlei",
    "Ecclesiastes": "קהלת — Kohelet",
    "Song of Solomon": "שיר השירים — Shir HaShirim",
    "Isaiah": "ישעיהו — Yeshayahu",
    "Jeremiah": "ירמיהו — Yirmeyahu",
    "Lamentations": "איכה — Eikhah",
    "Ezekiel": "יחזקאל — Yechezkel",
    "Daniel": "דניאל — Daniel",
    "Hosea": "הושע — Hoshea",
    "Joel": "יואל — Yoel",
    "Amos": "עמוס — Amos",
    "Obadiah": "עובדיה — Ovadyah",
    "Jonah": "יונה — Yonah",
    "Micah": "מיכה — Mikhah",
    "Nahum": "נחום — Nachum",
    "Habakkuk": "חבקוק — Chavakuk",
    "Zephaniah": "צפניה — Tzefanyah",
    "Haggai": "חגי — Chaggai",
    "Zechariah": "זכריה — Zekharyah",
    "Malachi": "מלאכי — Malakhi",
}


def parse_book_xml(xml_path):
    """Parse a single morphhb OSIS XML book file into chapters/verses."""
    tree = ET.parse(xml_path)
    root = tree.getroot()

    chapters = {}

    for verse in root.iter(f"{{{OSIS_NS}}}verse"):
        osis_id = verse.get("osisID")
        if not osis_id:
            continue

        # Parse osisID like "Gen.1.1"
        parts = osis_id.split(".")
        if len(parts) != 3:
            continue

        chapter_num = int(parts[1])
        verse_num = int(parts[2])

        # Extract Hebrew words, removing morphological separators
        words = []
        for w in verse.iter(f"{{{OSIS_NS}}}w"):
            text = w.text or ""
            text = text.replace("/", "")
            if text:
                words.append(text)

        verse_text = " ".join(words)

        if chapter_num not in chapters:
            chapters[chapter_num] = []

        chapters[chapter_num].append({
            "startingVerse": verse_num,
            "text": verse_text + " ",
        })

    return chapters


def parse_hebrew_ot(source_dir):
    """Parse all OT books from morphhb XML files."""
    bible_data = []

    for filename, book_name in BOOK_FILE_ORDER:
        xml_path = os.path.join(source_dir, filename)
        if not os.path.exists(xml_path):
            print(f"WARNING: Missing {xml_path}")
            continue

        print(f"Processing: {book_name} ({filename})")

        chapters = parse_book_xml(xml_path)
        description = BOOK_DESCRIPTIONS.get(book_name, book_name)

        chapter_list = []
        for ch_num in sorted(chapters.keys()):
            chapter_list.append({
                "number": ch_num,
                "paragraphs": chapters[ch_num],
            })

        bible_data.append({
            "name": book_name,
            "description": description,
            "chapters": chapter_list,
        })

    return bible_data


def save_to_json(bible_data, output_file):
    """Save parsed data to JSON file."""
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(bible_data, f, ensure_ascii=False, indent=4)
    print(f"Saved to {output_file}")


def main():
    source_dir = "sources/hebrew/morphhb/wlc"
    output_file = "../ios/swiftbible/Text/hebrew.json"

    print("Parsing Hebrew Old Testament from morphhb OSIS XML...")
    bible_data = parse_hebrew_ot(source_dir)

    print(f"\nParsed {len(bible_data)} books")

    if len(bible_data) != 39:
        print(f"WARNING: Expected 39 OT books, got {len(bible_data)}")

    total_chapters = sum(len(book["chapters"]) for book in bible_data)
    total_verses = sum(
        len(chapter["paragraphs"])
        for book in bible_data
        for chapter in book["chapters"]
    )
    print(f"Total chapters: {total_chapters}")
    print(f"Total verses: {total_verses}")

    save_to_json(bible_data, output_file)


if __name__ == "__main__":
    main()
