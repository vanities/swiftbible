# generate_verse_info.py  —  Mirascope v1 + full logging
import csv
import json
import logging
import os
import sys
from datetime import datetime
from logging.handlers import RotatingFileHandler
from pathlib import Path
from typing import Iterator

from dotenv import load_dotenv
from openai import OpenAI
from supabase import create_client
from tqdm import tqdm

from mirascope import Messages, llm

# ─────────────────────────  CONFIG  ──────────────────────────
BIBLE_JSON = Path("../swiftbible/Text/bible.json")
LOG_PATH = Path("verse_info.log")
CSV_OK = Path("verse_info.csv")
CSV_FAIL = Path("verse_info_failed.csv")
VERSION = "kjv"
LAMBDA_MODEL = "llama-3.3-70b-instruct-fp8"  # "hermes-3-llama-3.1-405b-fp8"

# ────────────────────────  LOGGING  ──────────────────────────
load_dotenv()  # .env → os.environ
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()

root = logging.getLogger()
root.setLevel(LOG_LEVEL)

# pretty console output
try:
    from rich.logging import RichHandler

    console = RichHandler(rich_tracebacks=True, markup=True, log_time_format="[%X]")
    console.setLevel(LOG_LEVEL)
    root.addHandler(console)
except ImportError:  # fall back if rich missing
    console = logging.StreamHandler(sys.stdout)
    console.setLevel(LOG_LEVEL)
    root.addHandler(console)

# rotating file log
file_handler = RotatingFileHandler(LOG_PATH, maxBytes=10_000_000, backupCount=5)
file_handler.setLevel("DEBUG")
file_fmt = logging.Formatter(
    "%(asctime)s | %(levelname)s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
file_handler.setFormatter(file_fmt)
root.addHandler(file_handler)

log = logging.getLogger("verse_info")

# ───────────────  LLM SETUP (Mirascope v1)  ────────────────
lambda_client = OpenAI(
    base_url="https://api.lambdalabs.com/v1",
    api_key=os.getenv("LAMBDA_API_KEY"),
)


@llm.call(
    provider="openai",
    model=LAMBDA_MODEL,
    client=lambda_client,
    call_params={"temperature": 0.7, "max_tokens": 800},
)
def generate_commentary(
    book: str, chapter: int, verse: int, text: str
) -> Messages.Type:
    sys_msg = (
        "You are a biblical scholar and commentator writing for curious readers. "
        "Your goal is to offer thoughtful, literary, and theological commentary on a Bible verse. "
        "Your tone should be accessible and reflective—not academic or bullet-pointed."
    )

    user_msg = (
        f"Reflect on the following verse and provide an insightful commentary:\n"
        f'{book} {chapter}:{verse} – "{text.strip()}"\n\n'
        f"Consider these elements in your reflection:\n"
        f"- The literary and theological themes in the verse.\n"
        f"- Any Hebrew or Greek words that deepen understanding, integrated naturally into the prose.\n"
        f"- Clarify uncommon or poetic phrases without using a glossary or numbered list.\n"
        f"Avoid rigid structure or section headings. Write fluidly, as if explaining to a thoughtful reader over coffee."
    )

    return [Messages.System(sys_msg), Messages.User(user_msg)]


# ────────────────────  SUPABASE  ────────────────────────────
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")
if not (SUPABASE_URL and SUPABASE_ANON_KEY):
    log.critical("Missing SUPABASE_URL or SUPABASE_ANON_KEY in environment")
    sys.exit(1)

supabase = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)


def upsert_commentary(book: str, chapter: int, verse: int, info: str) -> None:
    supabase.table("verse_info").upsert(
        {
            "version": VERSION,
            "book": book,
            "chapter": chapter,
            "starting_verse": verse,
            "info": info,
        }
    ).execute()


# ───────────────  CSV WRITERS (append-only)  ────────────────
def csv_writer(path: Path, header: list[str]):
    exists = path.exists()
    f = path.open("a", newline="", encoding="utf-8")
    w = csv.writer(f)
    if not exists:
        w.writerow(header)
    return w


ok_writer = csv_writer(CSV_OK, ["timestamp", "book", "chapter", "verse", "info"])
fail_writer = csv_writer(CSV_FAIL, ["timestamp", "book", "chapter", "verse", "error"])


# ────────────────────  BIBLE ITERATOR  ──────────────────────
def iter_verses() -> Iterator[tuple[str, int, int, str]]:
    with BIBLE_JSON.open(encoding="utf-8") as f:
        bible = json.load(f)
    for bk in bible:
        for chap in bk["chapters"]:
            for para in chap["paragraphs"]:
                yield bk["name"], chap["number"], para["startingVerse"], para["text"]


# ────────────────────────  DRIVER  ──────────────────────────
def main() -> None:
    start = datetime.utcnow()
    log.info(
        "▶️  Starting verse-info generation (%s)", start.isoformat(timespec="seconds")
    )

    verses = list(iter_verses())
    for book, chap, verse, text in tqdm(verses, desc="Processing"):
        ref = f"{book} {chap}:{verse}"
        try:
            resp = generate_commentary(book, chap, verse, text)
            info = resp.content.strip()

            # DB
            upsert_commentary(book, chap, verse, info)

            # CSV OK
            ok_writer.writerow(
                [
                    datetime.utcnow().isoformat(timespec="seconds"),
                    book,
                    chap,
                    verse,
                    info,
                ]
            )

            # Short preview
            preview = info.replace("\n", " ")[:120] + ("…" if len(info) > 120 else "")
            log.info("%s – %s", ref, preview)

        except Exception as exc:
            log.exception("❌  %s failed", ref)
            fail_writer.writerow(
                [
                    datetime.utcnow().isoformat(timespec="seconds"),
                    book,
                    chap,
                    verse,
                    str(exc),
                ]
            )

    log.info("✅ Done. Elapsed %.1f s", (datetime.utcnow() - start).total_seconds())


if __name__ == "__main__":
    main()
