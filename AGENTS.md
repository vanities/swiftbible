# AGENTS.md - SwiftBible Repository Documentation

> Universal agent instructions. `CLAUDE.md` is a compatibility symlink for Claude Code.
## Repository Overview

SwiftBible is an iOS application written in Swift that provides access to biblical texts, apocrypha, and pseudepigraphic literature. The app supports multiple text collections with rich navigation, search, and summary features.

## Project Structure

### Core iOS App (`ios/swiftbible/`)
```
swiftbible/
├── Models/
│   ├── Testament.swift           # Enums for text categories (old, new, apocrypha, enoch)
│   └── Version.swift             # Enum for Bible translations (kjv, asv, web)
├── Services/
│   └── BibleService.swift        # Data fetching services with caching per version
├── ViewModels/
│   └── AppViewModel.swift        # Global state including selectedVersion
├── Views/Bible/
│   └── BibleView.swift          # Main UI for browsing texts
├── Text/
│   ├── bible.json               # KJV Old/New Testament data
│   ├── asv.json                 # ASV Old/New Testament data
│   ├── web.json                 # WEB Old/New Testament data
│   ├── apocrypha.json           # Deuterocanonical books
│   ├── enoch.json               # Book of Enoch (5 sections)
│   ├── summaries.swift          # Detailed verse summaries
│   └── ChapterSummaries.swift   # Brief chapter summaries
```

### Python Parsers (`/python_parser/`)
```
python_parser/
├── parse_kjv.py                 # KJV Bible parser (from kjv.txt)
├── parse_asv.py                 # ASV parser (from Zefania XML)
├── parse_web.py                 # WEB parser (from USFX XML)
├── parse_apocrypha.py           # Apocrypha parser
├── parse_book_of_enoch.py       # Book of Enoch parser
├── book_of_enoch.txt            # Raw Enoch text
├── book_of_enoch_info.txt       # Scholarly information about Enoch
└── generate_verse_info.py       # Verse metadata generator
```

## Bible Translations

The app supports multiple Bible translations, all public domain:

### Supported Versions
| Version | Full Name | Year | Characteristics |
|---------|-----------|------|-----------------|
| KJV | King James Version | 1611 | Classic, formal language |
| ASV | American Standard Version | 1901 | Highly literal, scholarly |
| WEB | World English Bible | 2000 | Modern English, based on ASV |

### Version Implementation
```swift
enum Version: String, Codable, CaseIterable {
    case kjv
    case asv
    case web

    var displayName: String { ... }
    var shortName: String { ... }
    var filename: String { ... }  // Maps to JSON file
}
```

### Version Switching
- User selects version in Settings
- `AppViewModel.selectedVersion` stores the current version
- Views use computed properties that derive data from `BibleService.fetchBook(version:)`
- Changes propagate automatically via SwiftUI's @Observable tracking

## Data Architecture

### JSON Structure
All texts follow a consistent JSON structure:
```json
[
  {
    "name": "Book Name",
    "description": "Book description",
    "chapters": [
      {
        "number": 1,
        "paragraphs": [
          {
            "startingVerse": 1,
            "text": "Verse text with inline references like 1:2..."
          }
        ]
      }
    ]
  }
]
```

### Testament Categories
- `old` - Old Testament books
- `new` - New Testament books
- `apocrypha` - Deuterocanonical books
- `enoch` - Book of Enoch sections

## Book of Enoch Integration

### Background
The Book of Enoch is a pseudepigraphic work composed of 5 distinct sections spanning 108 chapters. It was excluded from the biblical canon but provides important historical and theological context.

### The Five Sections
1. **The Book of the Watchers** (Chapters 1-36)
   - Fall of the Watchers (angels) and their offspring (Nephilim)
   - Enoch's heavenly journeys and visions
   - Geography of punishment and blessing

2. **The Book of Parables** (Chapters 37-71)
   - Three parables featuring the "Son of Man"
   - Throne of glory visions
   - Resurrection and final judgment themes

3. **The Astronomical Book** (Chapters 72-82)
   - 364-day solar calendar revealed by angel Uriel
   - Cosmic order and celestial movements
   - Calendar ensuring proper festival timing

4. **The Book of Dream Visions** (Chapters 83-90)
   - Animal Apocalypse - symbolic history from Adam to Maccabees
   - Two major visions: flood and world history

5. **The Epistle of Enoch** (Chapters 91-108)
   - Apocalypse of Weeks (10 periods of history)
   - Woes against sinners, encouragement for righteous
   - Birth of Noah narrative

### Parser Implementation

#### Key Features
- **Sequential chapter numbering**: Maintains original 1-108 numbering across sections
- **Inline verse handling**: Converts "2 living" patterns to "1:2 living" format
- **Text cleaning**: Removes formatting artifacts while preserving references
- **Scholarly organization**: Creates 5 separate books matching academic divisions

#### Parser Logic (`parse_book_of_enoch.py`)
```python
# Section definitions
ENOCH_SECTIONS = [
    {"name": "The Book of the Watchers", "start_chapter": 1, "end_chapter": 36},
    {"name": "The Book of Parables", "start_chapter": 37, "end_chapter": 71},
    # ... etc
]

# Text parsing with inline verse handling
def replace_inline_verse(match):
    verse_num = match.group(1)
    following_text = match.group(2)
    return f" {current_chapter}:{verse_num} {following_text}"

text = re.sub(r' (\d+) ([a-z])', replace_inline_verse, text)
```

### UI Integration

#### BibleView Updates
- Added `@AppStorage("showApocrypha")` toggle controls both Apocrypha and Enoch
- Two separate sections: "Apocrypha" and "Book of Enoch"
- Filtered search support for all Enoch books
- Automatic data fetching with `fetchEnochData()`

#### Data Flow
```
BibleView → BibleService.fetchEnochData() → enoch.json → UI rendering
```

### Summary Integration

#### Verse Summaries (`summaries.swift`)
- 140+ detailed verse summaries covering major themes
- Key concepts: Watchers, Nephilim, Son of Man, cosmic calendar
- Historical context and scholarly insights

#### Chapter Summaries (`ChapterSummaries.swift`)
- Concise summaries for all 108 chapters
- Based on scholarly breakdown from academic sources
- Maintains section organization while preserving chapter flow

## Development Patterns

### Parser Creation Workflow
1. Analyze raw text structure and formatting
2. Identify chapter/verse markers and inline references
3. Create section definitions with start/end chapters
4. Implement text cleaning and reference formatting
5. Generate JSON output matching app structure
6. Update Swift models and services
7. Add UI support and summaries

### File Naming Conventions
- `parse_[collection].py` - Python parsers
- `[collection].json` - JSON data files
- `[Collection]Service` methods in BibleService.swift
- Testament enum cases use lowercase

### Testing Approach

**Unit tests (run these before shipping):**
- iOS: `swiftbibleTests` target — streak/freeze/sabbath date math, badge unlock conditions, `EventReadingDay` UTC-civil-date gating, bundled-text loading. Run with `make test-ios` (or `xcodebuild test … -only-testing:swiftbibleTests`). Uses an in-memory SwiftData store with `cloudKitDatabase: .none`.
- Android: `android/app/src/test/` — streak math, book-intro fallback chain, badge threshold registry, widget formatting. Run with `make test-android`.
- Parsers: `python_parser/test_*.py` — red-letter span placement, plus a guard that the shipped `bible.json`/`asv.json` tags still match `red_letter_map.json` exactly (this is what catches a hand-edited verse or a half-finished rebuild). Stdlib `unittest`, no dependencies. Run with `make test-parsers`.
- `make test` runs all three. CI (`.github/workflows/ci.yml`) runs SwiftLint + every suite on every push/PR.
- Analytics (PostHog) and Sentry skip configuration under XCTest, so tests never emit live events.

**Parser/data validation:**
- Validate chapter counts match source material
- Check sequential numbering preservation
- Verify inline reference formatting
- Ensure JSON structure consistency

**Red letter (Words of Jesus):**

Nothing here is inferred from the text. Spans are imported, reconciled between two independent sources, and stored as word indices in `red_letter_map.json`; `apply_red_letter.py` only turns those indices into `<JESUS>` tags.

| Translation | Where its red letters come from |
|---|---|
| WEB | Its own `<wj>` markup, carried through by `parse_web.py`. Nothing to do. |
| KJV | Two editions that mark Jesus's words on the KJV text itself: `eng-kjv.osis.xml` (`seven1m/open-bibles`, `<q who="Jesus">`) as the base, reconciled against `eng-kjv_usfx.xml` (ebible.org, USFX `<wj>`) and WEB. |
| ASV | No red-letter ASV exists in any public domain format. Projected from the reconciled KJV by word alignment (the ASV is a KJV revision), cross-checked against WEB, and taken from WEB for the verses the KJV renders indirectly. |

**Why two KJV sources.** They have opposite flaws, so each covers the other's. OSIS is the fuller — it marks glosses ("which is, being interpreted, My God, my God…"), Jesus quoted inside someone else's sentence (John 8:33), and verses carrying two separate spans (Luke 8:45) — and the sloppier: it leaves quotations open across whole paragraphs of narrative and drops the KJV's italicised supplied words out of mid-sentence. ebible.org's is cleaner and, being on the same text, gives exact boundaries rather than projected ones — but it marks no glosses or quoted speech at all. After reconciliation the shipped KJV agrees with ebible.org word-for-word on **2,018 of 2,027** shared verses (99.6%), with **no verse it marks that we miss**; the 9 remaining are ones where OSIS and WEB agree against it.

Every correction takes two witnesses, and each run prints what it did:
- **dropped** (17) — OSIS leaves a quotation open across whole paragraphs (Luke 7:1-8, Mark 8:22-25, Matthew 24:1). A verse OSIS reddens *entirely* while WEB reddens *none* of is that bleed.
- **trimmed** (13) — the milestone swallows the narrative introduction (Mark 8:34, "Saying," in Matthew 22:42) or the trailing narrative (Luke 17:14). The two edges are judged differently, and deliberately: **the exact witness decides a verse's opening alone** — its blind spot trails a quotation rather than opening a verse, and it is right in all 11 such verses, including the two where WEB shares the bleed — but **an ending needs WEB to second it**, since a gloss ebible declined to mark sits exactly there and Mark 15:34 would otherwise lose half its verse.
- **rejoined** (2) — Mark 5:41 marks "Damsel," and "arise." but not the "I say unto thee," between them. A gap closes only when WEB marks it as spoken too.
- **overrides** (2) — `red_letter_overrides.json`, hand-reviewed, for what no rule can settle: OSIS omits a quotation the KJV plainly attributes (Matthew 13:57, Luke 22:61). Spans are written as the KJV's own wording, so a stale one is reported rather than silently applied.
- **still differing from WEB** (12 KJV, 8 ASV) — left as the KJV's own markup has them. Reviewed: Revelation 21:5-8 / 22:14-15 (whether the voice from the throne is Christ's), John 16:17-18 (the disciples quoting Jesus), Mark 10:49 (the KJV reports the summons indirectly).

The KJV's italicised supplied words are claimed for the quotation they sit inside, so John 18:5 reads "I am he" rather than a red "I am" with a black "he".

To rebuild:
```bash
cd python_parser
python3 build_red_letter_map.py          # downloads the OSIS source, prints the report
python3 apply_red_letter.py ../ios/swiftbible/Text/bible.json
python3 apply_red_letter.py ../ios/swiftbible/Text/asv.json
```
Then copy to **all three homes** — they are byte-identical:
`ios/swiftbible/Text/`, `android/app/src/main/assets/`, `supabase/functions/daily-devotional/bible.json`.

Read the report before committing: new entries under "dropped", "trimmed" or "still differing" mean a source changed, and a stale override means the text moved under it.

## Technical Decisions

### Why Keep Sequential Chapter Numbering?
- **Scholarly accuracy**: Matches traditional academic references
- **User expectations**: "Enoch 47:3" references work correctly
- **Cross-referencing**: Enables proper citation and study

### Why Separate Enoch from Apocrypha?
- **Theological distinction**: Deuterocanonical vs. pseudepigraphic literature
- **Scholarly organization**: Different historical and canonical status
- **User clarity**: Helps users understand text categories
- **Flexibility**: Independent access and study

### Why 5 Separate Books?
- **Academic accuracy**: Reflects scholarly consensus on composition
- **Thematic organization**: Each section has distinct focus and style
- **Navigation benefits**: Users can study specific aspects (astronomy, dreams, etc.)
- **Historical context**: Preserves understanding of textual development

## Brand Palette

**Source of truth:** `scripts/generate_palette.py` → outputs `scripts/brand-palette.png`

The palette derives from the app icon's peridot (August birthstone) gradient. All colors use `brand{Color}{Variant}` naming in `ios/swiftbible/Extensions/Color.swift`.

| Group | Name | Hex | Usage |
|-------|------|-----|-------|
| **Icon Gradient** | `brandPeridot` | `#BFD900` | Top-left of icon gradient |
| | `brandGreen` | `#33CC66` | Midpoint of icon gradient |
| | `brandCyan` | `#00BFD9` | Bottom-right of icon gradient |
| **Accent** | `brandAccent` | `#00B4A0` | Primary — toggles, links, active tab |
| | `brandAccentLight` | `#00C8B4` | Dark mode variant (brighter) |
| | `brandAccentDark` | `#007A6D` | Pressed states |
| **Warm** | `brandGold` | `#D9AD52` | Cover embossing, splash glow, warmth |
| | `brandGoldLight` | `#FFEDBA` | Page glow, verse text accent |
| **Red** | `brandRed` | `#CC3333` | Jesus's words, emphasis, alerts |
| | `brandRedDark` | `#8C1F1F` | Ribbon bookmark, pressed states |
| **Surface** | `brandDeepNavy` | `#0D1226` | Launch screen, splash background |
| | `brandCoverDark` | `#2E1F14` | Dark leather cover |
| | `brandCoverLight` | `#473321` | Light leather cover |

When adding colors, update `generate_palette.py` first, regenerate the PNG, then update `Color.swift` and `generate_marketing_screenshots.py` to match.

## Deployment

**NEVER manually deploy Edge Functions or push migrations.** Merging to `master` triggers CI/CD which automatically deploys Edge Functions and runs Supabase migrations. Do not run `supabase functions deploy`, `supabase db push`, or any manual deployment commands.

**IMPORTANT: When adding a new Edge Function, you MUST also add it to `.github/workflows/deploy-supabase-functions.yml`.** The CI/CD workflow deploys each function individually — if it's not in the workflow file, it won't be deployed to production.

## Commands and Workflows

### Makefile
The project has a `Makefile` with common commands. Run `make help` to see all targets. Key targets:
- `make dev` - Start full local dev environment (Supabase + Edge Functions + ngrok)
- `make down` - Stop all services
- `make test_daily_devotional` - Trigger the daily devotional Edge Function (requires `SWIFTBIBLE_KEY` and `SWIFTBIBLE_SUPERSECRET_KEY` env vars)
- `make test_slowness` - Profile Swift compile times
- `make fresh` - Reset local Supabase database

### Running Parsers
```bash
cd python_parser
python3 parse_book_of_enoch.py
# Outputs: ../ios/swiftbible/Text/enoch.json
```

### Validation Scripts
```python
# Check chapter numbering
python3 -c "
import json
with open('enoch.json', 'r') as f:
    data = json.load(f)
for book in data:
    chapters = [c['number'] for c in book['chapters']]
    print(f'{book[\"name\"]}: {min(chapters)}-{max(chapters)}')
"
```

### Adding New Text Collections
1. Create `parse_[collection].py` following existing patterns
2. Add new Testament enum case if needed
3. Update BibleService with fetch method
4. Add UI section in BibleView
5. Create summaries in both summary files
6. Test parsing and UI integration

## Future Considerations

### Potential Enhancements
- Additional pseudepigraphic texts (Jubilees, Testament of the Twelve Patriarchs)
- Cross-reference linking between texts
- Advanced search across collections
- Commentary and annotation features

### Maintenance Notes
- Parser outputs should be validated after any text source updates
- UI changes should maintain accessibility and search functionality
- Summary additions should follow established patterns and scholarship

## Repository Insights

### Strengths
- Consistent JSON structure across all text collections
- Clean separation of parsing logic and app logic
- Rich summary and navigation features
- Scholarly accuracy in text organization

### Architecture Benefits
- Modular parser design enables easy addition of new texts
- Swift enums provide type-safe text categorization
- Service layer abstracts data access from UI
- Comprehensive summary system enhances user experience

## Complete App Architecture

### Core Models
```swift
struct Book: Codable, Equatable {
    let name: String
    let description: String
    let chapters: [Chapter]
    var testament: Testament? = .old
    var version: Version = .kjv
}

struct Chapter: Codable, Equatable, Hashable {
    let number: Int
    let paragraphs: [Paragraph]
}

struct Paragraph: Codable, Equatable {
    let startingVerse: Int
    let text: String
}
```

### ViewModels Architecture

#### AppViewModel
- **Purpose**: Global app state management
- **Key Features**:
  - `navigateToVerse()` - Cross-reference navigation
  - `allBibleData` - Unified data store for all texts
  - `selectedVerse` - Current verse selection state
  - `NavigationPath` management

#### UserViewModel
- **Purpose**: User authentication and preferences
- **Integration**: Works with SupabaseService for user management

### Tab-Based Navigation
```swift
enum Tabs: Equatable, Hashable {
    case bible
    case dailyDevotional
    case search
    case settings
}
```

The app uses a TabView with four main sections:
1. **Bible** - Text browsing and reading
2. **Daily Devotional** - Devotional content
3. **Search** - Full-text search across all collections
4. **Settings** - User preferences and app configuration

### Backend Integration (Supabase)

#### Authentication System
- **OTP-based email authentication**
- **Token management** with automatic refresh
- **Session persistence** using AppStorage
- **Row-level security** for user data

#### Database Schema
```sql
-- verse_info table for user commentary/notes
create table public.verse_info (
  id               bigint generated by default as identity primary key,
  created_at       timestamptz not null default now(),
  version          text        not null,
  book             text        not null,
  chapter          int         not null,
  starting_verse   int         not null,
  info             text        not null default '',
  constraint verse_info_one_per_verse
    unique (version, book, chapter, starting_verse)
);
```

#### Security Model
- **Anonymous users**: Read-only access to verse info
- **Authenticated users**: Can add personal notes/commentary
- **Service role**: Full administrative access

### Settings and Customization

#### User Preferences (AppStorage)
```swift
@AppStorage("showJesusWordsInRed") var showJesusWordsInRed = true
@AppStorage("hideNavAndTab") var hideNavAndTab = false
@AppStorage("showApocrypha") var showApocrypha = false
@AppStorage("fontName") private var fontName: String = "Helvetica"
@AppStorage("fontSize") private var fontSize: Int = 20
```

#### Features Available
- **Font customization** - Name and size selection
- **Color options** - Theme and accent colors
- **Jesus's words in red** - Traditional biblical formatting
- **Hide UI while reading** - Immersive reading mode
- **Apocrypha toggle** - Controls both Apocrypha and Enoch sections

### Code Quality and Standards

#### SwiftLint Configuration
```yaml
disabled_rules:
  - trailing_whitespace
  - line_length

opt_in_rules:
  - empty_count
  - force_unwrapping
  - implicitly_unwrapped_optional
  - private_outlet
  - redundant_nil_coalescing

line_length: 120
function_body_length:
  warning: 60
  error: 100
```

#### Standards Enforced
- **Function length limits** (60 lines warning, 100 error)
- **File length limits** (500 lines warning, 1200 error)
- **Cyclomatic complexity** (10 warning, 20 error)
- **Force unwrapping detection**
- **Redundant code elimination**

### External Dependencies

#### Supabase Swift Client
- **Authentication** - OTP email verification
- **Database** - PostgreSQL with RLS
- **Real-time** - WebSocket connections for live updates

#### Key Configuration
```plist
<key>SUPABASE_URL</key>
<string>https://yvanxjoayoiocwzfpkfm.supabase.co</string>
<key>SUPABASE_KEY</key>
<string>[anon-public-key]</string>
```

### App Store Information
- **Bundle ID**: Configurable in project settings
- **GitHub**: https://github.com/vanities/swiftbible
- **Website**: https://am2.biz/swiftbible
- **Contact**: mischke@proton.me
- **App Store ID**: 6670373108

### Advanced Features

#### Cross-Reference Navigation
- Users can navigate directly to specific verses from anywhere in the app
- Deep linking support via `navigateToVerse(bookName:chapterNumber:verseNumber:)`
- Universal verse addressing across all text collections

#### Search Functionality
- Full-text search across Bible, Apocrypha, and Enoch
- Real-time filtering of results
- Contextual highlighting of search terms

#### Note-Taking System
- Personal notes stored per verse
- Supabase backend for sync across devices
- Privacy-focused with row-level security

#### Highlighting System
- User can highlight verses with custom colors
- Persistent storage in backend
- Visual indicators in reading interface

### Python Parser Ecosystem

#### Shared Patterns
All parsers follow consistent patterns:
```python
def parse_text(input_file):
    # Parse raw text into structured chapters/verses

def create_book_structure(chapters, section_info):
    # Convert to JSON structure matching app requirements

def convert_to_json(input_file, output_file):
    # Main conversion pipeline
```

#### Parser-Specific Features
- **KJV Parser**: Handles traditional verse formatting
- **Apocrypha Parser**: Manages deuterocanonical book variations
- **Enoch Parser**: Advanced inline reference handling and section division

### Development Workflow

#### Local Development
```bash
# Run specific parsers
cd python_parser
python3 parse_book_of_enoch.py

# Lint checking
swiftlint lint --config .swiftlint.yml

# Build and test
xcodebuild -project ios/swiftbible.xcodeproj -scheme swiftbible test
```

#### Text Addition Process
1. Create raw text file in `/python_parser/`
2. Develop parser following established patterns
3. Update Testament enum if new category needed
4. Add fetch method to BibleService
5. Update UI in BibleView
6. Add summaries to both summary files
7. Test integration end-to-end

### Accessibility Considerations

#### Built-in Features
- **VoiceOver support** with accessibility identifiers
- **Dynamic Type** support for font scaling
- **High contrast** compatibility
- **Semantic markup** for screen readers

#### Implementation
```swift
.accessibilityIdentifier("BibleView")
.accessibilityLabel("Bible reading interface")
```

### Performance Optimizations

#### Data Loading
- **Lazy loading** of text collections
- **Efficient JSON parsing** with Codable
- **Memory management** for large texts
- **Background loading** for better UX

#### UI Rendering
- **List virtualization** for large chapter/verse lists
- **Image caching** for enhanced performance
- **Navigation optimization** with minimal state changes

This documentation reflects the complete state of the repository as of the Book of Enoch integration and serves as a comprehensive reference for future development and maintenance.
