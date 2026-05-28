import json
import re


def parse_didache_text(input_file):
    """Parse the Didache text file into chapters."""
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
        if line.startswith("THE DIDACHE") or line.startswith("Public Domain") or \
           line.startswith("====") or line.startswith("Source:") or \
           line.startswith("Translated by") or line.startswith("Edited by") or \
           line.startswith("(Buffalo"):
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

        # Skip chapter title lines like "Chapter 1. The Two Ways..."
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


def convert_didache_to_json(input_file, output_file):
    """Convert Didache text to JSON format."""
    print("Parsing Didache (Teaching of the Twelve Apostles)...")
    chapters = parse_didache_text(input_file)

    print(f"Found {len(chapters)} chapters")

    chapter_list = []
    for chapter_num in sorted(chapters.keys()):
        text = chapters[chapter_num]
        # Clean up scripture references that appear inline
        text = re.sub(r'\s+(Matthew|Mark|Luke|John|Exodus|Deuteronomy|Ephesians|Colossians|1 Timothy|2 Thessalonians|1 Corinthians) \d+:\d+(?:-\d+)?(?:;\s*(?:cf\.\s*)?(?:Luke|Colossians|Ephesians) \d+:\d+)?', '', text)
        chapter_list.append({
            "number": chapter_num,
            "paragraphs": [{
                "startingVerse": 1,
                "text": text
            }]
        })

    books = [{
        "name": "Didache",
        "description": "The Teaching of the Twelve Apostles. One of the earliest known Christian writings outside the New Testament, dating to the late first or early second century.",
        "chapters": chapter_list
    }]

    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(books, f, ensure_ascii=False, indent=4)

    print(f"Conversion complete. JSON saved to '{output_file}'.")
    print(f"Created 1 book with {len(chapters)} chapters.")


if __name__ == "__main__":
    input_txt_file = "sources/didache.txt"
    output_json_file = "../ios/swiftbible/Text/didache.json"
    convert_didache_to_json(input_txt_file, output_json_file)
