"""
One-shot editor for ios/swiftbible.xcodeproj/project.pbxproj that registers the
new summaries files as first-class Xcode project members:

  - SummariesService.swift  (Services group → Sources build phase)
  - summaries_swiftbible.json  (Text group → Resources build phase)
  - summaries_mhcc.json  (Text group → Resources build phase)

Xcode pbxproj is a plist-like text format. This script performs targeted,
anchor-based string insertions rather than attempting a full parse — each
insertion uses a unique anchor line that already exists in the file, so
ordering within sections stays stable and re-runs are idempotent (the script
aborts early if any of its sentinel UUIDs is already present).

Run before building. The script writes `project.pbxproj.bak` next to the
original on success so a fast rollback is possible without `git`.
"""
from __future__ import annotations

import shutil
import sys
from pathlib import Path

PBXPROJ = (
    Path(__file__).resolve().parents[1]
    / "ios/swiftbible.xcodeproj"
    / "project.pbxproj"
)

# Deterministic IDs. 24 chars, unique, obviously synthetic.
IDS = {
    "svc_build":       "DD0001SUMMARIES0000000001",
    "svc_fileref":     "DD0001SUMMARIES0000000002",
    "sb_json_build":   "DD0001SUMMARIES0000000003",
    "sb_json_fileref": "DD0001SUMMARIES0000000004",
    "mh_json_build":   "DD0001SUMMARIES0000000005",
    "mh_json_fileref": "DD0001SUMMARIES0000000006",
}

# Anchors used for insertion. Each anchor must be unique in the file.
# Insertions happen AFTER the anchor line.
ANCHOR_PBXBUILDFILE = (
    "\t\t954BC9EA2C8500F900FFCFA6 /* BibleService.swift in Sources */"
    " = {isa = PBXBuildFile; fileRef = 954BC9E92C8500F900FFCFA6 "
    "/* BibleService.swift */; };"
)
ANCHOR_PBXFILEREF = (
    "\t\t954BC9E92C8500F900FFCFA6 /* BibleService.swift */ = "
    "{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; "
    "path = BibleService.swift; sourceTree = \"<group>\"; };"
)
ANCHOR_TEXT_GROUP_CLOSE = (
    "\t\t\t\t951009872C9525250040B21A /* summaries.swift */,\n"
    "\t\t\t);\n"
    "\t\t\tpath = Text;"
)
ANCHOR_SERVICES_GROUP_OPEN = (
    "\t\t954BC9E82C8500EE00FFCFA6 /* Services */ = {\n"
    "\t\t\tisa = PBXGroup;\n"
    "\t\t\tchildren = ("
)
ANCHOR_RESOURCES_PHASE = (
    "\t\t\t\tCC0000022F5D0001000ORGTX /* greek.json in Resources */,"
)
ANCHOR_SOURCES_PHASE = (
    "\t\t\t\t954BC9EA2C8500F900FFCFA6 /* BibleService.swift in Sources */,"
)

# Content inserted after each anchor.
PBXBUILDFILE_INSERTIONS = (
    f"\n\t\t{IDS['svc_build']} /* SummariesService.swift in Sources */ = "
    f"{{isa = PBXBuildFile; fileRef = {IDS['svc_fileref']} /* SummariesService.swift */; }};"
    f"\n\t\t{IDS['sb_json_build']} /* summaries_swiftbible.json in Resources */ = "
    f"{{isa = PBXBuildFile; fileRef = {IDS['sb_json_fileref']} /* summaries_swiftbible.json */; }};"
    f"\n\t\t{IDS['mh_json_build']} /* summaries_mhcc.json in Resources */ = "
    f"{{isa = PBXBuildFile; fileRef = {IDS['mh_json_fileref']} /* summaries_mhcc.json */; }};"
)

PBXFILEREF_INSERTIONS = (
    f"\n\t\t{IDS['svc_fileref']} /* SummariesService.swift */ = "
    f"{{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; "
    f"path = SummariesService.swift; sourceTree = \"<group>\"; }};"
    f"\n\t\t{IDS['sb_json_fileref']} /* summaries_swiftbible.json */ = "
    f"{{isa = PBXFileReference; lastKnownFileType = text.json; "
    f"path = summaries_swiftbible.json; sourceTree = \"<group>\"; }};"
    f"\n\t\t{IDS['mh_json_fileref']} /* summaries_mhcc.json */ = "
    f"{{isa = PBXFileReference; lastKnownFileType = text.json; "
    f"path = summaries_mhcc.json; sourceTree = \"<group>\"; }};"
)

# Append into the Text group's children — go in BEFORE the closing `);`.
# We replace the anchor (which includes the existing last entry + `);` + path=Text)
# with a version that has our two JSON children inserted between them.
TEXT_GROUP_REPLACEMENT = (
    "\t\t\t\t951009872C9525250040B21A /* summaries.swift */,\n"
    f"\t\t\t\t{IDS['sb_json_fileref']} /* summaries_swiftbible.json */,\n"
    f"\t\t\t\t{IDS['mh_json_fileref']} /* summaries_mhcc.json */,\n"
    "\t\t\t);\n"
    "\t\t\tpath = Text;"
)

# Insert SummariesService.swift as the first child of the Services group.
SERVICES_GROUP_REPLACEMENT = (
    ANCHOR_SERVICES_GROUP_OPEN
    + f"\n\t\t\t\t{IDS['svc_fileref']} /* SummariesService.swift */,"
)

# Append JSON resources into the Resources build phase.
RESOURCES_PHASE_INSERTION = (
    f"\n\t\t\t\t{IDS['sb_json_build']} /* summaries_swiftbible.json in Resources */,"
    f"\n\t\t\t\t{IDS['mh_json_build']} /* summaries_mhcc.json in Resources */,"
)

# Append SummariesService.swift into the Sources build phase.
SOURCES_PHASE_INSERTION = (
    f"\n\t\t\t\t{IDS['svc_build']} /* SummariesService.swift in Sources */,"
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


def replace_once(body: str, old: str, new: str, label: str) -> str:
    ensure_unique(body, old, label)
    return body.replace(old, new, 1)


def main() -> None:
    if not PBXPROJ.exists():
        raise SystemExit(f"missing {PBXPROJ}")

    original = PBXPROJ.read_text(encoding="utf-8")

    # Idempotence guard: bail if any sentinel is already present.
    for key, uid in IDS.items():
        if uid in original:
            raise SystemExit(
                f"pbxproj already contains {uid} — refusing to double-insert "
                f"(re-running this script twice would corrupt the project). "
                f"If you're intentionally re-running after a revert, delete "
                f"the bak file first."
            )

    body = original

    # 1. PBXBuildFile section
    body = insert_after(
        body,
        ANCHOR_PBXBUILDFILE,
        PBXBUILDFILE_INSERTIONS,
        "PBXBuildFile section",
    )

    # 2. PBXFileReference section
    body = insert_after(
        body,
        ANCHOR_PBXFILEREF,
        PBXFILEREF_INSERTIONS,
        "PBXFileReference section",
    )

    # 3. Text group members
    body = replace_once(
        body,
        ANCHOR_TEXT_GROUP_CLOSE,
        TEXT_GROUP_REPLACEMENT,
        "Text group children",
    )

    # 4. Services group members
    body = replace_once(
        body,
        ANCHOR_SERVICES_GROUP_OPEN,
        SERVICES_GROUP_REPLACEMENT,
        "Services group children",
    )

    # 5. Resources build phase
    body = insert_after(
        body,
        ANCHOR_RESOURCES_PHASE,
        RESOURCES_PHASE_INSERTION,
        "Resources build phase",
    )

    # 6. Sources build phase
    body = insert_after(
        body,
        ANCHOR_SOURCES_PHASE,
        SOURCES_PHASE_INSERTION,
        "Sources build phase",
    )

    # Smoke checks.
    # Each new entry (3 PBXBuildFile + 3 PBXFileReference = 6 total) contributes
    # exactly one `{` to the body. Anything else means string replacement went
    # sideways.
    brace_delta = body.count("{") - original.count("{")
    if brace_delta != 6:
        raise SystemExit(
            f"brace-count delta is {brace_delta} (expected 6) — aborting"
        )

    # A build-file ID (svc_build, sb_json_build, mh_json_build) appears 2x:
    #   - as the PBXBuildFile entry's key
    #   - as a member of its build phase's files array
    # A file-ref ID (svc_fileref, sb_json_fileref, mh_json_fileref) appears 3x:
    #   - as the fileRef value inside its PBXBuildFile entry
    #   - as the PBXFileReference entry's key
    #   - as a member of its parent group's children array
    expected_counts = {
        "svc_build":       2,
        "svc_fileref":     3,
        "sb_json_build":   2,
        "sb_json_fileref": 3,
        "mh_json_build":   2,
        "mh_json_fileref": 3,
    }
    for key, uid in IDS.items():
        actual = body.count(uid)
        want = expected_counts[key]
        if actual != want:
            raise SystemExit(
                f"ID {uid} ({key}) appears {actual}x, expected {want}"
            )

    backup = PBXPROJ.with_suffix(PBXPROJ.suffix + ".bak")
    backup.write_text(original, encoding="utf-8")
    PBXPROJ.write_text(body, encoding="utf-8")

    print(f"pbxproj updated. backup at {backup.relative_to(PBXPROJ.parents[2])}")
    print("added:")
    for label in (
        "SummariesService.swift",
        "summaries_swiftbible.json",
        "summaries_mhcc.json",
    ):
        print(f"  - {label}")


if __name__ == "__main__":
    main()
