# AGENTS NOTEBOOK — `python_parser`

This project feeds generated scriptures into the Swift client living one level up in `../swiftbible`. A couple of traps surfaced while stitching the Book of Enoch parser to the app—captured here so the next agent (or future-me) can move faster.

## Core Flow
- `parse_book_of_enoch.py` ingests `book_of_enoch.txt`, builds a chapter → verse structure, and dumps JSON to `../ios/swiftbible/Text/enoch.json`.
- The Swift client relies on that JSON at runtime. Regenerate it with `python3 parse_book_of_enoch.py`. Because the output path is outside this workspace, the CLI usually prompts for elevated sandbox permissions—expect to rerun with `with_escalated_permissions`.
- Swift’s `ParagraphParser` searches paragraph strings for markers shaped like `chapter:verse[suffix]` and then promotes them into superscript labels at render time.

## Other Parsers
- `parse_kjv.py`
  - Reads `kjv.txt` and walks the canonical book headings in order. Each line shaped `CHAPTER:VERSE text...` starts a new paragraph block, while subsequent lines are appended until the next verse marker.
  - Injects Jesus quotations by loading `jesus.json` and wrapping matched phrases in `<JESUS>…</JESUS>` using a case-insensitive regex (the script depends on the third-party `regex` module).
  - Outputs to `../ios/swiftbible/Text/bible.json`. Expect console spam such as `book The Gospel According to Saint Matthew Matthew` while it processes.
- `parse_apocrypha.py`
  - Consumes `apocrypha.txt`, expecting each line as `ABBR CHAPTER:VERSE text` where `ABBR` is defined in `ABBREVIATIONS`.
  - Builds the same chapter/paragraph schema, ensures book ordering via `BOOK_ORDER`, and writes to `../ios/swiftbible/Text/apocrypha.json`.
  - Any unknown abbreviation or malformed line is logged to stdout with its line number—handy when the source text drifts.
- Shared data contract
  - Every parser feeds a list of books, each with `name`, `description`, and a `chapters` array of `{ number, paragraphs }`.
  - Paragraphs must expose `startingVerse` and the raw `text` string that still contains inline tokens for later Swift-side parsing.

## Supplementary Generators
- `generate_verse_info.py`
  - Reads `bible.json`, iterates every paragraph, and calls a remote model (default `llama-3.3-70b-instruct-fp8` via Lambda Labs) to craft commentary.
  - Requires `.env` with `LAMBDA_API_KEY`, `SUPABASE_URL`, and `SUPABASE_ANON_KEY`. Without them the script exits early.
  - Streams progress with `tqdm`, logs to both console and `verse_info.log`, writes successes to `verse_info.csv`, failures to `verse_info_failed.csv`, and upserts each result into Supabase table `verse_info`.
  - Tight loop: editing the JSON schema here means also keeping the Supabase upsert payload in sync.

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
  Updating either the JSON format or the Swift parser means touching `ios/swiftbible/Models/Verse.swift`, `ios/swiftbible/Services/ParagraphParser.swift`, and `ios/swiftbible/Views/Bible/ParagraphView.swift` together.

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
  data = json.loads(Path('../ios/swiftbible/Text/enoch.json').read_text())
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
