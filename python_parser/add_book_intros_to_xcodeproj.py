"""
One-shot editor for ios/swiftbible.xcodeproj/project.pbxproj that registers the
"About this book" feature's new files as first-class Xcode project members:

  - BookIntroView.swift          (Views/Bible group → Sources build phase)
  - book_intros_swiftbible.json  (Text group → Resources build phase)
  - book_intros_mhcc.json        (Text group → Resources build phase)
  - book_intros_jfb.json         (Text group → Resources build phase)

Mirrors add_summaries_to_xcodeproj.py: anchor-based string insertion against
unique existing lines, idempotence guard on the synthetic UUIDs, and a
brace-count smoke check. Writes project.pbxproj.bak on success.
"""
from __future__ import annotations

from pathlib import Path

PBXPROJ = (
    Path(__file__).resolve().parents[1]
    / "ios/swiftbible.xcodeproj"
    / "project.pbxproj"
)

# Deterministic, obviously-synthetic 24-char IDs.
IDS = {
    "view_build":      "DD0003INTROS000000000001",
    "view_fileref":    "DD0003INTROS000000000002",
    "sb_build":        "DD0003INTROS000000000003",
    "sb_fileref":      "DD0003INTROS000000000004",
    "mh_build":        "DD0003INTROS000000000005",
    "mh_fileref":      "DD0003INTROS000000000006",
    "jfb_build":       "DD0003INTROS000000000007",
    "jfb_fileref":     "DD0003INTROS000000000008",
}

# --- Anchors (unique full lines already in the file) -----------------------

ANCHOR_PBXBUILDFILE = (
    "\t\tDD0002JFB000000000000001 /* summaries_jfb.json in Resources */ = "
    "{isa = PBXBuildFile; fileRef = DD0002JFB000000000000002 "
    "/* summaries_jfb.json */; };"
)
ANCHOR_PBXFILEREF = (
    "\t\tDD0002JFB000000000000002 /* summaries_jfb.json */ = "
    "{isa = PBXFileReference; lastKnownFileType = text.json; "
    "path = summaries_jfb.json; sourceTree = \"<group>\"; };"
)
ANCHOR_TEXT_GROUP_CHILD = (
    "\t\t\t\tDD0002JFB000000000000002 /* summaries_jfb.json */,"
)
ANCHOR_BIBLE_GROUP_CHILD = (
    "\t\t\t\t954BC9EC2C85012200FFCFA6 /* BookDetailView.swift */,"
)
ANCHOR_RESOURCES_PHASE = (
    "\t\t\t\tDD0002JFB000000000000001 /* summaries_jfb.json in Resources */,"
)
ANCHOR_SOURCES_PHASE = (
    "\t\t\t\t954BC9ED2C85012200FFCFA6 /* BookDetailView.swift in Sources */,"
)

# --- Payloads --------------------------------------------------------------

PBXBUILDFILE_INSERTIONS = (
    f"\n\t\t{IDS['view_build']} /* BookIntroView.swift in Sources */ = "
    f"{{isa = PBXBuildFile; fileRef = {IDS['view_fileref']} /* BookIntroView.swift */; }};"
    f"\n\t\t{IDS['sb_build']} /* book_intros_swiftbible.json in Resources */ = "
    f"{{isa = PBXBuildFile; fileRef = {IDS['sb_fileref']} /* book_intros_swiftbible.json */; }};"
    f"\n\t\t{IDS['mh_build']} /* book_intros_mhcc.json in Resources */ = "
    f"{{isa = PBXBuildFile; fileRef = {IDS['mh_fileref']} /* book_intros_mhcc.json */; }};"
    f"\n\t\t{IDS['jfb_build']} /* book_intros_jfb.json in Resources */ = "
    f"{{isa = PBXBuildFile; fileRef = {IDS['jfb_fileref']} /* book_intros_jfb.json */; }};"
)

PBXFILEREF_INSERTIONS = (
    f"\n\t\t{IDS['view_fileref']} /* BookIntroView.swift */ = "
    f"{{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; "
    f"path = BookIntroView.swift; sourceTree = \"<group>\"; }};"
    f"\n\t\t{IDS['sb_fileref']} /* book_intros_swiftbible.json */ = "
    f"{{isa = PBXFileReference; lastKnownFileType = text.json; "
    f"path = book_intros_swiftbible.json; sourceTree = \"<group>\"; }};"
    f"\n\t\t{IDS['mh_fileref']} /* book_intros_mhcc.json */ = "
    f"{{isa = PBXFileReference; lastKnownFileType = text.json; "
    f"path = book_intros_mhcc.json; sourceTree = \"<group>\"; }};"
    f"\n\t\t{IDS['jfb_fileref']} /* book_intros_jfb.json */ = "
    f"{{isa = PBXFileReference; lastKnownFileType = text.json; "
    f"path = book_intros_jfb.json; sourceTree = \"<group>\"; }};"
)

TEXT_GROUP_INSERTION = (
    f"\n\t\t\t\t{IDS['sb_fileref']} /* book_intros_swiftbible.json */,"
    f"\n\t\t\t\t{IDS['mh_fileref']} /* book_intros_mhcc.json */,"
    f"\n\t\t\t\t{IDS['jfb_fileref']} /* book_intros_jfb.json */,"
)

BIBLE_GROUP_INSERTION = (
    f"\n\t\t\t\t{IDS['view_fileref']} /* BookIntroView.swift */,"
)

RESOURCES_PHASE_INSERTION = (
    f"\n\t\t\t\t{IDS['sb_build']} /* book_intros_swiftbible.json in Resources */,"
    f"\n\t\t\t\t{IDS['mh_build']} /* book_intros_mhcc.json in Resources */,"
    f"\n\t\t\t\t{IDS['jfb_build']} /* book_intros_jfb.json in Resources */,"
)

SOURCES_PHASE_INSERTION = (
    f"\n\t\t\t\t{IDS['view_build']} /* BookIntroView.swift in Sources */,"
)


def ensure_unique(body: str, snippet: str, label: str) -> None:
    count = body.count(snippet)
    if count == 0:
        raise SystemExit(f"anchor missing: {label}")
    if count > 1:
        raise SystemExit(f"anchor appears {count} times — ambiguous: {label}")


def insert_after(body: str, anchor: str, payload: str, label: str) -> str:
    ensure_unique(body, anchor, label)
    return body.replace(anchor, anchor + payload, 1)


def main() -> None:
    if not PBXPROJ.exists():
        raise SystemExit(f"missing {PBXPROJ}")

    original = PBXPROJ.read_text(encoding="utf-8")

    for uid in IDS.values():
        if uid in original:
            raise SystemExit(
                f"pbxproj already contains {uid} — refusing to double-insert."
            )

    body = original
    body = insert_after(body, ANCHOR_PBXBUILDFILE, PBXBUILDFILE_INSERTIONS, "PBXBuildFile")
    body = insert_after(body, ANCHOR_PBXFILEREF, PBXFILEREF_INSERTIONS, "PBXFileReference")
    body = insert_after(body, ANCHOR_TEXT_GROUP_CHILD, TEXT_GROUP_INSERTION, "Text group")
    body = insert_after(body, ANCHOR_BIBLE_GROUP_CHILD, BIBLE_GROUP_INSERTION, "Bible group")
    body = insert_after(body, ANCHOR_RESOURCES_PHASE, RESOURCES_PHASE_INSERTION, "Resources phase")
    body = insert_after(body, ANCHOR_SOURCES_PHASE, SOURCES_PHASE_INSERTION, "Sources phase")

    # Smoke check: 4 PBXBuildFile + 4 PBXFileReference = 8 new `{`.
    brace_delta = body.count("{") - original.count("{")
    if brace_delta != 8:
        raise SystemExit(f"brace-count delta is {brace_delta} (expected 8) — aborting")

    # build IDs appear 2x (entry key + phase member); fileref IDs appear 3x
    # (fileRef value + entry key + group child).
    expected = {
        "view_build": 2, "view_fileref": 3,
        "sb_build": 2, "sb_fileref": 3,
        "mh_build": 2, "mh_fileref": 3,
        "jfb_build": 2, "jfb_fileref": 3,
    }
    for key, uid in IDS.items():
        actual = body.count(uid)
        if actual != expected[key]:
            raise SystemExit(f"ID {uid} ({key}) appears {actual}x, expected {expected[key]}")

    backup = PBXPROJ.with_suffix(PBXPROJ.suffix + ".bak")
    backup.write_text(original, encoding="utf-8")
    PBXPROJ.write_text(body, encoding="utf-8")

    print(f"pbxproj updated. backup at {backup.relative_to(PBXPROJ.parents[2])}")
    for label in (
        "BookIntroView.swift",
        "book_intros_swiftbible.json",
        "book_intros_mhcc.json",
        "book_intros_jfb.json",
    ):
        print(f"  - {label}")


if __name__ == "__main__":
    main()
