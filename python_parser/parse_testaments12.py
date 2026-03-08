import json
import re


# The 12 testaments in canonical order
TESTAMENT_SECTIONS = [
    {"name": "Testament of Reuben", "description": "Reuben's deathbed confession concerning thoughts and the seven spirits of error"},
    {"name": "Testament of Simeon", "description": "Simeon's testament concerning envy and its destructive power"},
    {"name": "Testament of Levi", "description": "Levi's testament concerning the priesthood and prophecy of the Messiah"},
    {"name": "Testament of Judah", "description": "Judah's testament concerning courage, greed, and fornication"},
    {"name": "Testament of Issachar", "description": "Issachar's testament concerning simplicity and single-mindedness"},
    {"name": "Testament of Zebulun", "description": "Zebulun's testament concerning compassion and mercy"},
    {"name": "Testament of Dan", "description": "Dan's testament concerning anger and lying"},
    {"name": "Testament of Naphtali", "description": "Naphtali's testament concerning natural goodness"},
    {"name": "Testament of Gad", "description": "Gad's testament concerning hatred and its remedy through love"},
    {"name": "Testament of Asher", "description": "Asher's testament concerning the two faces of vice and virtue"},
    {"name": "Testament of Joseph", "description": "Joseph's testament concerning chastity and endurance under temptation"},
    {"name": "Testament of Benjamin", "description": "Benjamin's testament concerning a pure mind and the example of Joseph"},
]


def parse_testaments_text(input_file):
    """Parse the Testaments of the Twelve Patriarchs text file."""
    testaments = {}
    current_testament = None
    current_section = None
    current_text = ""

    with open(input_file, "r", encoding="utf-8") as f:
        lines = f.readlines()

    for line in lines:
        line = line.strip()

        # Skip empty lines and headers
        if not line or line.startswith("THE TESTAMENTS") or line.startswith("R.H. Charles"):
            continue

        # Check for testament separator
        testament_match = re.match(r'^=== Testament of (\w+) ===$', line)
        if testament_match:
            # Save previous section
            if current_testament and current_text.strip():
                if current_testament not in testaments:
                    testaments[current_testament] = []
                testaments[current_testament].append({
                    "section": current_section or 1,
                    "text": current_text.strip()
                })

            name = testament_match.group(1)
            current_testament = f"Testament of {name}"
            current_section = None
            current_text = ""
            continue

        # Skip separator lines
        if line.startswith("===="):
            continue

        # Skip subtitle lines like "Concerning Thoughts."
        if current_testament and current_section is None and not re.match(r'^\d+\.', line):
            # This is the subtitle/topic line, skip it
            continue

        # Check for section number at start of line (e.g., "1. The copy...")
        section_match = re.match(r'^(\d+)\.\s*(.*)', line)
        if section_match and current_testament:
            # Save previous section
            if current_text.strip():
                if current_testament not in testaments:
                    testaments[current_testament] = []
                testaments[current_testament].append({
                    "section": current_section or 1,
                    "text": current_text.strip()
                })

            current_section = int(section_match.group(1))
            current_text = section_match.group(2)
        elif current_testament:
            # Continue current section text
            if current_text:
                current_text += " " + line
            else:
                current_text = line

    # Save final section
    if current_testament and current_text.strip():
        if current_testament not in testaments:
            testaments[current_testament] = []
        testaments[current_testament].append({
            "section": current_section or 1,
            "text": current_text.strip()
        })

    return testaments


def convert_testaments_to_json(input_file, output_file):
    """Convert the Testaments text to JSON format."""
    print("Parsing Testaments of the Twelve Patriarchs...")
    testaments = parse_testaments_text(input_file)

    print(f"Found {len(testaments)} testaments")

    books = []
    for section_info in TESTAMENT_SECTIONS:
        name = section_info["name"]
        if name in testaments:
            sections = testaments[name]
            paragraphs = []
            for section_data in sections:
                paragraphs.append({
                    "startingVerse": section_data["section"],
                    "text": section_data["text"]
                })

            # Each testament is treated as a single chapter with numbered sections as verses
            books.append({
                "name": name,
                "description": section_info["description"],
                "chapters": [{
                    "number": 1,
                    "paragraphs": paragraphs
                }]
            })
            print(f"  {name}: {len(paragraphs)} sections")
        else:
            print(f"  WARNING: {name} not found in source text")

    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(books, f, ensure_ascii=False, indent=4)

    print(f"Conversion complete. JSON saved to '{output_file}'.")
    print(f"Created {len(books)} books.")


if __name__ == "__main__":
    input_txt_file = "sources/testaments12.txt"
    output_json_file = "../swiftbible/Text/testaments12.json"
    convert_testaments_to_json(input_txt_file, output_json_file)
