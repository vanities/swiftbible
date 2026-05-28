import json
import re

# Define the mapping of abbreviations to full book names and descriptions
ABBREVIATIONS = {
    "TOB": {"name": "Tobit", "description": "The Book of Tobit"},
    "JDT": {"name": "Judith", "description": "The Book of Judith"},
    "ESG": {"name": "Esther", "description": "The Book of Esther"},
    "WIS": {"name": "Wisdom of Solomon", "description": "The Wisdom of Solomon"},
    "SIR": {"name": "Sirach", "description": "The Book of Sirach"},
    "BAR": {"name": "Baruch", "description": "The Book of Baruch"},
    "PRA": {"name": "Prayer of Azariah", "description": "The Prayer of Azariah"},
    "SUS": {"name": "Susanna", "description": "The Story of Susanna"},
    "BEL": {
        "name": "Bel and the Dragon",
        "description": "The Story of Bel and the Dragon",
    },
    "1MA": {"name": "1 Maccabees", "description": "First Book of Maccabees"},
    "2MA": {"name": "2 Maccabees", "description": "Second Book of Maccabees"},
    "1ES": {"name": "1 Esdras", "description": "First Book of Esdras"},
    "PRM": {"name": "Prayer of Manasseh", "description": "The Prayer of Manasseh"},
    "4ES": {"name": "2 Esdras", "description": "Second Book of Esdras"},
    # Add more abbreviations as needed
}

# Define the correct order of books
BOOK_ORDER = [
    "TOB",
    "JDT",
    "ESG",
    "WIS",
    "SIR",
    "BAR",
    "PRA",
    "SUS",
    "BEL",
    "1MA",
    "2MA",
    "1ES",
    "PRM",
    "4ES",
]


def parse_line(line):
    """
    Parses a line of the format:
    ABBR CHAPTER:VERSE Text...

    Returns:
        abbr (str): Book abbreviation
        chapter (int): Chapter number
        verse (int): Verse number
        text (str): Verse text
    """
    pattern = r"^(\w+)\s+(\d+):(\d+)\s+(.*)$"
    match = re.match(pattern, line)
    if match:
        abbr, chapter, verse, text = match.groups()
        return abbr, int(chapter), int(verse), text.strip()
    else:
        return None, None, None, None


def convert_txt_to_json(input_file, output_file):
    # Data structure to hold the books
    books_dict = {}

    with open(input_file, "r", encoding="utf-8") as f:
        for line_number, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue  # Skip empty lines
            abbr, chapter, verse, text = parse_line(line)
            if not abbr:
                print(f"Line {line_number}: Unable to parse line: {line}")
                continue
            if abbr not in ABBREVIATIONS:
                print(f"Line {line_number}: Unknown abbreviation '{abbr}'. Skipping.")
                continue
            book_info = ABBREVIATIONS[abbr]
            book_name = book_info["name"]
            book_description = book_info["description"]

            # Initialize book if not already present
            if abbr not in books_dict:
                books_dict[abbr] = {
                    "name": book_name,
                    "description": book_description,
                    "chapters": {},
                }

            # Initialize chapter if not already present
            chapters = books_dict[abbr]["chapters"]
            if chapter not in chapters:
                chapters[chapter] = {"number": chapter, "paragraphs": []}

            # Add the verse as a paragraph
            paragraph = {"startingVerse": verse, "text": text}
            chapters[chapter]["paragraphs"].append(paragraph)

    # Convert the books_dict to the desired JSON structure
    books_list = []
    for abbr in BOOK_ORDER:
        if abbr in books_dict:
            book = books_dict[abbr]
            # Sort chapters by chapter number
            sorted_chapters = sorted(
                book["chapters"].values(), key=lambda x: x["number"]
            )
            # Sort paragraphs within each chapter by startingVerse
            for chapter in sorted_chapters:
                chapter["paragraphs"] = sorted(
                    chapter["paragraphs"], key=lambda x: x["startingVerse"]
                )
            book_entry = {
                "name": book["name"],
                "description": book["description"],
                "chapters": sorted_chapters,
            }
            books_list.append(book_entry)

    # Write the JSON to the output file
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(books_list, f, ensure_ascii=False, indent=4)

    print(f"Conversion complete. JSON saved to '{output_file}'.")


if __name__ == "__main__":
    input_txt_file = "apocrypha.txt"  # Replace with your input file path
    output_json_file = (
        "../ios/swiftbible/Text/apocrypha.json"  # Replace with your desired output file path
    )
    convert_txt_to_json(input_txt_file, output_json_file)
