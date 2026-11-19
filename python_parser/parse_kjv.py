import json
import re


book_titles = [
    "The First Book of Moses: Called Genesis",
    "The Second Book of Moses: Called Exodus",
    "The Third Book of Moses: Called Leviticus",
    "The Fourth Book of Moses: Called Numbers",
    "The Fifth Book of Moses: Called Deuteronomy",
    "The Book of Joshua",
    "The Book of Judges",
    "The Book of Ruth",
    "The First Book of Samuel",
    "The Second Book of Samuel",
    "The First Book of the Kings",
    "The Second Book of the Kings",
    "The First Book of the Chronicles",
    "The Second Book of the Chronicles",
    "Ezra",
    "The Book of Nehemiah",
    "The Book of Esther",
    "The Book of Job",
    "The Book of Psalms",
    "The Proverbs",
    "Ecclesiastes",
    "The Song of Solomon",
    "The Book of the Prophet Isaiah",
    "The Book of the Prophet Jeremiah",
    "The Lamentations of Jeremiah",
    "The Book of the Prophet Ezekiel",
    "The Book of Daniel",
    "Hosea",
    "Joel",
    "Amos",
    "Obadiah",
    "Jonah",
    "Micah",
    "Nahum",
    "Habakkuk",
    "Zephaniah",
    "Haggai",
    "Zechariah",
    "Malachi",
    "The Gospel According to Saint Matthew",
    "The Gospel According to Saint Mark",
    "The Gospel According to Saint Luke",
    "The Gospel According to Saint John",
    "The Acts of the Apostles",
    "The Epistle of Paul the Apostle to the Romans",
    "The First Epistle of Paul the Apostle to the Corinthians",
    "The Second Epistle of Paul the Apostle to the Corinthians",
    "The Epistle of Paul the Apostle to the Galatians",
    "The Epistle of Paul the Apostle to the Ephesians",
    "The Epistle of Paul the Apostle to the Philippians",
    "The Epistle of Paul the Apostle to the Colossians",
    "The First Epistle of Paul the Apostle to the Thessalonians",
    "The Second Epistle of Paul the Apostle to the Thessalonians",
    "The First Epistle of Paul the Apostle to Timothy",
    "The Second Epistle of Paul the Apostle to Timothy",
    "The Epistle of Paul the Apostle to Titus",
    "The Epistle of Paul the Apostle to Philemon",
    "The Epistle of Paul the Apostle to the Hebrews",
    "The General Epistle of James",
    "The First Epistle General of Peter",
    "The Second General Epistle of Peter",
    "The First Epistle General of John",
    "The Second Epistle General of John",
    "The Third Epistle General of John",
    "The General Epistle of Jude",
    "The Revelation of Saint John the Divine",
]

books = [
    "Genesis",
    "Exodus",
    "Leviticus",
    "Numbers",
    "Deuteronomy",
    "Joshua",
    "Judges",
    "Ruth",
    "1 Samuel",
    "2 Samuel",
    "1 Kings",
    "2 Kings",
    "1 Chronicles",
    "2 Chronicles",
    "Ezra",
    "Nehemiah",
    "Esther",
    "Job",
    "Psalms",
    "Proverbs",
    "Ecclesiastes",
    "Song of Solomon",
    "Isaiah",
    "Jeremiah",
    "Lamentations",
    "Ezekiel",
    "Daniel",
    "Hosea",
    "Joel",
    "Amos",
    "Obadiah",
    "Jonah",
    "Micah",
    "Nahum",
    "Habakkuk",
    "Zephaniah",
    "Haggai",
    "Zechariah",
    "Malachi",
    "Matthew",
    "Mark",
    "Luke",
    "John",
    "Acts",
    "Romans",
    "1 Corinthians",
    "2 Corinthians",
    "Galatians",
    "Ephesians",
    "Philippians",
    "Colossians",
    "1 Thessalonians",
    "2 Thessalonians",
    "1 Timothy",
    "2 Timothy",
    "Titus",
    "Philemon",
    "Hebrews",
    "James",
    "1 Peter",
    "2 Peter",
    "1 John",
    "2 John",
    "3 John",
    "Jude",
    "Revelation",
]


# kjv.txt starts about 6,100 verses mid-line, right after the verse before.
# Within a chapter that is harmless: the marker stays inline and both apps
# render it as a verse number. But 48 of those verses open the next chapter
# (33 chapters in all), and parse_bible_file starts a chapter only at the
# beginning of a line, so each stayed glued to the end of the previous chapter.
# The apps render an inline marker without its chapter, so John 6:1 showed as a
# stray verse "1" at the end of John 5 and John 6 began at verse 2 (reported
# 2026-11-19). test_bible_structure.py checks every chapter of every shipped
# translation runs 1..N.
LINE_START_MARKER = re.compile(r"(\d+):\d+")
MID_LINE_MARKER = re.compile(r"(?<=\s)(\d+):(\d+)(?=\s|$)")


def expand_chapter_openings(lines):
    """Yield `lines`, moving each mid-line chapter opening onto its own line.

    A blank line goes between the two halves, as between any two verses in
    kjv.txt, so the verse before the cut keeps the trailing space every
    paragraph ends with. A marker that ends its line (2 Samuel 2:1, Job 27:1,
    Acts 22:1) is carried onto the next line, where its text is. A mid-line
    marker that is neither in the current chapter nor the first verse of the
    next one raises instead of guessing.
    """
    chapter = None
    carried = None
    for line in lines:
        if carried is not None:
            if not line or line in book_titles:
                raise ValueError(f"verse marker {carried!r} has no text after it")
            line = f"{carried} {line}"
            carried = None
        if line in book_titles:
            chapter = None
            yield line
            continue
        start = LINE_START_MARKER.match(line)
        if start:
            chapter = int(start.group(1))
        cut = 0
        if chapter is not None:
            for marker in MID_LINE_MARKER.finditer(line):
                number, verse = int(marker.group(1)), int(marker.group(2))
                if number == chapter:
                    continue
                if (number, verse) != (chapter + 1, 1):
                    raise ValueError(
                        f"unexpected verse marker {marker.group(0)!r} in chapter {chapter}: {line!r}"
                    )
                yield line[cut:marker.start()].rstrip()
                yield ""
                cut = marker.start()
                chapter = number
        rest = line[cut:]
        if cut and LINE_START_MARKER.fullmatch(rest):
            carried = rest
        else:
            yield rest


def parse_bible_file(file_path):
    bible_data = []
    current_book = {}
    current_chapter = {}
    current_paragraph = {}

    transl_table = dict([(ord(x), ord(y)) for x, y in zip("‘’´“”–-", "'''\"\"--")])

    with open(file_path, "r", encoding="utf-8-sig") as file:
        content = file.read()
        lines = content.split("\n")

        for line in expand_chapter_openings(
            raw.strip().translate(transl_table) for raw in lines
        ):
            if line in book_titles:
                # Save the last paragraph and chapter of the previous book
                if current_book:
                    if current_paragraph:
                        current_chapter["paragraphs"].append(current_paragraph)
                        current_paragraph = {}
                    if current_chapter:
                        current_book["chapters"].append(current_chapter)
                        current_chapter = {}
                    bible_data.append(current_book)
                # Start a new book
                book_description = line
                print(f"book {line} {books[len(bible_data)]}")
                current_book = {
                    "name": books[len(bible_data)],
                    "description": book_description,
                    "chapters": [],
                }
                current_chapter = {}
                current_paragraph = {}
            elif re.match(r"\d+:\d+", line):
                # Parse chapter and verse numbers
                chapter_number, verse_rest = line.split(":", 1)
                verse_number, verse_text = verse_rest.strip().split(" ", 1)
                chapter_number = int(chapter_number)
                verse_number = int(verse_number)

                # Save the current paragraph before starting a new one
                if current_paragraph:
                    current_chapter["paragraphs"].append(current_paragraph)
                    current_paragraph = {}

                # Check if the chapter number has changed
                if (
                    current_chapter
                    and "number" in current_chapter
                    and chapter_number != current_chapter["number"]
                ):
                    current_book["chapters"].append(current_chapter)
                    current_chapter = {
                        "number": chapter_number,
                        "paragraphs": [],
                    }
                elif not current_chapter:
                    current_chapter = {
                        "number": chapter_number,
                        "paragraphs": [],
                    }

                # Start a new paragraph
                current_paragraph = {
                    "startingVerse": verse_number,
                    "text": verse_text,
                }
            else:
                if current_paragraph:
                    current_paragraph["text"] += " " + line

        # After the loop, save any remaining data
        if current_paragraph:
            current_chapter["paragraphs"].append(current_paragraph)
        if current_chapter:
            current_book["chapters"].append(current_chapter)
        if current_book:
            bible_data.append(current_book)

    return bible_data


def save_to_json(bible_data, output_file):
    with open(output_file, "w", encoding="utf-8") as file:
        json.dump(bible_data, file, ensure_ascii=False, indent=4)

    print(f"Saved to {output_file}")


if __name__ == "__main__":
    bible_data = parse_bible_file("kjv.txt")
    save_to_json(bible_data, "../ios/swiftbible/Text/bible.json")
