import json
import re


def parse_1clement_text(input_file):
    """Parse the 1 Clement text file into chapters."""
    chapters = {}
    current_chapter = None
    current_text = ""

    with open(input_file, "r", encoding="utf-8") as f:
        lines = f.readlines()

    for line in lines:
        line = line.strip()

        # Skip empty lines
        if not line:
            continue

        # Skip header lines
        if line.startswith("THE FIRST EPISTLE") or line.startswith("Ante-Nicene") or \
           line.startswith("====") or line.startswith("Source:") or \
           line.startswith("Translated by") or line.startswith("From Ante-Nicene") or \
           line.startswith("Edited by") or line.startswith("(Buffalo"):
            continue

        # Check for chapter marker like [Chapter 1]
        chapter_match = re.match(r'\[Chapter (\d+)\]', line)
        if chapter_match:
            # Save previous chapter
            if current_chapter is not None and current_text.strip():
                chapters[current_chapter] = current_text.strip()

            current_chapter = int(chapter_match.group(1))
            current_text = ""
            continue

        # Skip chapter title lines like "Chapter 1. The Salutation..."
        if current_chapter is not None and re.match(r'^Chapter \d+\.', line):
            continue

        # Accumulate text
        if current_chapter is not None:
            if current_text:
                current_text += " " + line
            else:
                current_text = line

    # Save final chapter
    if current_chapter is not None and current_text.strip():
        chapters[current_chapter] = current_text.strip()

    return chapters


def convert_1clement_to_json(input_file, output_file):
    """Convert 1 Clement text to JSON format."""
    print("Parsing 1 Clement (First Epistle of Clement to the Corinthians)...")
    chapters = parse_1clement_text(input_file)

    print(f"Found {len(chapters)} chapters")

    chapter_list = []
    for chapter_num in sorted(chapters.keys()):
        chapter_list.append({
            "number": chapter_num,
            "paragraphs": [{
                "startingVerse": 1,
                "text": chapters[chapter_num]
            }]
        })

    books = [{
        "name": "1 Clement",
        "description": "The First Epistle of Clement to the Corinthians. Written circa 96 AD by Clement of Rome, it is one of the oldest Christian documents outside the New Testament.",
        "chapters": chapter_list
    }]

    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(books, f, ensure_ascii=False, indent=4)

    print(f"Conversion complete. JSON saved to '{output_file}'.")
    print(f"Created 1 book with {len(chapters)} chapters.")


if __name__ == "__main__":
    input_txt_file = "sources/1clement.txt"
    output_json_file = "../swiftbible/Text/1clement.json"
    convert_1clement_to_json(input_txt_file, output_json_file)
