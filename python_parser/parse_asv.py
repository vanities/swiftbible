"""
Parser for American Standard Version (ASV) Bible from Zefania XML format.
Source: https://github.com/seven1m/open-bibles
"""

import json
import xml.etree.ElementTree as ET

# Book descriptions (matching KJV style descriptions)
book_descriptions = {
    "Genesis": "The First Book of Moses: Called Genesis",
    "Exodus": "The Second Book of Moses: Called Exodus",
    "Leviticus": "The Third Book of Moses: Called Leviticus",
    "Numbers": "The Fourth Book of Moses: Called Numbers",
    "Deuteronomy": "The Fifth Book of Moses: Called Deuteronomy",
    "Joshua": "The Book of Joshua",
    "Judges": "The Book of Judges",
    "Ruth": "The Book of Ruth",
    "1 Samuel": "The First Book of Samuel",
    "2 Samuel": "The Second Book of Samuel",
    "1 Kings": "The First Book of the Kings",
    "2 Kings": "The Second Book of the Kings",
    "1 Chronicles": "The First Book of the Chronicles",
    "2 Chronicles": "The Second Book of the Chronicles",
    "Ezra": "Ezra",
    "Nehemiah": "The Book of Nehemiah",
    "Esther": "The Book of Esther",
    "Job": "The Book of Job",
    "Psalms": "The Book of Psalms",
    "Proverbs": "The Proverbs",
    "Ecclesiastes": "Ecclesiastes",
    "Song of Solomon": "The Song of Solomon",
    "Isaiah": "The Book of the Prophet Isaiah",
    "Jeremiah": "The Book of the Prophet Jeremiah",
    "Lamentations": "The Lamentations of Jeremiah",
    "Ezekiel": "The Book of the Prophet Ezekiel",
    "Daniel": "The Book of Daniel",
    "Hosea": "Hosea",
    "Joel": "Joel",
    "Amos": "Amos",
    "Obadiah": "Obadiah",
    "Jonah": "Jonah",
    "Micah": "Micah",
    "Nahum": "Nahum",
    "Habakkuk": "Habakkuk",
    "Zephaniah": "Zephaniah",
    "Haggai": "Haggai",
    "Zechariah": "Zechariah",
    "Malachi": "Malachi",
    "Matthew": "The Gospel According to Saint Matthew",
    "Mark": "The Gospel According to Saint Mark",
    "Luke": "The Gospel According to Saint Luke",
    "John": "The Gospel According to Saint John",
    "Acts": "The Acts of the Apostles",
    "Romans": "The Epistle of Paul the Apostle to the Romans",
    "1 Corinthians": "The First Epistle of Paul the Apostle to the Corinthians",
    "2 Corinthians": "The Second Epistle of Paul the Apostle to the Corinthians",
    "Galatians": "The Epistle of Paul the Apostle to the Galatians",
    "Ephesians": "The Epistle of Paul the Apostle to the Ephesians",
    "Philippians": "The Epistle of Paul the Apostle to the Philippians",
    "Colossians": "The Epistle of Paul the Apostle to the Colossians",
    "1 Thessalonians": "The First Epistle of Paul the Apostle to the Thessalonians",
    "2 Thessalonians": "The Second Epistle of Paul the Apostle to the Thessalonians",
    "1 Timothy": "The First Epistle of Paul the Apostle to Timothy",
    "2 Timothy": "The Second Epistle of Paul the Apostle to Timothy",
    "Titus": "The Epistle of Paul the Apostle to Titus",
    "Philemon": "The Epistle of Paul the Apostle to Philemon",
    "Hebrews": "The Epistle of Paul the Apostle to the Hebrews",
    "James": "The General Epistle of James",
    "1 Peter": "The First Epistle General of Peter",
    "2 Peter": "The Second General Epistle of Peter",
    "1 John": "The First Epistle General of John",
    "2 John": "The Second Epistle General of John",
    "3 John": "The Third Epistle General of John",
    "Jude": "The General Epistle of Jude",
    "Revelation": "The Revelation of Saint John the Divine",
}

# Map XML book names to standard names
book_name_mapping = {
    "Genesis": "Genesis",
    "Exodus": "Exodus",
    "Leviticus": "Leviticus",
    "Numbers": "Numbers",
    "Deuteronomy": "Deuteronomy",
    "Joshua": "Joshua",
    "Judges": "Judges",
    "Ruth": "Ruth",
    "1 Samuel": "1 Samuel",
    "2 Samuel": "2 Samuel",
    "1 Kings": "1 Kings",
    "2 Kings": "2 Kings",
    "1 Chronicles": "1 Chronicles",
    "2 Chronicles": "2 Chronicles",
    "Ezra": "Ezra",
    "Nehemiah": "Nehemiah",
    "Esther": "Esther",
    "Job": "Job",
    "Psalms": "Psalms",
    "Psalm": "Psalms",
    "Proverbs": "Proverbs",
    "Ecclesiastes": "Ecclesiastes",
    "Song of Solomon": "Song of Solomon",
    "Isaiah": "Isaiah",
    "Jeremiah": "Jeremiah",
    "Lamentations": "Lamentations",
    "Ezekiel": "Ezekiel",
    "Daniel": "Daniel",
    "Hosea": "Hosea",
    "Joel": "Joel",
    "Amos": "Amos",
    "Obadiah": "Obadiah",
    "Jonah": "Jonah",
    "Micah": "Micah",
    "Nahum": "Nahum",
    "Habakkuk": "Habakkuk",
    "Zephaniah": "Zephaniah",
    "Haggai": "Haggai",
    "Zechariah": "Zechariah",
    "Malachi": "Malachi",
    "Matthew": "Matthew",
    "Mark": "Mark",
    "Luke": "Luke",
    "John": "John",
    "Acts": "Acts",
    "Romans": "Romans",
    "1 Corinthians": "1 Corinthians",
    "2 Corinthians": "2 Corinthians",
    "Galatians": "Galatians",
    "Ephesians": "Ephesians",
    "Philippians": "Philippians",
    "Colossians": "Colossians",
    "1 Thessalonians": "1 Thessalonians",
    "2 Thessalonians": "2 Thessalonians",
    "1 Timothy": "1 Timothy",
    "2 Timothy": "2 Timothy",
    "Titus": "Titus",
    "Philemon": "Philemon",
    "Hebrews": "Hebrews",
    "James": "James",
    "1 Peter": "1 Peter",
    "2 Peter": "2 Peter",
    "1 John": "1 John",
    "2 John": "2 John",
    "3 John": "3 John",
    "Jude": "Jude",
    "Revelation": "Revelation",
}


def parse_zefania_xml(input_file):
    """Parse Zefania XML Bible format into our JSON structure."""
    tree = ET.parse(input_file)
    root = tree.getroot()

    bible_data = []

    # Find all BIBLEBOOK elements
    for biblebook in root.findall('.//BIBLEBOOK'):
        book_name_xml = biblebook.get('bname')

        # Map to standard name
        book_name = book_name_mapping.get(book_name_xml, book_name_xml)
        book_description = book_descriptions.get(book_name, book_name)

        print(f"Processing: {book_name}")

        chapters = []

        for chapter_elem in biblebook.findall('CHAPTER'):
            chapter_number = int(chapter_elem.get('cnumber'))

            paragraphs = []

            for verse_elem in chapter_elem.findall('VERS'):
                verse_number = int(verse_elem.get('vnumber'))
                verse_text = verse_elem.text or ""

                # Clean up the text
                verse_text = verse_text.strip()

                paragraphs.append({
                    "startingVerse": verse_number,
                    "text": verse_text + " "
                })

            chapters.append({
                "number": chapter_number,
                "paragraphs": paragraphs
            })

        bible_data.append({
            "name": book_name,
            "description": book_description,
            "chapters": chapters
        })

    return bible_data


def save_to_json(bible_data, output_file):
    """Save parsed Bible data to JSON file."""
    with open(output_file, "w", encoding="utf-8") as file:
        json.dump(bible_data, file, ensure_ascii=False, indent=4)

    print(f"Saved to {output_file}")


def main():
    input_file = "eng-asv.zefania.xml"
    output_file = "../swiftbible/Text/asv.json"

    print("Parsing ASV Bible from Zefania XML...")
    bible_data = parse_zefania_xml(input_file)

    print(f"\nParsed {len(bible_data)} books")

    # Validate book count
    if len(bible_data) != 66:
        print(f"WARNING: Expected 66 books, got {len(bible_data)}")

    # Print summary
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
