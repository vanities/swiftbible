#!/usr/bin/env python3
"""Generate the iOS + Android reading-plan code for "Summer in the Psalms"
from days.py (the single source of truth).

- Android: writes a standalone SummerPsalmsReadingPlan.kt (Gradle auto-compiles
  everything under src/main/java).
- iOS: the main app target uses explicit file references (not a synchronized
  group), so a new .swift file would need a .pbxproj edit. Instead we splice the
  plan INLINE into AppEvent.swift between marker comments — idempotent, so
  re-running after editing days.py just replaces the block.

Reflections are emitted as escaped single-line string literals so neither
Swift multiline-indent stripping nor Kotlin trimIndent can alter the markdown.

Re-run after editing days.py:
  uv run python3 appstore/events/summer-psalms/gen_plan.py
"""
from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
APPEVENT = REPO / "swiftbible" / "Models" / "AppEvent.swift"
KOTLIN_OUT = (
    REPO / "android" / "app" / "src" / "main" / "java"
    / "biz" / "am2" / "swiftbible" / "data" / "SummerPsalmsReadingPlan.kt"
)

START = "    // SUMMER-PSALMS-PLAN START (generated from appstore/events/summer-psalms/days.py — do not edit by hand)"
END = "    // SUMMER-PSALMS-PLAN END"
# Insert before this existing line on first run (when markers aren't present yet):
ANCHOR = "    // MARK: - Pentecost 8-day reading plan (KJV)"


def load_days():
    spec = importlib.util.spec_from_file_location("days", HERE / "days.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.DAYS


def esc(s: str, kotlin: bool = False) -> str:
    s = s.replace("\\", "\\\\").replace('"', '\\"')
    if kotlin:
        s = s.replace("$", "\\$")
    return s.replace("\n", "\\n")


def ymd(date_iso: str) -> tuple[int, int, int]:
    y, m, d = date_iso[:10].split("-")
    return int(y), int(m), int(d)


_BIBLE = json.loads((REPO / "swiftbible" / "Text" / "bible.json").read_text())


def verse_text(book: str, chapter: int, verse: int) -> str:
    for b in _BIBLE:
        if b["name"] != book:
            continue
        for ch in b["chapters"]:
            if ch["number"] != chapter:
                continue
            for p in ch["paragraphs"]:
                if p["startingVerse"] == verse:
                    return " ".join(p["text"].split())
    raise KeyError(f"{book} {chapter}:{verse} not found in bible.json")


def build_reflection(day) -> str:
    """Weave the chosen verses (verbatim KJV) with the per-verse commentary."""
    parts = [day["intro"]]
    for v in day["verses"]:
        parts.append(f'> "{verse_text(day["book"], day["chapter"], v)}" ({day["chapter"]}:{v})')
        comment = day["comment"].get(v, "")
        if comment:
            parts.append(comment)
    parts.append(day["conclusion"])
    return "\n\n".join(parts)


def swift_block(days) -> str:
    out = [
        START,
        "    private static let summerPsalmsReadingPlan: [EventReadingDay] = [",
    ]
    for i, d in enumerate(days):
        # SwiftLint trailing_comma: no comma after the final array element.
        closing = "        )," if i < len(days) - 1 else "        )"
        out += [
            "        EventReadingDay(",
            f'            id: "{d["id"]}",',
            f'            date: parseISO("{d["date_iso"]}"),',
            f'            theme: "{esc(d["theme"])}",',
            f'            passage: ScriptureRef(book: "{d["book"]}", chapter: {d["chapter"]}, '
            f'startVerse: {d["start"]}, endVerse: {d["end"]}),',
            f'            reflection: "{esc(build_reflection(d))}"',
            closing,
        ]
    out += ["    ]", END]
    return "\n".join(out)


def gen_kotlin(days) -> str:
    out = [
        "package biz.am2.swiftbible.data",
        "",
        "import java.time.LocalDate",
        "",
        "// GENERATED from appstore/events/summer-psalms/days.py — do not edit by hand.",
        "// Re-run: uv run python3 appstore/events/summer-psalms/gen_plan.py",
        "internal val summerPsalmsReadingPlan: List<EventReadingDay> = listOf(",
    ]
    for d in days:
        y, m, dd = ymd(d["date_iso"])
        out += [
            "    EventReadingDay(",
            f'        id = "{d["id"]}",',
            f"        date = LocalDate.of({y}, {m}, {dd}),",
            f'        theme = "{esc(d["theme"], kotlin=True)}",',
            f'        passage = ScriptureRef("{d["book"]}", {d["chapter"]}, {d["start"]}, {d["end"]}),',
            f'        reflection = "{esc(build_reflection(d), kotlin=True)}",',
            "    ),",
        ]
    out += [")", ""]
    return "\n".join(out)


def splice_swift(block: str) -> None:
    text = APPEVENT.read_text()
    if START in text and END in text:
        pre = text[: text.index(START)]
        post = text[text.index(END) + len(END):]
        text = pre + block + post
    elif ANCHOR in text:
        text = text.replace(ANCHOR, block + "\n\n" + ANCHOR, 1)
    else:
        sys.exit(f"Could not find markers or anchor in {APPEVENT}")
    APPEVENT.write_text(text)


def main() -> None:
    days = load_days()
    splice_swift(swift_block(days))
    KOTLIN_OUT.write_text(gen_kotlin(days))
    print(f"spliced iOS plan into {APPEVENT.relative_to(REPO)} ({len(days)} days)")
    print(f"wrote {KOTLIN_OUT.relative_to(REPO)} ({len(days)} days)")


if __name__ == "__main__":
    main()
