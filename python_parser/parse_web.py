"""
Parser for World English Bible (WEB) from USFX XML format.
Source: https://github.com/seven1m/open-bibles
"""

import json
import re
import xml.etree.ElementTree as ET

# Book descriptions (matching app style)
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

# Map USFX book IDs to standard names
book_id_mapping = {
    "GEN": "Genesis",
    "EXO": "Exodus",
    "LEV": "Leviticus",
    "NUM": "Numbers",
    "DEU": "Deuteronomy",
    "JOS": "Joshua",
    "JDG": "Judges",
    "RUT": "Ruth",
    "1SA": "1 Samuel",
    "2SA": "2 Samuel",
    "1KI": "1 Kings",
    "2KI": "2 Kings",
    "1CH": "1 Chronicles",
    "2CH": "2 Chronicles",
    "EZR": "Ezra",
    "NEH": "Nehemiah",
    "EST": "Esther",
    "JOB": "Job",
    "PSA": "Psalms",
    "PRO": "Proverbs",
    "ECC": "Ecclesiastes",
    "SNG": "Song of Solomon",
    "ISA": "Isaiah",
    "JER": "Jeremiah",
    "LAM": "Lamentations",
    "EZK": "Ezekiel",
    "DAN": "Daniel",
    "HOS": "Hosea",
    "JOL": "Joel",
    "AMO": "Amos",
    "OBA": "Obadiah",
    "JON": "Jonah",
    "MIC": "Micah",
    "NAM": "Nahum",
    "HAB": "Habakkuk",
    "ZEP": "Zephaniah",
    "HAG": "Haggai",
    "ZEC": "Zechariah",
    "MAL": "Malachi",
    "MAT": "Matthew",
    "MRK": "Mark",
    "LUK": "Luke",
    "JHN": "John",
    "ACT": "Acts",
    "ROM": "Romans",
    "1CO": "1 Corinthians",
    "2CO": "2 Corinthians",
    "GAL": "Galatians",
    "EPH": "Ephesians",
    "PHP": "Philippians",
    "COL": "Colossians",
    "1TH": "1 Thessalonians",
    "2TH": "2 Thessalonians",
    "1TI": "1 Timothy",
    "2TI": "2 Timothy",
    "TIT": "Titus",
    "PHM": "Philemon",
    "HEB": "Hebrews",
    "JAS": "James",
    "1PE": "1 Peter",
    "2PE": "2 Peter",
    "1JN": "1 John",
    "2JN": "2 John",
    "3JN": "3 John",
    "JUD": "Jude",
    "REV": "Revelation",
}

# Canonical book order (66 books)
canonical_order = [
    "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
    "Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel",
    "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles",
    "Ezra", "Nehemiah", "Esther", "Job", "Psalms", "Proverbs",
    "Ecclesiastes", "Song of Solomon", "Isaiah", "Jeremiah", "Lamentations",
    "Ezekiel", "Daniel", "Hosea", "Joel", "Amos",
    "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk",
    "Zephaniah", "Haggai", "Zechariah", "Malachi",
    "Matthew", "Mark", "Luke", "John", "Acts",
    "Romans", "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians",
    "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians",
    "1 Timothy", "2 Timothy", "Titus", "Philemon", "Hebrews",
    "James", "1 Peter", "2 Peter", "1 John", "2 John", "3 John",
    "Jude", "Revelation"
]


def get_all_text(elem, include_tail=True):
    """
    Recursively get all text from an element, excluding footnotes but including their tails.
    This handles mixed content where text is split by inline elements.
    """
    text_parts = []

    # Get the element's direct text
    if elem.text:
        text_parts.append(elem.text)

    for child in elem:
        # For footnotes and cross-references, skip their content but keep the tail
        if child.tag in ('f', 'x', 'ref', 'fe', 'fm'):
            # Skip the footnote content, but include text AFTER it (tail)
            if child.tail:
                text_parts.append(child.tail)
        elif child.tag in ('v', 've', 'c'):
            # Skip verse/chapter markers but keep their tails
            if child.tail:
                text_parts.append(child.tail)
        else:
            # For other elements (wj, add, nd, qt, etc.), include their content and tail
            text_parts.append(get_all_text(child, include_tail=False))
            if child.tail:
                text_parts.append(child.tail)

    return ''.join(text_parts)


def parse_usfx_xml(input_file):
    """Parse USFX XML Bible format into our JSON structure."""
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    books_dict = {}
    current_book_id = None
    current_chapter = None

    # Split content by book
    book_pattern = re.compile(r'<book id="([A-Z0-9]+)">(.*?)</book>', re.DOTALL)

    for book_match in book_pattern.finditer(content):
        book_id = book_match.group(1)
        book_content = book_match.group(2)

        # Skip non-canonical books
        if book_id not in book_id_mapping:
            print(f"Skipping non-canonical book: {book_id}")
            continue

        book_name = book_id_mapping[book_id]
        book_description = book_descriptions.get(book_name, book_name)

        print(f"Processing: {book_name}")

        chapters = {}
        current_chapter = None

        # Find all chapter and verse markers
        # Process sequentially through the book content
        pos = 0
        while pos < len(book_content):
            # Look for chapter marker
            chapter_match = re.match(r'<c id="(\d+)"/>', book_content[pos:])
            if chapter_match:
                current_chapter = int(chapter_match.group(1))
                if current_chapter not in chapters:
                    chapters[current_chapter] = {}
                pos += chapter_match.end()
                continue

            # Look for verse marker
            verse_match = re.match(r'<v id="(\d+)"/>', book_content[pos:])
            if verse_match:
                verse_num = int(verse_match.group(1))
                pos += verse_match.end()

                # Collect text until next verse, verse end, or chapter
                verse_text = []
                while pos < len(book_content):
                    # Check for verse end or next verse or chapter
                    if book_content[pos:].startswith('<ve/>'):
                        pos += 5
                        break
                    elif book_content[pos:].startswith('<v id='):
                        break
                    elif book_content[pos:].startswith('<c id='):
                        break
                    elif book_content[pos:].startswith('<f ') or book_content[pos:].startswith('<f>'):
                        # Skip footnote
                        end_f = book_content.find('</f>', pos)
                        if end_f != -1:
                            pos = end_f + 4
                        else:
                            pos += 1
                    elif book_content[pos:].startswith('<x ') or book_content[pos:].startswith('<x>'):
                        # Skip cross-reference
                        end_x = book_content.find('</x>', pos)
                        if end_x != -1:
                            pos = end_x + 4
                        else:
                            pos += 1
                    elif book_content[pos:].startswith('<wj>'):
                        # Words of Jesus opening tag - preserve as <JESUS>
                        verse_text.append('<JESUS>')
                        pos += 4  # len('<wj>')
                    elif book_content[pos:].startswith('<wj '):
                        # Words of Jesus opening tag with attributes
                        verse_text.append('<JESUS>')
                        end_tag = book_content.find('>', pos)
                        pos = end_tag + 1 if end_tag != -1 else pos + 1
                    elif book_content[pos:].startswith('</wj>'):
                        # Words of Jesus closing tag
                        verse_text.append('</JESUS>')
                        pos += 5  # len('</wj>')
                    elif book_content[pos] == '<':
                        # Other tag - skip the tag but keep looking for content
                        end_tag = book_content.find('>', pos)
                        if end_tag != -1:
                            pos = end_tag + 1
                        else:
                            pos += 1
                    else:
                        # Regular text
                        verse_text.append(book_content[pos])
                        pos += 1

                # Clean up the verse text
                text = ''.join(verse_text)
                text = re.sub(r'\s+', ' ', text).strip()

                if current_chapter and text:
                    chapters[current_chapter][verse_num] = text + " "
                continue

            # Skip other content
            pos += 1

        # Convert chapters dict to list format
        chapter_list = []
        for chapter_num in sorted(chapters.keys()):
            paragraphs = []
            for verse_num in sorted(chapters[chapter_num].keys()):
                paragraphs.append({
                    "startingVerse": verse_num,
                    "text": chapters[chapter_num][verse_num]
                })
            chapter_list.append({
                "number": chapter_num,
                "paragraphs": paragraphs
            })

        books_dict[book_name] = {
            "name": book_name,
            "description": book_description,
            "chapters": chapter_list
        }

    # Return books in canonical order
    bible_data = []
    for book_name in canonical_order:
        if book_name in books_dict:
            bible_data.append(books_dict[book_name])
        else:
            print(f"WARNING: Missing book: {book_name}")

    return bible_data


def save_to_json(bible_data, output_file):
    """Save parsed Bible data to JSON file."""
    with open(output_file, "w", encoding="utf-8") as file:
        json.dump(bible_data, file, ensure_ascii=False, indent=4)

    print(f"Saved to {output_file}")


def main():
    input_file = "eng-web.usfx.xml"
    output_file = "../swiftbible/Text/web.json"

    print("Parsing WEB Bible from USFX XML...")
    bible_data = parse_usfx_xml(input_file)

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
