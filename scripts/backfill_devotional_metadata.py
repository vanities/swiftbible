#!/usr/bin/env python3
"""Backfill holiday_name / holiday_url / anchor_verse on existing
Daily Devotional rows. Idempotent — only writes fields that are null
on the row and have a valid value to set.

Holiday detection mirrors the logic in
supabase/functions/daily-devotional/index.ts. Keep them in sync if you
add a new holiday there.

Usage:
  set -a && source .env.production && set +a
  python3 scripts/backfill_devotional_metadata.py [--dry-run]
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import date, timedelta
from typing import Optional


SUPABASE_URL = os.environ["SUPABASE_URL"].rstrip("/")
SERVICE_KEY = (
    os.environ.get("SUPABASE_SERVICE_KEY")
    or os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
)
if not SERVICE_KEY:
    raise SystemExit("Set SUPABASE_SERVICE_KEY or SUPABASE_SERVICE_ROLE_KEY")

HEADERS = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal",
}

# Mirrors HOLIDAY_WIKIPEDIA_URLS in the edge function. Holidays without a
# URL here just get a null holiday_url — still searchable by name.
HOLIDAY_WIKIPEDIA_URLS = {
    "Shrove Tuesday": "https://en.wikipedia.org/wiki/Shrove_Tuesday",
    "Ash Wednesday": "https://en.wikipedia.org/wiki/Ash_Wednesday",
    "Laetare Sunday": "https://en.wikipedia.org/wiki/Laetare_Sunday",
    "Palm Sunday": "https://en.wikipedia.org/wiki/Palm_Sunday",
    "Holy Monday": "https://en.wikipedia.org/wiki/Holy_Monday",
    "Spy Wednesday": "https://en.wikipedia.org/wiki/Holy_Wednesday",
    "Maundy Thursday": "https://en.wikipedia.org/wiki/Maundy_Thursday",
    "Good Friday": "https://en.wikipedia.org/wiki/Good_Friday",
    "Holy Saturday": "https://en.wikipedia.org/wiki/Holy_Saturday",
    "Easter Sunday": "https://en.wikipedia.org/wiki/Easter",
    "Ascension Day": "https://en.wikipedia.org/wiki/Feast_of_the_Ascension",
    "Pentecost": "https://en.wikipedia.org/wiki/Pentecost",
    "Trinity Sunday": "https://en.wikipedia.org/wiki/Trinity_Sunday",
    "Epiphany": "https://en.wikipedia.org/wiki/Epiphany_(holiday)",
    "Epiphany Eve": "https://en.wikipedia.org/wiki/Epiphany_(holiday)",
    "Baptism of Jesus": "https://en.wikipedia.org/wiki/Baptism_of_the_Lord",
    "Transfiguration": "https://en.wikipedia.org/wiki/Feast_of_the_Transfiguration",
    "Reformation Day": "https://en.wikipedia.org/wiki/Reformation_Day",
    "All Saints' Day": "https://en.wikipedia.org/wiki/All_Saints%27_Day",
    "Christmas Eve": "https://en.wikipedia.org/wiki/Christmas_Eve",
    "Christmas Day": "https://en.wikipedia.org/wiki/Christmas",
    "New Year's Eve": "https://en.wikipedia.org/wiki/New_Year%27s_Eve",
    "New Year's Day": "https://en.wikipedia.org/wiki/New_Year%27s_Day",
    "Thanksgiving": "https://en.wikipedia.org/wiki/Thanksgiving_(United_States)",
    "Mother's Day": "https://en.wikipedia.org/wiki/Mother%27s_Day",
    "Father's Day": "https://en.wikipedia.org/wiki/Father%27s_Day",
    "Independence Day": "https://en.wikipedia.org/wiki/Independence_Day_(United_States)",
    "Memorial Day": "https://en.wikipedia.org/wiki/Memorial_Day",
    "Veterans Day": "https://en.wikipedia.org/wiki/Veterans_Day",
    "Labor Day": "https://en.wikipedia.org/wiki/Labor_Day",
    "Martin Luther King Jr. Day": "https://en.wikipedia.org/wiki/Martin_Luther_King_Jr._Day",
    "Presidents' Day": "https://en.wikipedia.org/wiki/Washington%27s_Birthday",
    "Juneteenth": "https://en.wikipedia.org/wiki/Juneteenth",
    "Valentine's Day": "https://en.wikipedia.org/wiki/Valentine%27s_Day",
    "St. Patrick's Day": "https://en.wikipedia.org/wiki/Saint_Patrick%27s_Day",
    "Earth Day": "https://en.wikipedia.org/wiki/Earth_Day",
    "Flag Day": "https://en.wikipedia.org/wiki/Flag_Day_(United_States)",
    "Patriot Day": "https://en.wikipedia.org/wiki/Patriot_Day_(United_States)",
    "International Day of Peace": "https://en.wikipedia.org/wiki/International_Day_of_Peace",
    "Michaelmas": "https://en.wikipedia.org/wiki/Michaelmas",
    "Spring Equinox": "https://en.wikipedia.org/wiki/March_equinox",
    "Summer Solstice": "https://en.wikipedia.org/wiki/Summer_solstice",
    "Autumn Equinox": "https://en.wikipedia.org/wiki/September_equinox",
    "Winter Solstice": "https://en.wikipedia.org/wiki/Winter_solstice",
    "World Day of Prayer": "https://en.wikipedia.org/wiki/World_Day_of_Prayer",
    "National Day of Prayer": "https://en.wikipedia.org/wiki/National_Day_of_Prayer",
    "Election Day": "https://en.wikipedia.org/wiki/Election_Day_(United_States)",
    "Christ the King Sunday": "https://en.wikipedia.org/wiki/Feast_of_Christ_the_King",
    "First Sunday of Advent": "https://en.wikipedia.org/wiki/Advent",
    "Second Sunday of Advent": "https://en.wikipedia.org/wiki/Advent",
    "Third Sunday of Advent": "https://en.wikipedia.org/wiki/Advent",
    "Fourth Sunday of Advent": "https://en.wikipedia.org/wiki/Advent",
}

EASTER_OFFSETS = {
    -47: "Shrove Tuesday",
    -46: "Ash Wednesday",
    -21: "Laetare Sunday",
    -7: "Palm Sunday",
    -6: "Holy Monday",
    -4: "Spy Wednesday",
    -3: "Maundy Thursday",
    -2: "Good Friday",
    -1: "Holy Saturday",
    0: "Easter Sunday",
    39: "Ascension Day",
    49: "Pentecost",
    56: "Trinity Sunday",
}

# (month-1-indexed-as-Python, day) → name
FIXED_DATE_HOLIDAYS = {
    (1, 1): "New Year's Day",
    (1, 5): "Epiphany Eve",
    (1, 6): "Epiphany",
    (2, 14): "Valentine's Day",
    (3, 17): "St. Patrick's Day",
    (3, 20): "Spring Equinox",
    (4, 22): "Earth Day",
    (6, 14): "Flag Day",
    (6, 19): "Juneteenth",
    (6, 21): "Summer Solstice",
    (7, 4): "Independence Day",
    (8, 6): "Transfiguration",
    (9, 11): "Patriot Day",
    (9, 21): "International Day of Peace",
    (9, 22): "Autumn Equinox",
    (9, 29): "Michaelmas",
    (10, 31): "Reformation Day",
    (11, 1): "All Saints' Day",
    (11, 11): "Veterans Day",
    (11, 21): "Winter Solstice",
    (12, 24): "Christmas Eve",
    (12, 25): "Christmas Day",
    (12, 31): "New Year's Eve",
}


def compute_easter(year: int) -> date:
    a = year % 19
    b = year // 100
    c = year % 100
    d_ = b // 4
    e = b % 4
    f = (b + 8) // 25
    g = (b - f + 1) // 3
    h = (19 * a + b - d_ - g + 15) % 30
    i = c // 4
    k = c % 4
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * l) // 451
    month = (h + l - 7 * m + 114) // 31
    day = ((h + l - 7 * m + 114) % 31) + 1
    return date(year, month, day)


def ts_weekday(d: date) -> int:
    """0=Sun..6=Sat (matches JS Date.getDay)."""
    return (d.isoweekday()) % 7


def nth_weekday(year: int, month_py: int, ts_wd: int, n: int) -> date:
    d = date(year, month_py, 1)
    seen = 0
    while d.month == month_py:
        if ts_weekday(d) == ts_wd:
            seen += 1
            if seen == n:
                return d
        d += timedelta(days=1)
    raise ValueError(f"nth weekday not found: {year}-{month_py} wd={ts_wd} n={n}")


def last_weekday(year: int, month_py: int, ts_wd: int) -> date:
    if month_py == 12:
        nxt = date(year + 1, 1, 1)
    else:
        nxt = date(year, month_py + 1, 1)
    d = nxt - timedelta(days=1)
    while ts_weekday(d) != ts_wd:
        d -= timedelta(days=1)
    return d


def advent_sundays(year: int) -> list[date]:
    """Four Sundays of Advent (closest Sunday to Nov 30 going backward,
    then the three after)."""
    christmas = date(year, 12, 25)
    # Walk back to find the 4th Sunday before Christmas
    d = christmas
    while ts_weekday(d) != 0:
        d -= timedelta(days=1)
    # d is now the Sunday <= Christmas. Advent 4 = Sunday before Christmas.
    advent4 = d if d != christmas else d - timedelta(days=7)
    return [advent4 - timedelta(days=21), advent4 - timedelta(days=14), advent4 - timedelta(days=7), advent4]


def get_holiday(d: date) -> Optional[str]:
    year = d.year
    month_py = d.month
    month_ts = d.month - 1
    wd = ts_weekday(d)

    # Easter-based
    easter = compute_easter(year)
    delta = (d - easter).days
    if delta in EASTER_OFFSETS:
        return EASTER_OFFSETS[delta]

    # Fixed dates
    if (month_py, d.day) in FIXED_DATE_HOLIDAYS:
        return FIXED_DATE_HOLIDAYS[(month_py, d.day)]

    # Moveable secular holidays
    if month_ts == 4 and wd == 0 and d == nth_weekday(year, 5, 0, 2):
        return "Mother's Day"
    if month_ts == 5 and wd == 0 and d == nth_weekday(year, 6, 0, 3):
        return "Father's Day"
    if month_ts == 10 and wd == 4 and d == nth_weekday(year, 11, 4, 4):
        return "Thanksgiving"
    if month_ts == 0 and wd == 1 and d == nth_weekday(year, 1, 1, 3):
        return "Martin Luther King Jr. Day"
    if month_ts == 1 and wd == 1 and d == nth_weekday(year, 2, 1, 3):
        return "Presidents' Day"
    if month_ts == 4 and wd == 1 and d == last_weekday(year, 5, 1):
        return "Memorial Day"
    if month_ts == 8 and wd == 1 and d == nth_weekday(year, 9, 1, 1):
        return "Labor Day"

    # Baptism of Jesus: First Sunday after Epiphany (Jan 6)
    if month_ts == 0 and wd == 0:
        jan6 = date(year, 1, 6)
        days_until_sunday = (7 - ts_weekday(jan6)) % 7
        baptism_sunday = jan6 + timedelta(days=(7 if days_until_sunday == 0 else days_until_sunday))
        if d == baptism_sunday:
            return "Baptism of Jesus"

    # World Day of Prayer: 1st Friday in March
    if month_ts == 2 and wd == 5 and d == nth_weekday(year, 3, 5, 1):
        return "World Day of Prayer"
    # National Day of Prayer: 1st Thursday in May
    if month_ts == 4 and wd == 4 and d == nth_weekday(year, 5, 4, 1):
        return "National Day of Prayer"
    # Election Day: Tuesday after the 1st Monday in November
    if month_ts == 10 and wd == 2:
        first_mon = nth_weekday(year, 11, 1, 1)
        if d == first_mon + timedelta(days=1):
            return "Election Day"

    # Christ the King Sunday: Sunday before Advent 1
    if wd == 0 and month_ts >= 9:
        advent = advent_sundays(year)
        if d == advent[0] - timedelta(days=7):
            return "Christ the King Sunday"

    # Advent Sundays
    if wd == 0:
        advent = advent_sundays(year)
        for idx, sunday in enumerate(advent):
            if d == sunday:
                return ["First", "Second", "Third", "Fourth"][idx] + " Sunday of Advent"

    return None


def fetch_all_rows() -> list[dict]:
    """Fetch every row with the fields we need to inspect/update."""
    rows: list[dict] = []
    page_size = 500
    offset = 0
    while True:
        url = (
            f"{SUPABASE_URL}/rest/v1/Daily%20Devotional"
            f"?select=id,for_date,devotional_type,verses,holiday_name,holiday_url,anchor_verse,message"
            f"&order=for_date.asc&limit={page_size}&offset={offset}"
        )
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req) as resp:
            batch = json.loads(resp.read())
        rows.extend(batch)
        if len(batch) < page_size:
            break
        offset += page_size
    return rows


# Matches "Book chapter:verse" where Book may have a leading "1 ", "2 ",
# or "3 " (1 Kings, 2 Corinthians, etc.) and may have multi-word names
# joined by spaces (e.g. "Song of Solomon"). Greedy on the chapter:verse
# at the end so we get the first hit, and we constrain Book to start
# with an uppercase letter to skip dates ("3:21" alone won't match).
_BOOK_RE = (
    r"(?:[1-3]\s+)?"  # optional leading number
    r"[A-Z][A-Za-z]+"  # First book word
    r"(?:\s+(?:of\s+)?[A-Z][A-Za-z]+)*"  # optional additional words ("of Solomon")
)
VERSE_REF_RE = re.compile(rf"\b({_BOOK_RE})\s+(\d+):(\d+)\b")


def extract_anchor_from_markdown(message: str) -> Optional[str]:
    """Try to pull out a 'Book chapter:verse' reference from the H1
    title first, then from the first blockquote citation, then
    anywhere in the document. Returns the matched text or None."""
    if not message:
        return None
    lines = message.splitlines()
    # Prefer the H1 title — the AI prompt bakes the reference into it.
    for line in lines:
        if line.startswith("# "):
            m = VERSE_REF_RE.search(line)
            if m:
                return f"{m.group(1)} {m.group(2)}:{m.group(3)}"
            break
    # Then any **Book c:v** in a blockquote (the citation pattern).
    blockquote_cite = re.search(
        rf"\*\*({_BOOK_RE})\s+(\d+):(\d+)\*\*", message
    )
    if blockquote_cite:
        return (
            f"{blockquote_cite.group(1)} "
            f"{blockquote_cite.group(2)}:{blockquote_cite.group(3)}"
        )
    # Last resort: first verse-shaped pattern anywhere.
    m = VERSE_REF_RE.search(message)
    if m:
        return f"{m.group(1)} {m.group(2)}:{m.group(3)}"
    return None


def patch_row(row_id: int, updates: dict) -> None:
    url = f"{SUPABASE_URL}/rest/v1/Daily%20Devotional?id=eq.{row_id}"
    body = json.dumps(updates).encode("utf-8")
    req = urllib.request.Request(url, data=body, method="PATCH", headers=HEADERS)
    try:
        with urllib.request.urlopen(req) as resp:
            resp.read()
    except urllib.error.HTTPError as err:
        detail = err.read().decode("utf-8", errors="replace")
        raise SystemExit(f"PATCH {row_id} failed: {err.code} {detail}") from err


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="Print what would change without writing")
    args = parser.parse_args()

    rows = fetch_all_rows()
    print(f"Fetched {len(rows)} rows.")

    holiday_changes = 0
    anchor_changes = 0
    holidays_seen: dict[str, int] = {}

    for row in rows:
        updates: dict[str, object] = {}
        try:
            d = date.fromisoformat(row["for_date"])
        except (ValueError, TypeError):
            continue

        # Holiday backfill
        if not row.get("holiday_name"):
            name = get_holiday(d)
            if name:
                updates["holiday_name"] = name
                if HOLIDAY_WIKIPEDIA_URLS.get(name):
                    updates["holiday_url"] = HOLIDAY_WIKIPEDIA_URLS[name]
                holidays_seen[name] = holidays_seen.get(name, 0) + 1

        # Anchor verse for single AI devotionals.
        # 1) Prefer the structured `verses` JSONB if present.
        # 2) Fallback to extracting from the message markdown for older
        #    rows that predate the verses column.
        if row.get("devotional_type") == "single" and not row.get("anchor_verse"):
            verses = row.get("verses") or []
            anchor: Optional[str] = None
            if verses:
                v = verses[0]
                book = v.get("book")
                chapter = v.get("chapter")
                verse = v.get("verse")
                if book and chapter is not None and verse is not None:
                    anchor = f"{book} {chapter}:{verse}"
            if not anchor:
                anchor = extract_anchor_from_markdown(row.get("message") or "")
            if anchor:
                updates["anchor_verse"] = anchor

        if not updates:
            continue

        if "holiday_name" in updates:
            holiday_changes += 1
        if "anchor_verse" in updates:
            anchor_changes += 1

        if args.dry_run:
            print(f"[dry-run] id={row['id']} for_date={row['for_date']} → {updates}")
        else:
            patch_row(row["id"], updates)

    print()
    print(f"Holiday rows: {holiday_changes}")
    print(f"Anchor verse rows: {anchor_changes}")
    if holidays_seen:
        print("Holidays detected:")
        for name, n in sorted(holidays_seen.items(), key=lambda kv: -kv[1]):
            print(f"  {n:3d}  {name}")
    if args.dry_run:
        print("\nDry run only — no rows were modified.")


if __name__ == "__main__":
    main()
