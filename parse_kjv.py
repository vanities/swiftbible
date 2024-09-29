import json
import re
import regex as rep


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

    transl_table = dict( [ (ord(x), ord(y)) for x,y in zip( u"‘’´“”–-",  u"'''\"\"--") ] ) 


    with open(file_path, "r", encoding="utf-8-sig") as file:
        content = file.read()
        lines = content.split("\n")

        for line in lines:
            line = line.strip().translate(transl_table)

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

num_of_matched_phrases = 0
def parse_jesus_words():
    lower_matched = set()
    total_matches = 0
    all_lowered_words = []
    jesus_words = None
    jesus_pattern = None

    def find_book(books, book_name):
        for book in books:
            if book.get('name', '').lower() == book_name.lower():
                return book
        return None

    def wrap_jesus_words(match):
        global num_of_matched_phrases
        num_of_matched_phrases += 1
        lower_matched.add(match.group(0).lower())
        return f"<JESUS>{match.group(0)}</JESUS>"

    with open('jesus.json', 'r', encoding='utf-8') as f:
        jesus_words_list = json.load(f)

    for book_name in jesus_words_list.keys():
        jesus_words = sorted(set(jesus_words_list[book_name]), key=len, reverse=True)
        all_lowered_words += [w.lower() for w in jesus_words]
        total_matches += len(jesus_words)
        jesus_pattern = rep.compile(r"\L<words>", words=jesus_words, flags=re.IGNORECASE)
        book = find_book(bible_data, book_name)
        if book:
            for chapter in book.get('chapters', []):
                for paragraph in chapter.get('paragraphs', []):
                    paragraph["text"] = jesus_pattern.sub(wrap_jesus_words, paragraph["text"])

    print(f"Total: {total_matches}")
    print(f"Matched {num_of_matched_phrases}")

    for j in all_lowered_words:
        if j not in lower_matched:
            print(j)

    for i in lower_matched:
        if i not in all_lowered_words:
            print(i)

def save_to_json(bible_data, output_file):
    with open(output_file, "w", encoding="utf-8") as file:
        json.dump(bible_data, file, ensure_ascii=False, indent=4)


bible_file = "kjv.txt"
bible_data = parse_bible_file(bible_file)
parse_jesus_words()
save_to_json(bible_data, "swiftbible/Text/bible.json")

