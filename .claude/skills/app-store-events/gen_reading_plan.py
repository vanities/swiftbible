"""Generate a Swift `[EventReadingDay]` block from a per-event days.py spec.

Usage (from repo root):
    uv run --quiet python3 .claude/skills/app-store-events/gen_reading_plan.py --event pentecost > /tmp/plan.swift

Each event provides its own data at `appstore/events/<slug>/days.py`:
    PLAN_NAME = "<slug>ReadingPlan"   # Swift identifier, e.g. "pentecostReadingPlan"
    DAYS = [{...}, ...]               # one dict per day (see below)

Each day dict:
    id, date_iso, theme,
    book, chapter, start, end,
    intro, comment={verse: str_or_empty}, conclusion

Verse extraction includes partial-verse `<JESUS>...</JESUS>` handling: a verse
like Acts 1:7 ("And he said unto them, <JESUS>It is not for you to know...</JESUS>")
emits two adjacent blockquotes — the narrator framing in normal style, the
Jesus speech with the `[J]` marker — so EventDetailView's red-letter render
matches bible.json exactly instead of flooding the whole verse red.
"""
import argparse
import importlib.util
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]


def load_event_days(slug):
    path = REPO_ROOT / "appstore" / "events" / slug / "days.py"
    if not path.exists():
        sys.exit(f"days.py not found at {path}")
    spec = importlib.util.spec_from_file_location(f"days_{slug}", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    plan_name = getattr(mod, "PLAN_NAME", f"{slug}ReadingPlan")
    return mod.DAYS, plan_name


def parse_chapter(bible, book, ch):
    b = next(x for x in bible if x["name"] == book)
    chap = next(c for c in b["chapters"] if c["number"] == ch)
    out = {}
    for p in chap["paragraphs"]:
        chunks = re.split(rf'\s*({ch}):(\d+)\s*', p["text"])
        out[p["startingVerse"]] = _segments(chunks[0])
        for i in range(1, len(chunks), 3):
            v = int(chunks[i + 1])
            out[v] = _segments(chunks[i + 2])
    return out


def _segments(raw):
    """Split a verse into [(text, is_jesus), ...] preserving boundary order.

    A verse can mix narrator framing with Jesus speech. Returning per-segment
    tuples lets the renderer emit two blockquotes — one normal, one [J] — so
    red-letter rendering matches bible.json exactly.
    """
    parts = re.split(r"(<JESUS>.*?</JESUS>)", raw, flags=re.DOTALL)
    out = []
    for p in parts:
        if not p:
            continue
        if p.startswith("<JESUS>"):
            inner = re.sub(r"</?JESUS>", "", p).strip()
            if inner:
                out.append((inner, True))
        else:
            cleaned = p.strip()
            if cleaned:
                out.append((cleaned, False))
    return out


def render_reflection(day, verses):
    lines = [day["intro"]]
    for v in range(day["start"], day["end"] + 1):
        segments = verses[v]
        # Multi-segment verses (narrator + Jesus, etc.) emit one blockquote
        # per segment with the verse-number citation only on the last line.
        for i, (text, is_jesus) in enumerate(segments):
            marker = "[J] " if is_jesus else ""
            verse_text = text.replace("\\", "\\\\")
            citation = f" (v.{v})" if i == len(segments) - 1 else ""
            lines.append("")
            lines.append(f'> {marker}"{verse_text}"{citation}')
        commentary = day["comment"].get(v, "")
        if commentary:
            lines.append("")
            lines.append(commentary)
    lines.append("")
    lines.append(day["conclusion"])
    return "\n".join(lines)


def render_swift_entry(day, verses):
    refl = render_reflection(day, verses)
    indented = "\n".join(("            " + line) if line else "" for line in refl.split("\n"))
    return f"""        EventReadingDay(
            id: "{day['id']}",
            date: parseISO("{day['date_iso']}"),
            theme: "{day['theme']}",
            passage: ScriptureRef(book: "{day['book']}", chapter: {day['chapter']}, startVerse: {day['start']}, endVerse: {day['end']}),
            reflection: \"\"\"
{indented}
            \"\"\"
        ),"""


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--event", required=True,
                    help="Event slug (folder under appstore/events/<slug>)")
    args = ap.parse_args()

    bible_path = REPO_ROOT / "swiftbible" / "Text" / "bible.json"
    bible = json.loads(bible_path.read_text())
    days, plan_name = load_event_days(args.event)

    out = []
    for day in days:
        verses = parse_chapter(bible, day["book"], day["chapter"])
        out.append(render_swift_entry(day, verses))

    print(f"    private static let {plan_name}: [EventReadingDay] = [")
    print("\n".join(out))
    print("    ]")


if __name__ == "__main__":
    main()
