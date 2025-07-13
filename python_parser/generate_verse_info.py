"""
generate_verse_info.py
-----------------------------------
End-to-end generator & loader for Bible commentary.

• Loads swiftbible/Text/bible.json
• Creates an LLM prompt per verse
• Uses Mirascope-OpenAI (LambdaLabs backend)
• Upserts to Supabase ‘Verse Info’
"""

import json
import os
from pathlib import Path
from typing import Iterator

from dotenv import load_dotenv
from supabase import create_client
from tqdm import tqdm

# --- LLM -------------------------------------------------------

from mirascope.openai import OpenAIChatPrompt


class CommentaryPrompt(OpenAIChatPrompt):
    """Bible commentary prompt template."""

    template = (
        "You are a Bible commentary generator.\n"
        "1. Summarize the words and themes.\n"
        "2. Define uncommon words.\n"
        "3. Reference Greek or Hebrew words depending on testament.\n\n"
        '{book} {chapter}:{verse} - "{text}"'
    )


def generate_commentary(book: str, chapter: int, verse: int, text: str) -> str:
    """Call the LLM via Mirascope → Lambda Labs."""
    prompt = CommentaryPrompt(
        book=book, chapter=chapter, verse=verse, text=text.strip()
    )
    # For Lambda we must pass model name explicitly
    response = prompt.run(
        model="hermes-3-llama-3.1-405b-fp8",
        temperature=0.7,
        max_tokens=800,
    )
    return response.content.strip()


# --- Supabase --------------------------------------------------

load_dotenv()  # brings in .env

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")

if not SUPABASE_URL or not SUPABASE_ANON_KEY:
    raise EnvironmentError("Missing SUPABASE_URL or SUPABASE_ANON_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)


def upsert_commentary(
    version: str,
    book: str,
    chapter: int,
    starting_verse: int,
    info: str,
) -> None:
    """Insert or update a single commentary row."""
    payload = {
        "version": version,
        "book": book,
        "chapter": chapter,
        "starting_verse": starting_verse,
        "info": info,
    }
    supabase.table("Verse Info").upsert(payload).execute()


# --- Bible JSON helpers ---------------------------------------

BIBLE_JSON = Path("swiftbible/Text/bible.json")


def iter_verses() -> Iterator[tuple[str, int, int, str]]:
    """Yield (book, chapter, starting_verse, text) from JSON."""
    with BIBLE_JSON.open(encoding="utf-8") as f:
        bible = json.load(f)

    for book in bible:  # book = {"name": "...", "chapters": [...]}
        book_name = book["name"]
        for chapter in book["chapters"]:
            chap_num = chapter["number"]
            for paragraph in chapter["paragraphs"]:
                yield (
                    book_name,
                    chap_num,
                    paragraph["startingVerse"],
                    paragraph["text"],
                )


# --- Driver ----------------------------------------------------


def main() -> None:
    VERSION = "kjv"
    for book, chap, verse, text in tqdm(list(iter_verses()), desc="Processing verses"):
        try:
            commentary = generate_commentary(book, chap, verse, text)
            upsert_commentary(VERSION, book, chap, verse, commentary)
        except Exception as exc:
            # Log and continue; you may want better retry/backoff here
            print(f"⚠️  {book} {chap}:{verse} failed → {exc}")

    print("✅ All done!")


if __name__ == "__main__":
    main()
