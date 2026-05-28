"""
One-shot Xcode project surgery to register summaries_jfb.json as a bundle
resource. Mirrors the same pattern used by add_summaries_to_xcodeproj.py:
sentinel-guarded, anchor-based string insertions, idempotent.
"""
from __future__ import annotations

from pathlib import Path

PBXPROJ = (
    Path(__file__).resolve().parents[1]
    / "ios/swiftbible.xcodeproj"
    / "project.pbxproj"
)

IDS = {
    "build":   "DD0002JFB000000000000001",
    "fileref": "DD0002JFB000000000000002",
}

ANCHOR_PBXBUILDFILE = (
    "\t\tDD0001SUMMARIES0000000005 /* summaries_mhcc.json in Resources */ = "
    "{isa = PBXBuildFile; fileRef = DD0001SUMMARIES0000000006 "
    "/* summaries_mhcc.json */; };"
)
ANCHOR_PBXFILEREF = (
    "\t\tDD0001SUMMARIES0000000006 /* summaries_mhcc.json */ = "
    "{isa = PBXFileReference; lastKnownFileType = text.json; "
    "path = summaries_mhcc.json; sourceTree = \"<group>\"; };"
)
ANCHOR_TEXT_GROUP_TAIL = (
    "\t\t\t\tDD0001SUMMARIES0000000006 /* summaries_mhcc.json */,"
)
ANCHOR_RESOURCES_PHASE = (
    "\t\t\t\tDD0001SUMMARIES0000000005 /* summaries_mhcc.json in Resources */,"
)


PBXBUILDFILE_INSERTION = (
    f"\n\t\t{IDS['build']} /* summaries_jfb.json in Resources */ = "
    f"{{isa = PBXBuildFile; fileRef = {IDS['fileref']} /* summaries_jfb.json */; }};"
)

PBXFILEREF_INSERTION = (
    f"\n\t\t{IDS['fileref']} /* summaries_jfb.json */ = "
    f"{{isa = PBXFileReference; lastKnownFileType = text.json; "
    f"path = summaries_jfb.json; sourceTree = \"<group>\"; }};"
)

TEXT_GROUP_INSERTION = (
    f"\n\t\t\t\t{IDS['fileref']} /* summaries_jfb.json */,"
)

RESOURCES_PHASE_INSERTION = (
    f"\n\t\t\t\t{IDS['build']} /* summaries_jfb.json in Resources */,"
)


def insert_after(body: str, anchor: str, payload: str, label: str) -> str:
    count = body.count(anchor)
    if count == 0:
        raise SystemExit(f"anchor missing: {label}")
    if count > 1:
        raise SystemExit(f"anchor not unique ({count}x): {label}")
    return body.replace(anchor, anchor + payload, 1)


def main() -> None:
    if not PBXPROJ.exists():
        raise SystemExit(f"missing {PBXPROJ}")
    original = PBXPROJ.read_text(encoding="utf-8")

    for key, uid in IDS.items():
        if uid in original:
            raise SystemExit(
                f"pbxproj already contains {uid} — refusing to double-insert"
            )

    body = original
    body = insert_after(body, ANCHOR_PBXBUILDFILE, PBXBUILDFILE_INSERTION, "PBXBuildFile")
    body = insert_after(body, ANCHOR_PBXFILEREF, PBXFILEREF_INSERTION, "PBXFileReference")
    body = insert_after(body, ANCHOR_TEXT_GROUP_TAIL, TEXT_GROUP_INSERTION, "Text group")
    body = insert_after(body, ANCHOR_RESOURCES_PHASE, RESOURCES_PHASE_INSERTION, "Resources phase")

    brace_delta = body.count("{") - original.count("{")
    if brace_delta != 2:
        raise SystemExit(f"brace delta {brace_delta}, expected 2 — aborting")

    backup = PBXPROJ.with_suffix(PBXPROJ.suffix + ".bak.jfb")
    backup.write_text(original, encoding="utf-8")
    PBXPROJ.write_text(body, encoding="utf-8")
    print(f"pbxproj updated. backup at {backup.relative_to(PBXPROJ.parents[2])}")
    print("added: summaries_jfb.json")


if __name__ == "__main__":
    main()
