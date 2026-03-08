import json
import re


def parse_2enoch_text(input_file):
    """Parse the 2 Enoch (Secrets of Enoch) text file into chapters and verses."""
    chapters = {}
    current_chapter = None
    current_verse_num = None
    current_verse_text = ""

    with open(input_file, "r", encoding="utf-8") as f:
        lines = f.readlines()

    for line in lines:
        line = line.strip()

        # Skip empty lines
        if not line:
            continue

        # Skip header lines
        if line.startswith("THE BOOK OF THE SECRETS") or line.startswith("Also known") or \
           line.startswith("Morfill/Charles") or line.startswith("===="):
            continue

        # Check for chapter marker like [Chapter 1]
        chapter_match = re.match(r'\[Chapter (\d+)\]', line)
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

        # Skip chapter subtitle lines like "Chapter 1, I"
        if current_chapter is not None and re.match(r'^Chapter \d+', line):
            continue

        # Check for verse number at start of line
        verse_match = re.match(r'^(\d+)\s+(.*)', line)
        if verse_match and current_chapter is not None:
            # Save previous verse
            if current_verse_text.strip():
                if current_chapter not in chapters:
                    chapters[current_chapter] = []
                chapters[current_chapter].append({
                    "verse": current_verse_num or 1,
                    "text": current_verse_text.strip()
                })

            current_verse_num = int(verse_match.group(1))
            current_verse_text = verse_match.group(2)
        elif current_chapter is not None:
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


def convert_2enoch_to_json(input_file, output_file):
    """Convert 2 Enoch text to JSON format."""
    print("Parsing 2 Enoch (Secrets of Enoch)...")
    chapters = parse_2enoch_text(input_file)

    print(f"Found {len(chapters)} chapters")

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

    books = [{
        "name": "2 Enoch (Secrets of Enoch)",
        "description": "Also called Slavonic Enoch. Describes Enoch's ascent through ten heavens, his encounters with angels, and divine revelations about creation and the end times.",
        "chapters": chapter_list
    }]

    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(books, f, ensure_ascii=False, indent=4)

    total_verses = sum(len(ch) for ch in chapters.values())
    print(f"Conversion complete. JSON saved to '{output_file}'.")
    print(f"Created 1 book with {len(chapters)} chapters and {total_verses} verses.")


if __name__ == "__main__":
    input_txt_file = "sources/2enoch.txt"
    output_json_file = "../swiftbible/Text/2enoch.json"
    convert_2enoch_to_json(input_txt_file, output_json_file)
