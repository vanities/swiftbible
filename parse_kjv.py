import json
import re
import regex as rep
import string

matched = set()
lower_matched = set()

def wrap_jesus_words(match):
    if match.group(0) not in matched:
        global num_of_matched_phrases
        num_of_matched_phrases += 1
        matched.add(match.group(0))
        lower_matched.add(match.group(0).lower())
        return f"<JESUS>{match.group(0)}</JESUS>"
    else:
        return match.group(0)

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

def normalize_text(text):
    return text.translate(str.maketrans('', '', string.punctuation)).lower().strip()

num_of_matched_phrases = 0

def parse_bible_file(
        file_path,
        jesus_words_list_matthew,
        jesus_words_list_mark,
        jesus_words_list_luke,
        jesus_words_list_john,
        jesus_words_list_acts,
        jesus_words_list_1cor,
        jesus_words_list_2cor,
        jesus_words_list_rev
):


    bible_data = []
    current_book = {}
    current_chapter = {}
    current_paragraph = {}

    # Compile the regex pattern outside the loop for efficiency
    jesus_pattern_matthew = rep.compile(r"\L<words>", words=jesus_words_list_matthew, flags=re.IGNORECASE)
    jesus_pattern_mark = rep.compile(r"\L<words>", words=jesus_words_list_mark, flags=re.IGNORECASE)
    jesus_pattern_luke = rep.compile(r"\L<words>", words=jesus_words_list_luke, flags=re.IGNORECASE)
    jesus_pattern_john = rep.compile(r"\L<words>", words=jesus_words_list_john, flags=re.IGNORECASE)
    jesus_pattern_acts = rep.compile(r"\L<words>", words=jesus_words_list_acts, flags=re.IGNORECASE)
    jesus_pattern_1cor = rep.compile(r"\L<words>", words=jesus_words_list_1cor, flags=re.IGNORECASE)
    jesus_pattern_2cor = rep.compile(r"\L<words>", words=jesus_words_list_2cor, flags=re.IGNORECASE)
    jesus_pattern_rev = rep.compile(r"\L<words>", words=jesus_words_list_rev, flags=re.IGNORECASE)

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

            if current_paragraph.get("text") and current_book["name"] == "Matthew":
                current_paragraph["text"] = jesus_pattern_matthew.sub(wrap_jesus_words, current_paragraph["text"])
            if current_paragraph.get("text") and current_book["name"] == "Mark":
                current_paragraph["text"] = jesus_pattern_mark.sub(wrap_jesus_words, current_paragraph["text"])
            if current_paragraph.get("text") and current_book["name"] == "Luke":
                current_paragraph["text"] = jesus_pattern_luke.sub(wrap_jesus_words, current_paragraph["text"])
            if current_paragraph.get("text") and current_book["name"] == "John":
                current_paragraph["text"] = jesus_pattern_john.sub(wrap_jesus_words, current_paragraph["text"])
            if current_paragraph.get("text") and current_book["name"] == "Acts":
                current_paragraph["text"] = jesus_pattern_acts.sub(wrap_jesus_words, current_paragraph["text"])
            if current_paragraph.get("text") and current_book["name"] == "1 Corinthians":
                current_paragraph["text"] = jesus_pattern_1cor.sub(wrap_jesus_words, current_paragraph["text"])
            if current_paragraph.get("text") and current_book["name"] == "2 Corinthians":
                current_paragraph["text"] = jesus_pattern_2cor.sub(wrap_jesus_words, current_paragraph["text"])
            if current_paragraph.get("text") and current_book["name"] == "Revelation":
                current_paragraph["text"] = jesus_pattern_rev.sub(wrap_jesus_words, current_paragraph["text"])


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

# **Step 1: Load the jesus.json file**

# Load the list of Jesus's words from jesus.json
with open('jesus.json', 'r', encoding='utf-8') as f:
    jesus_words_list = json.load(f)

# **Usage example**
bible_file = "kjv.txt"
output_file = "swiftbible/Text/bible.json"


jesus_words_list_matthew = sorted(set(jesus_words_list["Matthew"]), key=len, reverse=True)
jesus_words_list_mark = sorted(set(jesus_words_list["Mark"]), key=len, reverse=True)
jesus_words_list_luke = sorted(set(jesus_words_list["Luke"]), key=len, reverse=True)
jesus_words_list_john = sorted(set(jesus_words_list["John"]), key=len, reverse=True)
jesus_words_list_acts = sorted(set(jesus_words_list["Acts"]), key=len, reverse=True)
jesus_words_list_1cor = sorted(set(jesus_words_list["1 Corinthians"]), key=len, reverse=True)
jesus_words_list_2cor = sorted(set(jesus_words_list["2 Corinthians"]), key=len, reverse=True)
jesus_words_list_rev = sorted(set(jesus_words_list["Revelation"]), key=len, reverse=True)

bible_data = parse_bible_file(bible_file, jesus_words_list_matthew, jesus_words_list_mark, jesus_words_list_luke, jesus_words_list_john, jesus_words_list_acts, jesus_words_list_1cor, jesus_words_list_2cor, jesus_words_list_rev)

save_to_json(bible_data, output_file)

print(f"Total: {len(jesus_words_list_matthew) + len(jesus_words_list_mark) + len(jesus_words_list_luke) + len(jesus_words_list_john) + len(jesus_words_list_acts)+ len(jesus_words_list_1cor)+ len(jesus_words_list_2cor)+ len(jesus_words_list_rev)}")
print(f"Matched {num_of_matched_phrases}")

all_words = [w.lower() for w in jesus_words_list_matthew] + [w.lower() for w in jesus_words_list_mark] + [w.lower() for w in jesus_words_list_luke] + [w.lower() for w in jesus_words_list_john]+ [w.lower() for w in jesus_words_list_acts]+ [w.lower() for w in jesus_words_list_1cor]+ [w.lower() for w in jesus_words_list_2cor]+ [w.lower() for w in jesus_words_list_rev]
for j in all_words:
    if j not in lower_matched:
        print(j)
