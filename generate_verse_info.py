import json
import os
import requests

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_ANON_KEY = os.environ.get("SUPABASE_ANON_KEY")
LAMBDA_API_KEY = os.environ.get("LAMBDA_API_KEY")

HEADERS = {
    "apikey": SUPABASE_ANON_KEY or "",
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}" if SUPABASE_ANON_KEY else "",
    "Content-Type": "application/json",
}


def load_bible():
    with open("swiftbible/Text/bible.json", "r", encoding="utf-8") as f:
        return json.load(f)


def generate_for_verse(book, chapter, verse, text):
    payload = {
        "book": book,
        "chapter": chapter,
        "starting_verse": verse,
        "version": "kjv",
        "text": text,
    }
    url = f"{SUPABASE_URL}/functions/v1/verse-info"
    resp = requests.post(url, headers={**HEADERS, "Authorization": HEADERS["Authorization"]}, json=payload)
    resp.raise_for_status()
    return resp.text


def main():
    bible = load_bible()
    for book in bible:
        for chapter in book["chapters"]:
            for paragraph in chapter["paragraphs"]:
                print(f"Processing {book['name']} {chapter['number']}:{paragraph['startingVerse']}")
                generate_for_verse(
                    book["name"],
                    chapter["number"],
                    paragraph["startingVerse"],
                    paragraph["text"],
                )


if __name__ == "__main__":
    main()
