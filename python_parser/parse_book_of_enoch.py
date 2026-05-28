import json
import re
from typing import Match

SUPERSCRIPT_MAP = {
    "0": "⁰",
    "1": "¹",
    "2": "²",
    "3": "³",
    "4": "⁴",
    "5": "⁵",
    "6": "⁶",
    "7": "⁷",
    "8": "⁸",
    "9": "⁹",
    "a": "ᵃ",
    "b": "ᵇ",
    "c": "ᶜ",
    "d": "ᵈ",
    "e": "ᵉ",
    "f": "ᶠ",
    "g": "ᵍ",
    "h": "ʰ",
    "i": "ᶦ",
    "j": "ʲ",
    "k": "ᵏ",
    "l": "ˡ",
    "m": "ᵐ",
    "n": "ⁿ",
    "o": "ᵒ",
    "p": "ᵖ",
    "q": "ᵠ",
    "r": "ʳ",
    "s": "ˢ",
    "t": "ᵗ",
    "u": "ᵘ",
    "v": "ᵛ",
    "w": "ʷ",
    "x": "ˣ",
    "y": "ʸ",
    "z": "ᶻ",
}

FOOTNOTE_SUFFIX_PATTERN = re.compile(r"(?<!:)(\d+)([a-z])\b", re.IGNORECASE)


def _to_superscript(text: str) -> str:
    """Convert supported characters in ``text`` to their superscript equivalents."""

    converted = []
    for char in text:
        converted_char = SUPERSCRIPT_MAP.get(char)
        if converted_char is None:
            converted_char = SUPERSCRIPT_MAP.get(char.lower(), char)
        converted.append(converted_char)
    return "".join(converted)


def apply_superscript_suffixes(text: str) -> str:
    """Convert verse suffixes like ``6a`` to superscript form (e.g. ``⁶ᵃ``)."""

    def replace(match: Match[str]) -> str:
        digits, suffix = match.groups()
        return _to_superscript(f"{digits}{suffix}")

    return FOOTNOTE_SUFFIX_PATTERN.sub(replace, text)

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
    expected_inline_verse = None

    # Matches inline verse numbers like " 2", " 4,5" or " 9, 10" (optionally with letter suffixes)
    inline_verse_pattern = re.compile(
        r" (?P<numbers>\d+[a-z]?(?:[,-]\s*\d+[a-z]?)*?)"
        r"(?P<following>\s+(?=[\"'A-Za-z]))"
    )

    def save_current_verse():
        """Helper to save the current verse"""
        nonlocal expected_inline_verse

        if current_chapter is not None and current_verse_text.strip():
            if current_chapter not in chapters:
                chapters[current_chapter] = []

            # Clean up the text but preserve inline verse references
            text = current_verse_text.strip()

            # Convert inline verse numbers to the chapter:verse notation our Swift parser expects
            def replace_inline_verse(match):
                nonlocal expected_inline_verse

                numbers_str = match.group("numbers")
                following = match.group("following")

                # Normalize whitespace and split on comma or hyphen while capturing optional suffixes
                parts = [
                    part.strip()
                    for part in re.split(r"[,-]", numbers_str)
                    if part.strip()
                ]

                base_numbers = []
                has_suffix = bool(re.search(r"[a-z]", parts[0], re.IGNORECASE))
                for part in parts:
                    base_match = re.match(r"(\d+)", part)
                    if not base_match:
                        return match.group(0)
                    base_numbers.append(int(base_match.group(1)))

                if not base_numbers:
                    return match.group(0)

                # Guard against backwards references or unrelated numbers while allowing skipped verses
                minimal_expected = current_verse_num + 1
                effective_expected = expected_inline_verse or minimal_expected
                if base_numbers[0] < minimal_expected:
                    return match.group(0)

                if not has_suffix and base_numbers[0] < effective_expected:
                    return match.group(0)

                expected_inline_verse = base_numbers[-1] + 1

                normalized_numbers = re.sub(r"\s+", "", numbers_str)
                return f" {current_chapter}:{normalized_numbers}{following}"

            text = inline_verse_pattern.sub(replace_inline_verse, text)

            # Convert verse suffixes like "6a" to superscript form for readability
            text = apply_superscript_suffixes(text)

            chapters[current_chapter].append({
                "verse": current_verse_num,
                "text": text
            })

            expected_inline_verse = None

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
                expected_inline_verse = None
                continue

            # Check for verse number at start of line
            verse_match = re.match(r'^(\d+)\s+(.*)', line)
            if verse_match:
                # Save previous verse if exists
                save_current_verse()

                # Start new verse
                current_verse_num = int(verse_match.group(1))
                current_verse_text = verse_match.group(2)
                expected_inline_verse = current_verse_num + 1
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
    output_json_file = "../ios/swiftbible/Text/enoch.json"
    convert_enoch_to_json(input_txt_file, output_json_file)
