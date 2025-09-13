import json
import re

# Define the 5 sections of the Book of Enoch
ENOCH_SECTIONS = [
    {
        "name": "The Book of the Watchers",
        "description": "The first section describing the fall of the Watchers and Enoch's heavenly journeys",
        "start_chapter": 1,
        "end_chapter": 36
    },
    {
        "name": "The Book of Parables",
        "description": "The Similitudes of Enoch containing parables and visions",
        "start_chapter": 37,
        "end_chapter": 71
    },
    {
        "name": "The Astronomical Book",
        "description": "The Book of the Heavenly Luminaries describing celestial movements",
        "start_chapter": 72,
        "end_chapter": 82
    },
    {
        "name": "The Book of Dream Visions",
        "description": "The Book of Dreams containing allegorical visions of history",
        "start_chapter": 83,
        "end_chapter": 90
    },
    {
        "name": "The Epistle of Enoch",
        "description": "Enoch's final teachings and the Apocalypse of Weeks",
        "start_chapter": 91,
        "end_chapter": 108
    }
]


def parse_enoch_text(input_file):
    """
    Parse the Book of Enoch text file and organize into chapters and verses.
    Handles inline verse numbers and complex formatting.

    Returns:
        dict: Dictionary with chapter numbers as keys and verse data as values
    """
    chapters = {}
    current_chapter = None
    current_verse_num = 1
    current_verse_text = ""

    def save_current_verse():
        """Helper to save the current verse"""
        if current_chapter is not None and current_verse_text.strip():
            if current_chapter not in chapters:
                chapters[current_chapter] = []

            # Clean up the text but preserve inline verse references
            text = current_verse_text.strip()

            # Convert inline verse numbers to proper format (like your parser does)
            # Pattern: " 2 " becomes " 1:2 " where 1 is current chapter
            def replace_inline_verse(match):
                verse_num = match.group(1)
                following_text = match.group(2)
                return f" {current_chapter}:{verse_num} {following_text}"

            # Replace patterns like " 2 living" with " 1:2 living"
            text = re.sub(r' (\d+) ([a-z])', replace_inline_verse, text)

            chapters[current_chapter].append({
                "verse": current_verse_num,
                "text": text
            })

    with open(input_file, "r", encoding="utf-8") as f:
        for line_number, line in enumerate(f, 1):
            line = line.strip()

            # Skip empty lines
            if not line:
                continue

            # Check for chapter marker
            chapter_match = re.match(r'\[Chapter (\d+)\]', line)
            if chapter_match:
                # Save previous verse if exists
                save_current_verse()

                # Start new chapter
                current_chapter = int(chapter_match.group(1))
                current_verse_num = 1
                current_verse_text = ""
                continue

            # Check for verse number at start of line
            verse_match = re.match(r'^(\d+)\s+(.*)', line)
            if verse_match:
                # Save previous verse if exists
                save_current_verse()

                # Start new verse
                current_verse_num = int(verse_match.group(1))
                current_verse_text = verse_match.group(2)
            else:
                # Continue current verse text
                if current_verse_text:
                    current_verse_text += " " + line
                else:
                    current_verse_text = line

    # Save final verse
    save_current_verse()

    return chapters


def create_book_structure(chapters, section_info):
    """
    Create a book structure for a specific Enoch section.

    Args:
        chapters (dict): All parsed chapters
        section_info (dict): Section information with start/end chapters

    Returns:
        dict: Book structure matching the app's JSON format
    """
    book_chapters = []

    for chapter_num in range(section_info["start_chapter"], section_info["end_chapter"] + 1):
        if chapter_num in chapters:
            # Create paragraphs from verses
            paragraphs = []
            for verse_data in chapters[chapter_num]:
                paragraphs.append({
                    "startingVerse": verse_data["verse"],
                    "text": verse_data["text"]
                })

            # Keep original chapter numbering (don't renumber)
            book_chapters.append({
                "number": chapter_num,
                "paragraphs": paragraphs
            })

    return {
        "name": section_info["name"],
        "description": section_info["description"],
        "chapters": book_chapters
    }


def convert_enoch_to_json(input_file, output_file):
    """
    Convert the Book of Enoch text to JSON format with 5 separate books.

    Args:
        input_file (str): Path to the input text file
        output_file (str): Path to the output JSON file
    """
    print("Parsing Book of Enoch text...")
    chapters = parse_enoch_text(input_file)

    print(f"Found {len(chapters)} chapters")

    # Create the 5 books
    books = []
    for section in ENOCH_SECTIONS:
        print(f"Processing {section['name']} (Chapters {section['start_chapter']}-{section['end_chapter']})")
        book = create_book_structure(chapters, section)
        books.append(book)

    # Write the JSON to the output file
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(books, f, ensure_ascii=False, indent=4)

    print(f"Conversion complete. JSON saved to '{output_file}'.")
    print(f"Created {len(books)} books from the Book of Enoch.")


if __name__ == "__main__":
    input_txt_file = "book_of_enoch.txt"
    output_json_file = "../swiftbible/Text/enoch.json"
    convert_enoch_to_json(input_txt_file, output_json_file)