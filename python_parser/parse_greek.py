"""
Parser for Greek New Testament from Robinson-Pierpont Byzantine Majority Text.
Source: https://github.com/byztxt/byzantine-majority-text
Text: Robinson-Pierpont 2018 - Public Domain (Unlicense)
"""

import csv
import json
import os
import re

# Map CSV filenames to standard book names (matching app's Testament.newNames)
BOOK_FILE_ORDER = [
    ("MAT.csv", "Matthew"),
    ("MAR.csv", "Mark"),
    ("LUK.csv", "Luke"),
    ("JOH.csv", "John"),
    ("ACT.csv", "Acts"),
    ("ROM.csv", "Romans"),
    ("1CO.csv", "1 Corinthians"),
    ("2CO.csv", "2 Corinthians"),
    ("GAL.csv", "Galatians"),
    ("EPH.csv", "Ephesians"),
    ("PHP.csv", "Philippians"),
    ("COL.csv", "Colossians"),
    ("1TH.csv", "1 Thessalonians"),
    ("2TH.csv", "2 Thessalonians"),
    ("1TI.csv", "1 Timothy"),
    ("2TI.csv", "2 Timothy"),
    ("TIT.csv", "Titus"),
    ("PHM.csv", "Philemon"),
    ("HEB.csv", "Hebrews"),
    ("JAM.csv", "James"),
    ("1PE.csv", "1 Peter"),
    ("2PE.csv", "2 Peter"),
    ("1JO.csv", "1 John"),
    ("2JO.csv", "2 John"),
    ("3JO.csv", "3 John"),
    ("JUD.csv", "Jude"),
    ("REV.csv", "Revelation"),
]

# Greek book descriptions (Greek name — transliteration)
BOOK_DESCRIPTIONS = {
    "Matthew": "Κατὰ Ματθαῖον — Kata Matthaion",
    "Mark": "Κατὰ Μᾶρκον — Kata Markon",
    "Luke": "Κατὰ Λουκᾶν — Kata Loukan",
    "John": "Κατὰ Ἰωάννην — Kata Iōannēn",
    "Acts": "Πράξεις Ἀποστόλων — Praxeis Apostolōn",
    "Romans": "Πρὸς Ῥωμαίους — Pros Rhōmaious",
    "1 Corinthians": "Πρὸς Κορινθίους Αʹ — Pros Korinthious A",
    "2 Corinthians": "Πρὸς Κορινθίους Βʹ — Pros Korinthious B",
    "Galatians": "Πρὸς Γαλάτας — Pros Galatas",
    "Ephesians": "Πρὸς Ἐφεσίους — Pros Ephesious",
    "Philippians": "Πρὸς Φιλιππησίους — Pros Philippēsious",
    "Colossians": "Πρὸς Κολοσσαεῖς — Pros Kolossaeis",
    "1 Thessalonians": "Πρὸς Θεσσαλονικεῖς Αʹ — Pros Thessalonikeis A",
    "2 Thessalonians": "Πρὸς Θεσσαλονικεῖς Βʹ — Pros Thessalonikeis B",
    "1 Timothy": "Πρὸς Τιμόθεον Αʹ — Pros Timotheon A",
    "2 Timothy": "Πρὸς Τιμόθεον Βʹ — Pros Timotheon B",
    "Titus": "Πρὸς Τίτον — Pros Titon",
    "Philemon": "Πρὸς Φιλήμονα — Pros Philēmona",
    "Hebrews": "Πρὸς Ἑβραίους — Pros Hebraious",
    "James": "Ἰακώβου — Iakōbou",
    "1 Peter": "Πέτρου Αʹ — Petrou A",
    "2 Peter": "Πέτρου Βʹ — Petrou B",
    "1 John": "Ἰωάννου Αʹ — Iōannou A",
    "2 John": "Ἰωάννου Βʹ — Iōannou B",
    "3 John": "Ἰωάννου Γʹ — Iōannou G",
    "Jude": "Ἰούδα — Iouda",
    "Revelation": "Ἀποκάλυψις Ἰωάννου — Apokalypsis Iōannou",
}


def clean_greek_text(text):
    """Clean Greek text: remove paragraph markers and extra whitespace."""
    # Remove paragraph markers (¶)
    text = text.replace("¶", "").strip()
    # Collapse multiple spaces
    text = re.sub(r"\s+", " ", text)
    return text


def parse_book_csv(csv_path):
    """Parse a single Byzantine CSV book file into chapters/verses."""
    chapters = {}

    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            chapter_num = int(row["chapter"])
            verse_num = int(row["verse"])
            verse_text = clean_greek_text(row["text"])

            if chapter_num not in chapters:
                chapters[chapter_num] = []

            chapters[chapter_num].append({
                "startingVerse": verse_num,
                "text": verse_text + " ",
            })

    return chapters


def parse_greek_nt(source_dir):
    """Parse all NT books from Byzantine Majority Text CSV files."""
    bible_data = []

    for filename, book_name in BOOK_FILE_ORDER:
        csv_path = os.path.join(source_dir, filename)
        if not os.path.exists(csv_path):
            print(f"WARNING: Missing {csv_path}")
            continue

        print(f"Processing: {book_name} ({filename})")

        chapters = parse_book_csv(csv_path)
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
    source_dir = "sources/greek/byzantine-majority-text/csv-unicode/ccat/no-variants"
    output_file = "../swiftbible/Text/greek.json"

    print("Parsing Greek New Testament from Byzantine Majority Text CSV...")
    bible_data = parse_greek_nt(source_dir)

    print(f"\nParsed {len(bible_data)} books")

    if len(bible_data) != 27:
        print(f"WARNING: Expected 27 NT books, got {len(bible_data)}")

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
