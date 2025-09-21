# AGENTS NOTEBOOK — `python_parser`

This project feeds generated scriptures into the Swift client living one level up in `../swiftbible`. A couple of traps surfaced while stitching the Book of Enoch parser to the app—captured here so the next agent (or future-me) can move faster.

## Core Flow
- `parse_book_of_enoch.py` ingests `book_of_enoch.txt`, builds a chapter → verse structure, and dumps JSON to `../swiftbible/Text/enoch.json`.
- The Swift client relies on that JSON at runtime. Regenerate it with `python3 parse_book_of_enoch.py`. Because the output path is outside this workspace, the CLI usually prompts for elevated sandbox permissions—expect to rerun with `with_escalated_permissions`.
- Swift’s `ParagraphParser` searches paragraph strings for markers shaped like `chapter:verse[suffix]` and then promotes them into superscript labels at render time.

## Inline Verse Markers
- Keep inline references formatted as `CHAPTER:VERSE` (e.g. `39:10`). **Do not swap them to superscripts inside the JSON.** The Swift code handles presentation and assumes the colon syntax.
- The parser now allows a verse suffix (`a`, `b`, etc.) inside inline markers: `5:6a`, `5:7c`, etc. Presence of any suffix loosens the sequencing guard so mid-verse fragments are still picked up.

## Footnote / Suffix Handling
- Mixed verse letters inside the source (e.g. `6a`, `6b`) serve two roles:
  - When they appear in running text without a preceding chapter number, `apply_superscript_suffixes` converts them to actual superscript glyphs (e.g. `6a → ⁶ᵃ`).
  - When they’re part of inline verse markers the regex leaves the letter intact so we emit `chapter:versesuffix` for the Swift parser.
- The Swift side expects three fields per verse:
  - `Verse.number` (optional main verse integer)
  - `Verse.suffix` (new optional letter suffix)
  - `Verse.segments` (text and JESUS-tag segments)
  Updating either the JSON format or the Swift parser means touching `swiftbible/Models/Verse.swift`, `swiftbible/Services/ParagraphParser.swift`, and `swiftbible/Views/Bible/ParagraphView.swift` together.

## Swift Rendering Contract
- `ParagraphParser` uses regex `\b(\d+:\d+[a-z]?)\b`; if we change the JSON token format, adjust this too.
- `ParagraphView` renders numbers in a gray superscript style. It now appends the suffix (if any) before adding a trailing space. Numbers without suffixes still display exactly as before.
- JESUS tagging is supported via literal `<JESUS>...</JESUS>` wrappers in the JSON. The parser splits them into `.jesus` segments and colorizes in red when the user setting is enabled.

## Testing / Verification Tips
- Quick spot check: after running the parser, open a Python REPL and inspect a problematic passage:
  ```sh
  python3 - <<'PY'
  import json
  from pathlib import Path
  data = json.loads(Path('../swiftbible/Text/enoch.json').read_text())
  for book in data:
      for chapter in book['chapters']:
          if chapter['number'] == 39:
              for para in chapter['paragraphs']:
                  if para['startingVerse'] == 9:
                      print(para['text'])
              break
  PY
  ```
  Expect inline markers like `39:10`, `39:12`, `39:13` in the paragraph text.
- For suffix-heavy sections (chapter 5, chapter 39), ensure output contains `5:6a`, `5:7a`, etc., and that standalone suffixes (e.g. `6a` outside colon expressions) are superscripted.

## Common Pitfalls
- Regeneration overwrites `enoch.json`; if the CLI denies permission, the script still runs but leaves the file untouched—always read the console output.
- Be mindful of non-ASCII output: superscripts are Unicode but already present in the project; keep new text ASCII unless it’s a deliberate superscript conversion.
- The repo may have other pending changes from the user. Never revert unrelated modifications.

Happy parsing!
