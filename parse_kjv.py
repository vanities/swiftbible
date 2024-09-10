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


def parse_bible_file(file_path):
    bible_data = []
    current_book = {}
    current_chapter = {}
    current_paragraph = {}

    with open(file_path, "r", encoding="utf-8-sig") as file:
        content = file.read()
        lines = content.split("\n")

        for line in lines:
            line = line.strip()

            if line in book_titles:
                if current_book and current_chapter:
                    if current_paragraph:
                        if "paragraphs" not in current_chapter:
                            current_chapter["paragraphs"] = []
                        current_chapter["paragraphs"].append(current_paragraph)
                    current_book["chapters"].append(current_chapter)
                if current_book:
                    bible_data.append(current_book)
                book_description = line
                print(f"book {line} {books[len(bible_data)]}")
                current_book = {
                    "name": books[len(bible_data)],
                    "description": book_description,
                    "chapters": [],
                }
                current_chapter = {
                    "number": 0,
                    "paragraphs": [],
                }
                current_paragraph = {}
            elif re.match(r"\d+:\d+", line):
                chapter_number, verse_number = line.split(":", 1)
                if current_chapter and current_paragraph:
                    if "paragraphs" not in current_chapter:
                        current_chapter["paragraphs"] = []
                    current_chapter["paragraphs"].append(current_paragraph)
                if (
                    current_chapter
                    and "number" in current_chapter
                    and int(chapter_number) != current_chapter["number"]
                ):
                    if current_chapter["number"] != 0:
                        current_book["chapters"].append(current_chapter)
                    current_chapter = {
                        "number": int(chapter_number),
                        "paragraphs": [],
                    }
                current_paragraph = {
                    "startingVerse": int(verse_number.split()[0]),
                    "text": line.split(maxsplit=1)[1],
                }
            else:
                if current_paragraph:
                    current_paragraph["text"] += " " + line

    if current_book and current_chapter and current_paragraph:
        if "paragraphs" not in current_chapter:
            current_chapter["paragraphs"] = []
        current_chapter["paragraphs"].append(current_paragraph)
        current_book["chapters"].append(current_chapter)
        bible_data.append(current_book)

    return bible_data


def save_to_json(bible_data, output_file):
    with open(output_file, "w") as file:
        json.dump(bible_data, file, indent=4)


# Usage example
bible_file = "kjv.txt"
output_file = "swiftbible/Text/bible.json"

bible_data = parse_bible_file(bible_file)
save_to_json(bible_data, output_file)
