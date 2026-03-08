# Next Text Packs Roadmap (Apocrypha/Enoch-style)

This guide documents:

1. **What to add next** (high-value text packs users ask for)
2. **How to fetch source text with `curl`**
3. **How to parse into the app JSON schema**
4. **How to wire the text into the app behind a Settings toggle**

---

## 1) What to add next

Suggested order (best mix of demand + implementation effort):

1. **Book of Jubilees** (most requested alongside Enoch)
2. **Testaments of the Twelve Patriarchs**
3. **2 Enoch**
4. **Didache** (early Christian writing)
5. **1 Clement**

Optional later set:

- Shepherd of Hermas
- Odes of Solomon
- 3 Baruch
- 4 Ezra / 2 Esdras variants (if you want alternate traditions/editions)

> Recommendation: add one corpus at a time (e.g., Jubilees), then repeat the same ingest/parser/app wiring pattern.

---

## 2) Where to get texts with curl

Use public-domain or permissively licensed translations only.

### 2.1 Quick download template

```bash
mkdir -p python_parser/sources
curl -L "<DIRECT_TEXT_URL>" -o python_parser/sources/<slug>.txt
```

### 2.2 Source options

- **Project Gutenberg** (public domain editions; sometimes needs cleanup)
- **Internet Archive text exports**
- **Public domain mirrors on GitHub (`raw.githubusercontent.com`)**

### 2.3 Example command set (replace with your chosen direct links)

```bash
# Example placeholders — use direct raw .txt URLs you approve.
curl -L "https://raw.githubusercontent.com/<org>/<repo>/<branch>/jubilees.txt" \
  -o python_parser/sources/jubilees.txt

curl -L "https://raw.githubusercontent.com/<org>/<repo>/<branch>/testaments12.txt" \
  -o python_parser/sources/testaments12.txt
```

### 2.4 Licensing checklist (required)

Before merging text content:

- Confirm the translation is public domain or explicitly redistributable.
- Capture source URL and license note in commit message or a short `Text/SOURCES.md` log.
- If license is unclear, do **not** ship it.

---

## 3) Parser: convert raw text to app JSON format

The app expects a `Book` list JSON structure (same schema used by `bible.json`, `apocrypha.json`, `enoch.json`).

Use existing parsers as templates:

- `python_parser/parse_apocrypha.py`
- `python_parser/parse_book_of_enoch.py`

### 3.1 Create a new parser

Create `python_parser/parse_<slug>.py` that outputs:

- `../swiftbible/Text/<slug>.json`

Use this normalized shape per book:

```json
[
  {
    "name": "Book Name",
    "description": "Short Description",
    "chapters": [
      {
        "number": 1,
        "paragraphs": [
          { "startingVerse": 1, "text": "Verse text..." }
        ]
      }
    ]
  }
]
```

### 3.2 Parser implementation checklist

- Normalize headings (book/chapter markers)
- Split verses reliably (regex + fallback handling)
- Remove footnotes/editorial artifacts
- Preserve verse ordering
- Ensure integers for chapter/verse numbers
- Emit UTF-8 JSON with pretty formatting for diffs

### 3.3 Run parser

```bash
cd python_parser
python parse_<slug>.py
```

Then verify the output exists:

```bash
test -f ../swiftbible/Text/<slug>.json && echo "ok"
```

---

## 4) Integrate into app (toggle + loading + UI)

Below is the exact wiring pattern currently used by Apocrypha + Enoch.

### 4.1 Add a new testament bucket/name list

Update `swiftbible/Models/Testament.swift`:

- Add a new enum case (example: `.jubilees`)
- Add canonical order list (example: `static let jubileesNames = [...]`)

### 4.2 Add data fetch in BibleService

Update `swiftbible/Services/BibleService.swift`:

- Add `fetch<Corpus>Data()`
- Load `Bundle.main.url(forResource: "<slug>", withExtension: "json")`
- Decode `[Book]`
- Assign `book.testament = .<newCase>`

### 4.3 Add Settings toggle

Update `swiftbible/Views/Settings/SettingsView.swift`:

- Add `@AppStorage("show<Corpus>") var show<Corpus> = false`
- Add a `Toggle(...)`
- Emit analytics event on change

Also add analytics event in `swiftbible/Services/AnalyticsService.swift`:

- Add `case <corpus>Toggled = "<corpus>_toggled"`

### 4.4 Show section in Bible list

Update `swiftbible/Views/Bible/BibleView.swift`:

- Extend local state tuple with new corpus array
- Add filtered computed property (mirroring apocrypha/enoch)
- Fetch on appear
- Fetch when toggle flips on
- Render a conditional `Section(header: Text("<Corpus Title>"))`

### 4.5 Include in deep-link/navigation lookup

Update `swiftbible/ViewModels/AppViewModel.swift`:

- In `ensureBibleDataLoadedIfNeeded()`, append new corpus to `combinedBooks`
- In `navigateToVerse(...)`, append new corpus to `books`

### 4.6 Include in AI source labeling (optional but recommended)

Update `swiftbible/Models/VerseExplanationRequest.swift`:

- Extend `sourceDescriptor` to return corpus label
- Update `shouldDisplayTranslationBadge` logic if corpus is non-translation

### 4.7 Ensure JSON is bundled

- Confirm `swiftbible/Text/<slug>.json` is in the app target resources.
- If not auto-included, add in Xcode target membership.

---

## 5) End-to-end checklist (copy/paste)

```bash
# 1) download text
curl -L "<DIRECT_TEXT_URL>" -o python_parser/sources/<slug>.txt

# 2) parse to app JSON
cd python_parser
python parse_<slug>.py

# 3) return to repo root
cd ..

# 4) verify new text file exists
test -f swiftbible/Text/<slug>.json && echo "json ready"

# 5) run your normal app build/test flow
# (xcodebuild / unit tests / UI smoke test)
```

---

## 6) Suggested first implementation: Jubilees

If you want the fastest next win, implement **Jubilees** first using this exact sequence:

1. Add `swiftbible/Text/jubilees.json`
2. Add `parse_jubilees.py`
3. Add `.jubilees` case + names in `Testament`
4. Add `fetchJubileesData()` in `BibleService`
5. Add `showJubilees` toggle in Settings
6. Add Jubilees section in `BibleView`
7. Include in `AppViewModel` lookup and `VerseExplanationRequest`

After that, reuse the same pattern for each additional corpus.
