import json
import re


def parse_jubilees_text(input_file):
    """Parse the Book of Jubilees text file into chapters and verses."""
    chapters = {}
    current_chapter = None
    current_verse_num = None
    current_verse_text = ""

    with open(input_file, "r", encoding="utf-8") as f:
        lines = f.readlines()

    i = 0
    while i < len(lines):
        line = lines[i].strip()
        i += 1

        # Skip empty lines
        if not line:
            continue

        # Skip header lines
        if line.startswith("THE BOOK OF JUBILEES") or line.startswith("R.H. Charles") or line.startswith("===="):
            continue

        # Check for chapter marker like [Chapter 1] or "Jubilees 1"
        chapter_match = re.match(r'\[Chapter (\d+)\]', line)
        if not chapter_match:
            chapter_match = re.match(r'^Jubilees (\d+)\s*$', line)
        if chapter_match:
            # Save previous verse
            if current_chapter is not None and current_verse_text.strip():
                if current_chapter not in chapters:
                    chapters[current_chapter] = []
                chapters[current_chapter].append({
                    "verse": current_verse_num or 1,
                    "text": current_verse_text.strip()
                })

            current_chapter = int(chapter_match.group(1))
            current_verse_num = None
            current_verse_text = ""
            continue

        # Skip chapter description/summary lines (before first verse)
        if current_chapter is not None and current_verse_num is None:
            # Check if this line starts with a verse number
            verse_match = re.match(r'^(\d+)\s+(.*)', line)
            if not verse_match:
                # This is a chapter summary/description line, skip it
                continue

        # Check for verse number at start of line
        verse_match = re.match(r'^(\d+)\s+(.*)', line)
        if verse_match:
            # Save previous verse
            if current_chapter is not None and current_verse_text.strip():
                if current_chapter not in chapters:
                    chapters[current_chapter] = []
                chapters[current_chapter].append({
                    "verse": current_verse_num or 1,
                    "text": current_verse_text.strip()
                })

            current_verse_num = int(verse_match.group(1))
            current_verse_text = verse_match.group(2)
        else:
            # Continue current verse text
            if current_verse_text:
                current_verse_text += " " + line
            else:
                current_verse_text = line

    # Save final verse
    if current_chapter is not None and current_verse_text.strip():
        if current_chapter not in chapters:
            chapters[current_chapter] = []
        chapters[current_chapter].append({
            "verse": current_verse_num or 1,
            "text": current_verse_text.strip()
        })

    return chapters


def convert_jubilees_to_json(input_file, output_file):
    """Convert the Book of Jubilees text to JSON format."""
    print("Parsing Book of Jubilees text...")
    chapters = parse_jubilees_text(input_file)

    print(f"Found {len(chapters)} chapters")

    # Build chapter list
    chapter_list = []
    for chapter_num in sorted(chapters.keys()):
        paragraphs = []
        for verse_data in chapters[chapter_num]:
            paragraphs.append({
                "startingVerse": verse_data["verse"],
                "text": verse_data["text"]
            })
        chapter_list.append({
            "number": chapter_num,
            "paragraphs": paragraphs
        })

    # Single book
    books = [{
        "name": "Book of Jubilees",
        "description": "Also called Lesser Genesis. A retelling of Genesis and Exodus using a 364-day solar calendar, attributed to Moses via angelic dictation on Mount Sinai.",
        "chapters": chapter_list
    }]

    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(books, f, ensure_ascii=False, indent=4)

    total_verses = sum(len(ch) for ch in chapters.values())
    print(f"Conversion complete. JSON saved to '{output_file}'.")
    print(f"Created 1 book with {len(chapters)} chapters and {total_verses} verses.")


if __name__ == "__main__":
    input_txt_file = "sources/jubilees.txt"
    output_json_file = "../ios/swiftbible/Text/jubilees.json"
    convert_jubilees_to_json(input_txt_file, output_json_file)
