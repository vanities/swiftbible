// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { initSentry, captureException } from "../_shared/sentry.ts";
import { selectRandomVerse as sharedSelectRandomVerse } from "../_shared/verse-selection.ts";
import {
  PROMPT_THEOLOGY_GUARDRAILS,
  PROMPT_MATT_RULES,
  PROMPT_JOSH_RULES,
} from "../_shared/devotional-voice.ts";

// ─── Types ──────────────────────────────────────────────────────────

interface Book {
  name: string;
  description: string;
  chapters: Chapter[];
}
interface Chapter {
  number: number;
  paragraphs: Paragraph[];
}
interface Paragraph {
  startingVerse: number;
  text: string;
}
interface SelectedVerse {
  book: string;
  chapter: number;
  verse: number;
  text: string;
  testament: "old" | "new";
}
interface Holiday {
  name: string;
  themeHint: string;
  verses: SelectedVerse[];
  wikipediaUrl?: string;
}

// Wikipedia URLs for holiday names. Looked up by Holiday.name in
// getHoliday() and attached to the returned object so we don't have to
// edit every holiday literal. Keys MUST exactly match the .name values
// returned by getHolidayInternal — names not present here just get no
// link. All URLs verified live (HTTP 200) on 2026-04-26.
const HOLIDAY_WIKIPEDIA_URLS: Record<string, string> = {
  // Easter cycle
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
  // Fixed-date Christian
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
  "Christ the King Sunday": "https://en.wikipedia.org/wiki/Feast_of_Christ_the_King",
  // Advent — each Sunday is a distinct .name
  "First Sunday of Advent": "https://en.wikipedia.org/wiki/Advent",
  "Second Sunday of Advent": "https://en.wikipedia.org/wiki/Advent",
  "Third Sunday of Advent": "https://en.wikipedia.org/wiki/Advent",
  "Fourth Sunday of Advent": "https://en.wikipedia.org/wiki/Advent",
  // Moveable secular
  "Mother's Day": "https://en.wikipedia.org/wiki/Mother%27s_Day",
  "Father's Day": "https://en.wikipedia.org/wiki/Father%27s_Day",
  "Thanksgiving": "https://en.wikipedia.org/wiki/Thanksgiving_(United_States)",
  "Martin Luther King Jr. Day": "https://en.wikipedia.org/wiki/Martin_Luther_King_Jr._Day",
  "Presidents' Day": "https://en.wikipedia.org/wiki/Washington%27s_Birthday",
  "Memorial Day": "https://en.wikipedia.org/wiki/Memorial_Day",
  "Labor Day": "https://en.wikipedia.org/wiki/Labor_Day",
  "Election Day": "https://en.wikipedia.org/wiki/Election_Day_(United_States)",
  "World Day of Prayer": "https://en.wikipedia.org/wiki/World_Day_of_Prayer",
  "National Day of Prayer": "https://en.wikipedia.org/wiki/National_Day_of_Prayer",
  // Fixed-date secular & seasonal
  "Independence Day": "https://en.wikipedia.org/wiki/Independence_Day_(United_States)",
  "Juneteenth": "https://en.wikipedia.org/wiki/Juneteenth",
  "Veterans Day": "https://en.wikipedia.org/wiki/Veterans_Day",
  "Valentine's Day": "https://en.wikipedia.org/wiki/Valentine%27s_Day",
  "St. Patrick's Day": "https://en.wikipedia.org/wiki/Saint_Patrick%27s_Day",
  "Earth Day": "https://en.wikipedia.org/wiki/Earth_Day",
  "Flag Day": "https://en.wikipedia.org/wiki/Flag_Day_(United_States)",
  "Patriot Day": "https://en.wikipedia.org/wiki/Patriot_Day",
  "International Day of Peace": "https://en.wikipedia.org/wiki/International_Day_of_Peace",
  "Michaelmas": "https://en.wikipedia.org/wiki/Michaelmas",
  "Spring Equinox": "https://en.wikipedia.org/wiki/March_equinox",
  "Summer Solstice": "https://en.wikipedia.org/wiki/Summer_solstice",
  "Autumn Equinox": "https://en.wikipedia.org/wiki/September_equinox",
  "Winter Solstice": "https://en.wikipedia.org/wiki/Winter_solstice",
};

// ─── Load local KJV Bible data ──────────────────────────────────────

// deno-lint-ignore no-explicit-any
import bibleJson from "./bible.json" with { type: "json" };
const bibleData: Book[] = bibleJson as any;

const OT_BOOKS = bibleData.slice(0, 39);
const NT_BOOKS = bibleData.slice(39);

// ─── Verse text lookup from bible.json ──────────────────────────────

// bible.json carries <JESUS>...</JESUS> red-letter markup. Every path that
// hands verse text to a prompt (or straight into the devotional blockquote)
// must strip it, or the raw tags render verbatim in the app.
//
// Only the tags go — never the whitespace hugging them. 418 KJV paragraphs
// carry an inline verse number between two tags ("…against thee; </JESUS>5:24
// <JESUS> Leave there…"), so eating the adjacent space would run words and
// verse numbers together. The trailing space that "…life. </JESUS>" leaves is
// handled by trim(): the surrounding quote comes from the prompt template, not
// from the verse text. The iOS/Android clients and the 20260812090000 backfill
// migration apply the same substitution — keep all four in step.
export function stripJesusTags(text: string): string {
  return text.replace(/<\/?JESUS>/g, "").trim();
}

function lookupVerseText(
  bookName: string,
  chapterNum: number,
  verseNum: number
): string | null {
  const book = bibleData.find((b) => b.name === bookName);
  if (!book) return null;
  const chapter = book.chapters.find((c) => c.number === chapterNum);
  if (!chapter) return null;

  // Try exact match first
  let paragraph = chapter.paragraphs.find(
    (p) => p.startingVerse === verseNum
  );

  // If not found, find the paragraph that contains this verse
  // (startingVerse <= verseNum < next paragraph's startingVerse)
  if (!paragraph) {
    const sorted = [...chapter.paragraphs].sort(
      (a, b) => a.startingVerse - b.startingVerse
    );
    for (let i = sorted.length - 1; i >= 0; i--) {
      if (sorted[i].startingVerse <= verseNum) {
        paragraph = sorted[i];
        break;
      }
    }
  }

  if (!paragraph) return null;
  return stripJesusTags(paragraph.text);
}

const OPENAI_CHAT_URL = "https://api.openai.com/v1/chat/completions";

// LLM models. SINGLE SOURCE OF TRUTH — set here, nowhere else.
//
// These were previously overridable via Supabase secrets. That override sat on
// gpt-5.5 from 2026-05-02 while this file claimed otherwise, so a model "change"
// in code shipped nothing for months. The secret has been removed; do not
// reintroduce an env fallback. Change the model by editing these two lines and
// deploying, then confirm against the `model` column on a freshly generated row.
//
// Pinned to explicit tier ids, never the bare "gpt-5.6" alias — that alias
// routes to Sol and would silently change both quality and price under us.
//
// The model used for each devotional is persisted to the "Daily Devotional".model
// column so the iOS and Android apps can attribute it accurately.
const DEVOTIONAL_MODEL = "gpt-5.6-terra";
const VERSE_SELECTION_MODEL = "gpt-5.6-luna";

// Two parallel prompt tracks rotate randomly to vary the daily devotional
// voice. The "Daily Devotional" table's prompt_version column records
// which track + iteration produced each row.
//
//   empathy — four-beat empathy/Bible/mix/prayer structure with avoid-list,
//             few-shot example, and modern observable scenes. v1–v4 of
//             this track were originally tagged "daily-vN"; backfilled to
//             "empathy-vN" in 20260509130000_rename_daily_to_empathy.sql.
//             v5 is the implicit pre-fix state; v6 (current) reverts the
//             prayer from blockquote to italics (matches v1 historical
//             rendering, avoids the iOS verse-link detector mistakenly
//             treating the prayer as a verse), expands the avoid rule to
//             cover fragment stacking (v4's new failure mode), tilts the
//             subtitle toward question form, and softly caps beat 2 length.
//
//   technical — restored from the original v1 prompt: numbered guidelines,
//               Contextual/Historical/Cultural/Linguistic sections,
//               reflection-question bullet list, italic final meditation.
//               Heavier on biblical-historical content, lighter on modern
//               empathy. Mixed in for voice variety and reader range.
//
//   prayer address (empathy-v8 / technical-v3 / narrative-v3 / practical-v4):
//             all four tracks now default the closing prayer's address to the
//             Father, reserving a direct address to Jesus ("Lord Jesus") for
//             verses that themselves model prayer or a cry to Jesus (the dying
//             thief's "Lord, remember me," or "Come, Lord Jesus"), and drop the
//             Holy Spirit as an address entirely. The NT prayer pattern is to
//             the Father, through the Son; the Spirit carries prayer rather
//             than receiving it. The narrative few-shot (Zacchaeus) was
//             re-aimed Father-ward to match, since few-shots steer harder than
//             rules.
const EMPATHY_PROMPT_VERSION = "empathy-v8";
const TECHNICAL_PROMPT_VERSION = "technical-v3";
const NARRATIVE_PROMPT_VERSION = "narrative-v3";
const PRACTICAL_PROMPT_VERSION = "practical-v4";
const MATT_PROMPT_VERSION = "matt-v1";
const JOSH_PROMPT_VERSION = "josh-v1";
const LAMENT_PROMPT_VERSION = "lament-v1";
const QUESTION_PROMPT_VERSION = "question-v1";
const CHARACTER_PROMPT_VERSION = "character-v1";

// Per-model pricing in USD per million tokens (input, output).
// Source: OpenAI pricing page, snapshotted 2026-08-27.
// Update when pricing changes; cost is locked-in at generation time so
// historical rows keep the price actually paid. Retired models stay listed
// so historical rows can still be costed.
const MODEL_PRICING: Record<string, { input: number; output: number }> = {
  // GPT-5.6 family (GA 2026-07-09)
  "gpt-5.6-sol":   { input: 5.00,  output: 30.00 },
  "gpt-5.6-terra": { input: 2.00,  output: 12.00 },
  "gpt-5.6-luna":  { input: 0.20,  output:  1.20 },
  // retired — kept for historical cost lookup
  "gpt-5.5":      { input: 5.00,  output: 30.00 },
  "gpt-5.4":      { input: 2.50,  output: 15.00 },
  "gpt-5.4-mini": { input: 0.75,  output:  4.50 },
};

function computeCost(
  model: string,
  prompt_tokens: number,
  completion_tokens: number
): number {
  const p = MODEL_PRICING[model];
  if (!p) return 0;
  return (
    (prompt_tokens * p.input + completion_tokens * p.output) / 1_000_000
  );
}

// Token usage captured from each OpenAI call and persisted alongside
// each devotional for cost auditing. cost_usd is computed at the time
// of the call using MODEL_PRICING, so historical rows reflect the
// price that was actually paid.
interface TokenUsage {
  model: string;
  prompt_tokens: number;
  completion_tokens: number;
  total_tokens: number;
  cost_usd: number;
}

interface DevotionalUsage {
  generation: TokenUsage;
  selection?: TokenUsage;
}

function extractUsage(
  data: { usage?: { prompt_tokens?: number; completion_tokens?: number; total_tokens?: number } } | null | undefined,
  model: string
): TokenUsage {
  const prompt_tokens = data?.usage?.prompt_tokens ?? 0;
  const completion_tokens = data?.usage?.completion_tokens ?? 0;
  return {
    model,
    prompt_tokens,
    completion_tokens,
    total_tokens: data?.usage?.total_tokens ?? 0,
    cost_usd: computeCost(model, prompt_tokens, completion_tokens),
  };
}

// ─── Easter computation (Anonymous Gregorian algorithm) ─────────────

function computeEaster(year: number): Date {
  const a = year % 19;
  const b = Math.floor(year / 100);
  const c = year % 100;
  const d = Math.floor(b / 4);
  const e = b % 4;
  const f = Math.floor((b + 8) / 25);
  const g = Math.floor((b - f + 1) / 3);
  const h = (19 * a + b - d - g + 15) % 30;
  const i = Math.floor(c / 4);
  const k = c % 4;
  const l = (32 + 2 * e + 2 * i - h - k) % 7;
  const m = Math.floor((a + 11 * h + 22 * l) / 451);
  const month = Math.floor((h + l - 7 * m + 114) / 31);
  const day = ((h + l - 7 * m + 114) % 31) + 1;
  return new Date(year, month - 1, day);
}

function addDays(date: Date, days: number): Date {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
}

function getNthWeekday(
  year: number,
  month: number,
  weekday: number,
  n: number
): Date {
  const first = new Date(year, month, 1);
  let diff = weekday - first.getDay();
  if (diff < 0) diff += 7;
  return new Date(year, month, 1 + diff + (n - 1) * 7);
}

function getLastWeekday(year: number, month: number, weekday: number): Date {
  const lastDay = new Date(year, month + 1, 0);
  const diff = (lastDay.getDay() - weekday + 7) % 7;
  return new Date(year, month, lastDay.getDate() - diff);
}

function getAdventSundays(year: number): Date[] {
  const christmas = new Date(year, 11, 25);
  const dow = christmas.getDay();
  const daysBack = dow === 0 ? 7 : dow;
  const advent4 = new Date(year, 11, 25 - daysBack);
  return [
    addDays(advent4, -21),
    addDays(advent4, -14),
    addDays(advent4, -7),
    advent4,
  ];
}

function sameDay(a: Date, b: Date): boolean {
  return a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate();
}

// ─── Holiday calendar ───────────────────────────────────────────────

function getHoliday(date: Date): Holiday | null {
  const holiday = getHolidayInternal(date);
  if (!holiday) return null;
  const url = HOLIDAY_WIKIPEDIA_URLS[holiday.name];
  return url ? { ...holiday, wikipediaUrl: url } : holiday;
}

function getHolidayInternal(date: Date): Holiday | null {
  const year = date.getFullYear();
  const month = date.getMonth(); // 0-indexed
  const day = date.getDate();

  // ── Easter-based moveable feasts ──
  const easter = computeEaster(year);
  const easterHolidays: Array<{ offset: number; holiday: Holiday }> = [
    {
      offset: -47,
      holiday: {
        name: "Shrove Tuesday",
        themeHint:
          "Today is Shrove Tuesday, the day before Lent begins — traditionally a day of feasting and preparation before the season of fasting. The devotional should reflect themes of celebration before sacrifice, preparation of the heart, and the rhythm of spiritual seasons.",
        verses: [
          { book: "Matthew", chapter: 6, verse: 16, text: "Moreover when ye fast, be not, as the hypocrites, of a sad countenance: for they disfigure their faces, that they may appear unto men to fast. Verily I say unto you, They have their reward.", testament: "new" },
          { book: "Joel", chapter: 2, verse: 12, text: "Therefore also now, saith the LORD, turn ye even to me with all your heart, and with fasting, and with weeping, and with mourning.", testament: "old" },
          { book: "1 Corinthians", chapter: 10, verse: 31, text: "Whether therefore ye eat, or drink, or whatsoever ye do, do all to the glory of God.", testament: "new" },
          { book: "Ecclesiastes", chapter: 3, verse: 1, text: "To every thing there is a season, and a time to every purpose under the heaven.", testament: "old" },
          { book: "Isaiah", chapter: 58, verse: 6, text: "Is not this the fast that I have chosen? to loose the bands of wickedness, to undo the heavy burdens, and to let the oppressed go free, and that ye break every yoke?", testament: "old" },
          { book: "2 Corinthians", chapter: 7, verse: 1, text: "Having therefore these promises, dearly beloved, let us cleanse ourselves from all filthiness of the flesh and spirit, perfecting holiness in the fear of God.", testament: "new" },
        ],
      },
    },
    {
      offset: -46,
      holiday: {
        name: "Ash Wednesday",
        themeHint:
          "Today is Ash Wednesday, the beginning of Lent — a season of repentance, fasting, and spiritual renewal. The devotional should reflect themes of humility, turning back to God, and examining one's heart.",
        verses: [
          { book: "Joel", chapter: 2, verse: 13, text: "And rend your heart, and not your garments, and turn unto the LORD your God: for he is gracious and merciful, slow to anger, and of great kindness, and repenteth him of the evil.", testament: "old" },
          { book: "Psalms", chapter: 51, verse: 10, text: "Create in me a clean heart, O God; and renew a right spirit within me.", testament: "old" },
          { book: "Matthew", chapter: 6, verse: 6, text: "But thou, when thou prayest, enter into thy closet, and when thou hast shut thy door, pray to thy Father which is in secret; and thy Father which seeth in secret shall reward thee openly.", testament: "new" },
          { book: "Genesis", chapter: 3, verse: 19, text: "In the sweat of thy face shalt thou eat bread, till thou return unto the ground; for out of it wast thou taken: for dust thou art, and unto dust shalt thou return.", testament: "old" },
          { book: "Psalms", chapter: 103, verse: 14, text: "For he knoweth our frame; he remembereth that we are dust.", testament: "old" },
          { book: "James", chapter: 4, verse: 10, text: "Humble yourselves in the sight of the Lord, and he shall lift you up.", testament: "new" },
        ],
      },
    },
    {
      offset: -21,
      holiday: {
        name: "Laetare Sunday",
        themeHint:
          "Today is Laetare Sunday, the midpoint of Lent — also known as 'Rejoice Sunday.' After weeks of penitence, the Church pauses to rejoice in anticipation of Easter. The devotional should reflect themes of joy amid discipline, refreshment on the journey, and the nourishment God provides.",
        verses: [
          { book: "Isaiah", chapter: 66, verse: 10, text: "Rejoice ye with Jerusalem, and be glad with her, all ye that love her: rejoice for joy with her, all ye that mourn for her.", testament: "old" },
          { book: "John", chapter: 6, verse: 35, text: "And Jesus said unto them, I am the bread of life: he that cometh to me shall never hunger; and he that believeth on me shall never thirst.", testament: "new" },
          { book: "Psalms", chapter: 122, verse: 1, text: "I was glad when they said unto me, Let us go into the house of the LORD.", testament: "old" },
          { book: "Philippians", chapter: 4, verse: 4, text: "Rejoice in the Lord alway: and again I say, Rejoice.", testament: "new" },
          { book: "Nehemiah", chapter: 8, verse: 10, text: "Then he said unto them, Go your way, eat the fat, and drink the sweet, and send portions unto them for whom nothing is prepared: for this day is holy unto our Lord: neither be ye sorry; for the joy of the LORD is your strength.", testament: "old" },
          { book: "Romans", chapter: 15, verse: 13, text: "Now the God of hope fill you with all joy and peace in believing, that ye may abound in hope, through the power of the Holy Ghost.", testament: "new" },
        ],
      },
    },
    {
      offset: -7,
      holiday: {
        name: "Palm Sunday",
        themeHint:
          "Today is Palm Sunday, celebrating Jesus's triumphal entry into Jerusalem. The devotional should reflect themes of kingship, humility, praise, and the beginning of Holy Week.",
        verses: [
          { book: "Matthew", chapter: 21, verse: 9, text: "And the multitudes that went before, and that followed, cried, saying, Hosanna to the Son of David: Blessed is he that cometh in the name of the Lord; Hosanna in the highest.", testament: "new" },
          { book: "Zechariah", chapter: 9, verse: 9, text: "Rejoice greatly, O daughter of Zion; shout, O daughter of Jerusalem: behold, thy King cometh unto thee: he is just, and having salvation; lowly, and riding upon an ass, and upon a colt the foal of an ass.", testament: "old" },
          { book: "John", chapter: 12, verse: 13, text: "Took branches of palm trees, and went forth to meet him, and cried, Hosanna: Blessed is the King of Israel that cometh in the name of the Lord.", testament: "new" },
          { book: "Psalms", chapter: 118, verse: 26, text: "Blessed be he that cometh in the name of the LORD: we have blessed you out of the house of the LORD.", testament: "old" },
          { book: "Mark", chapter: 11, verse: 9, text: "And they that went before, and they that followed, cried, saying, Hosanna; Blessed is he that cometh in the name of the Lord.", testament: "new" },
          { book: "Luke", chapter: 19, verse: 40, text: "And he answered and said unto them, I tell you that, if these should hold their peace, the stones would immediately cry out.", testament: "new" },
          { book: "Philippians", chapter: 2, verse: 8, text: "And being found in fashion as a man, he humbled himself, and became obedient unto death, even the death of the cross.", testament: "new" },
        ],
      },
    },
    {
      offset: -6,
      holiday: {
        name: "Holy Monday",
        themeHint:
          "Today is Holy Monday, when Jesus cleansed the Temple and declared it a house of prayer. The devotional should reflect themes of righteous zeal, purifying our worship, and the authority of Christ over what has become corrupt.",
        verses: [
          { book: "Mark", chapter: 11, verse: 15, text: "And they come to Jerusalem: and Jesus went into the temple, and began to cast out them that sold and bought in the temple, and overthrew the tables of the moneychangers, and the seats of them that sold doves.", testament: "new" },
          { book: "John", chapter: 2, verse: 16, text: "And said unto them that sold doves, Take these things hence; make not my Father's house an house of merchandise.", testament: "new" },
          { book: "Isaiah", chapter: 56, verse: 7, text: "Even them will I bring to my holy mountain, and make them joyful in my house of prayer: their house shall be called an house of prayer for all people.", testament: "old" },
          { book: "Malachi", chapter: 3, verse: 2, text: "But who may abide the day of his coming? and who shall stand when he appeareth? for he is like a refiner's fire, and like fullers' soap.", testament: "old" },
          { book: "Psalms", chapter: 69, verse: 9, text: "For the zeal of thine house hath eaten me up; and the reproaches of them that reproached thee are fallen upon me.", testament: "old" },
          { book: "Jeremiah", chapter: 7, verse: 11, text: "Is this house, which is called by my name, become a den of robbers in your eyes? Behold, even I have seen it, saith the LORD.", testament: "old" },
          { book: "Matthew", chapter: 21, verse: 13, text: "And said unto them, It is written, My house shall be called the house of prayer; but ye have made it a den of thieves.", testament: "new" },
        ],
      },
    },
    {
      offset: -4,
      holiday: {
        name: "Spy Wednesday",
        themeHint:
          "Today is Spy Wednesday, also called Holy Wednesday, recalling Judas Iscariot's agreement to betray Jesus for thirty pieces of silver. The devotional should reflect themes of betrayal and loyalty, the cost of discipleship, and examining our own faithfulness.",
        verses: [
          { book: "Matthew", chapter: 26, verse: 15, text: "And said unto them, What will ye give me, and I will deliver him unto you? And they covenanted with him for thirty pieces of silver.", testament: "new" },
          { book: "Psalms", chapter: 41, verse: 9, text: "Yea, mine own familiar friend, in whom I trusted, which did eat of my bread, hath lifted up his heel against me.", testament: "old" },
          { book: "Zechariah", chapter: 11, verse: 12, text: "And I said unto them, If ye think good, give me my price; and if not, forbear. So they weighed for my price thirty pieces of silver.", testament: "old" },
          { book: "Luke", chapter: 22, verse: 3, text: "Then entered Satan into Judas surnamed Iscariot, being of the number of the twelve.", testament: "new" },
          { book: "Proverbs", chapter: 27, verse: 6, text: "Faithful are the wounds of a friend; but the kisses of an enemy are deceitful.", testament: "old" },
          { book: "John", chapter: 13, verse: 27, text: "And after the sop Satan entered into him. Then said Jesus unto him, That thou doest, do quickly.", testament: "new" },
        ],
      },
    },
    {
      offset: -3,
      holiday: {
        name: "Maundy Thursday",
        themeHint:
          "Today is Maundy Thursday, commemorating the Last Supper where Jesus washed His disciples' feet and instituted the Lord's Supper. The devotional should reflect themes of humble service, communion, and Jesus's new commandment to love one another.",
        verses: [
          { book: "John", chapter: 13, verse: 34, text: "A new commandment I give unto you, That ye love one another; as I have loved you, that ye also love one another.", testament: "new" },
          { book: "Luke", chapter: 22, verse: 19, text: "And he took bread, and gave thanks, and brake it, and gave unto them, saying, This is my body which is given for you: this do in remembrance of me.", testament: "new" },
          { book: "John", chapter: 13, verse: 14, text: "If I then, your Lord and Master, have washed your feet; ye also ought to wash one another's feet.", testament: "new" },
          { book: "1 Corinthians", chapter: 11, verse: 26, text: "For as often as ye eat this bread, and drink this cup, ye do shew the Lord's death till he come.", testament: "new" },
          { book: "Mark", chapter: 14, verse: 22, text: "And as they did eat, Jesus took bread, and blessed, and brake it, and gave to them, and said, Take, eat: this is my body.", testament: "new" },
          { book: "Exodus", chapter: 12, verse: 14, text: "And this day shall be unto you for a memorial; and ye shall keep it a feast to the LORD throughout your generations; ye shall keep it a feast by an ordinance for ever.", testament: "old" },
          { book: "Matthew", chapter: 26, verse: 39, text: "And he went a little further, and fell on his face, and prayed, saying, O my Father, if it be possible, let this cup pass from me: nevertheless not as I will, but as thou wilt.", testament: "new" },
        ],
      },
    },
    {
      offset: -2,
      holiday: {
        name: "Good Friday",
        themeHint:
          "Today is Good Friday, commemorating the crucifixion of Jesus Christ. The devotional should reflect themes of sacrifice, redemption, atonement, and the depth of God's love.",
        verses: [
          { book: "John", chapter: 19, verse: 30, text: "When Jesus therefore had received the vinegar, he said, It is finished: and he bowed his head, and gave up the ghost.", testament: "new" },
          { book: "Isaiah", chapter: 53, verse: 5, text: "But he was wounded for our transgressions, he was bruised for our iniquities: the chastisement of our peace was upon him; and with his stripes we are healed.", testament: "old" },
          { book: "Romans", chapter: 5, verse: 8, text: "But God commendeth his love toward us, in that, while we were yet sinners, Christ died for us.", testament: "new" },
          { book: "Psalms", chapter: 22, verse: 1, text: "My God, my God, why hast thou forsaken me? why art thou so far from helping me, and from the words of my roaring?", testament: "old" },
          { book: "Luke", chapter: 23, verse: 34, text: "Then said Jesus, Father, forgive them; for they know not what they do. And they parted his raiment, and cast lots.", testament: "new" },
          { book: "Galatians", chapter: 2, verse: 20, text: "I am crucified with Christ: nevertheless I live; yet not I, but Christ liveth in me: and the life which I now live in the flesh I live by the faith of the Son of God, who loved me, and gave himself for me.", testament: "new" },
          { book: "1 Peter", chapter: 2, verse: 24, text: "Who his own self bare our sins in his own body on the tree, that we, being dead to sins, should live unto righteousness: by whose stripes ye were healed.", testament: "new" },
          { book: "Hebrews", chapter: 12, verse: 2, text: "Looking unto Jesus the author and finisher of our faith; who for the joy that was set before him endured the cross, despising the shame, and is set down at the right hand of the throne of God.", testament: "new" },
        ],
      },
    },
    {
      offset: -1,
      holiday: {
        name: "Holy Saturday",
        themeHint:
          "Today is Holy Saturday, the day of waiting between crucifixion and resurrection. The devotional should reflect themes of patient waiting, hope in darkness, trust in God's promises, and the silence before the dawn of Easter.",
        verses: [
          { book: "Psalms", chapter: 130, verse: 5, text: "I wait for the LORD, my soul doth wait, and in his word do I hope.", testament: "old" },
          { book: "Lamentations", chapter: 3, verse: 25, text: "The LORD is good unto them that wait for him, to the soul that seeketh him.", testament: "old" },
          { book: "Romans", chapter: 8, verse: 25, text: "But if we hope for that we see not, then do we with patience wait for it.", testament: "new" },
          { book: "Psalms", chapter: 16, verse: 10, text: "For thou wilt not leave my soul in hell; neither wilt thou suffer thine Holy One to see corruption.", testament: "old" },
          { book: "Job", chapter: 19, verse: 25, text: "For I know that my redeemer liveth, and that he shall stand at the latter day upon the earth.", testament: "old" },
          { book: "Habakkuk", chapter: 2, verse: 3, text: "For the vision is yet for an appointed time, but at the end it shall speak, and not lie: though it tarry, wait for it; because it will surely come, it will not tarry.", testament: "old" },
          { book: "Isaiah", chapter: 25, verse: 9, text: "And it shall be said in that day, Lo, this is our God; we have waited for him, and he will save us: this is the LORD; we have waited for him, we will be glad and rejoice in his salvation.", testament: "old" },
        ],
      },
    },
    {
      offset: 0,
      holiday: {
        name: "Easter Sunday",
        themeHint:
          "Today is Easter Sunday, celebrating the resurrection of Jesus Christ! This is the most important day in the Christian calendar. The devotional should overflow with joy, hope, victory over death, and the promise of eternal life.",
        verses: [
          { book: "Matthew", chapter: 28, verse: 6, text: "He is not here: for he is risen, as he said. Come, see the place where the Lord lay.", testament: "new" },
          { book: "John", chapter: 11, verse: 25, text: "Jesus said unto her, I am the resurrection, and the life: he that believeth in me, though he were dead, yet shall he live.", testament: "new" },
          { book: "1 Corinthians", chapter: 15, verse: 55, text: "O death, where is thy sting? O grave, where is thy victory?", testament: "new" },
          { book: "Romans", chapter: 6, verse: 9, text: "Knowing that Christ being raised from the dead dieth no more; death hath no more dominion over him.", testament: "new" },
          { book: "Colossians", chapter: 3, verse: 1, text: "If ye then be risen with Christ, seek those things which are above, where Christ sitteth on the right hand of God.", testament: "new" },
          { book: "Luke", chapter: 24, verse: 6, text: "He is not here, but is risen: remember how he spake unto you when he was yet in Galilee.", testament: "new" },
          { book: "Psalms", chapter: 118, verse: 24, text: "This is the day which the LORD hath made; we will rejoice and be glad in it.", testament: "old" },
          { book: "1 Peter", chapter: 1, verse: 3, text: "Blessed be the God and Father of our Lord Jesus Christ, which according to his abundant mercy hath begotten us again unto a lively hope by the resurrection of Jesus Christ from the dead.", testament: "new" },
        ],
      },
    },
    {
      offset: 39,
      holiday: {
        name: "Ascension Day",
        themeHint:
          "Today is Ascension Day, commemorating Jesus's ascension into heaven forty days after the resurrection. The devotional should reflect themes of Christ's exaltation, the promise of His return, and the commission given to believers.",
        verses: [
          { book: "Acts", chapter: 1, verse: 9, text: "And when he had spoken these things, while they beheld, he was taken up; and a cloud received him out of their sight.", testament: "new" },
          { book: "Ephesians", chapter: 4, verse: 8, text: "Wherefore he saith, When he ascended up on high, he led captivity captive, and gave gifts unto men.", testament: "new" },
          { book: "Mark", chapter: 16, verse: 19, text: "So then after the Lord had spoken unto them, he was received up into heaven, and sat on the right hand of God.", testament: "new" },
        ],
      },
    },
    {
      offset: 49,
      holiday: {
        name: "Pentecost",
        themeHint:
          "Today is Pentecost, celebrating the descent of the Holy Spirit upon the apostles. The devotional should reflect themes of spiritual empowerment, the birth of the Church, and the transforming power of the Holy Spirit.",
        verses: [
          { book: "Acts", chapter: 2, verse: 4, text: "And they were all filled with the Holy Ghost, and began to speak with other tongues, as the Spirit gave them utterance.", testament: "new" },
          { book: "Joel", chapter: 2, verse: 28, text: "And it shall come to pass afterward, that I will pour out my spirit upon all flesh; and your sons and your daughters shall prophesy, your old men shall dream dreams, your young men shall see visions.", testament: "old" },
          { book: "John", chapter: 14, verse: 26, text: "But the Comforter, which is the Holy Ghost, whom the Father will send in my name, he shall teach you all things, and bring all things to your remembrance, whatsoever I have said unto you.", testament: "new" },
        ],
      },
    },
    {
      offset: 56,
      holiday: {
        name: "Trinity Sunday",
        themeHint:
          "Today is Trinity Sunday, celebrating the mystery of the Holy Trinity — Father, Son, and Holy Spirit. The devotional should reflect themes of the triune nature of God, divine unity, and the distinct yet unified persons of the Godhead.",
        verses: [
          { book: "Matthew", chapter: 28, verse: 19, text: "Go ye therefore, and teach all nations, baptizing them in the name of the Father, and of the Son, and of the Holy Ghost.", testament: "new" },
          { book: "2 Corinthians", chapter: 13, verse: 14, text: "The grace of the Lord Jesus Christ, and the love of God, and the communion of the Holy Ghost, be with you all. Amen.", testament: "new" },
          { book: "Isaiah", chapter: 6, verse: 3, text: "And one cried unto another, and said, Holy, holy, holy, is the LORD of hosts: the whole earth is full of his glory.", testament: "old" },
        ],
      },
    },
  ];

  for (const { offset, holiday } of easterHolidays) {
    if (sameDay(addDays(easter, offset), date)) return holiday;
  }

  // ── Fixed-date holidays ──
  const fixedHolidays: Record<string, Holiday> = {
    "0-1": {
      name: "New Year's Day",
      themeHint:
        "Today is New Year's Day — a time of new beginnings and renewed hope. The devotional should reflect themes of renewal, God's faithfulness, and looking forward with trust.",
      verses: [
        { book: "Isaiah", chapter: 43, verse: 19, text: "Behold, I will do a new thing; now it shall spring forth; shall ye not know it? I will even make a way in the wilderness, and rivers in the desert.", testament: "old" },
        { book: "Lamentations", chapter: 3, verse: 22, text: "It is of the LORD's mercies that we are not consumed, because his compassions fail not.", testament: "old" },
        { book: "2 Corinthians", chapter: 5, verse: 17, text: "Therefore if any man be in Christ, he is a new creature: old things are passed away; behold, all things are become new.", testament: "new" },
      ],
    },
    "0-6": {
      name: "Epiphany",
      themeHint:
        "Today is Epiphany, celebrating the revelation of Christ to the Gentiles as represented by the Magi. The devotional should reflect themes of seeking, revelation, and the universal nature of God's love.",
      verses: [
        { book: "Matthew", chapter: 2, verse: 11, text: "And when they were come into the house, they saw the young child with Mary his mother, and fell down, and worshipped him: and when they had opened their treasures, they presented unto him gifts; gold, and frankincense, and myrrh.", testament: "new" },
        { book: "Isaiah", chapter: 60, verse: 3, text: "And the Gentiles shall come to thy light, and kings to the brightness of thy rising.", testament: "old" },
      ],
    },
    "1-14": {
      name: "Valentine's Day",
      themeHint:
        "Today is Valentine's Day — a celebration of love. The devotional should reflect on the nature of divine love, love for one another, and the greatest commandment of love.",
      verses: [
        { book: "1 Corinthians", chapter: 13, verse: 4, text: "Charity suffereth long, and is kind; charity envieth not; charity vaunteth not itself, is not puffed up.", testament: "new" },
        { book: "1 John", chapter: 4, verse: 19, text: "We love him, because he first loved us.", testament: "new" },
        { book: "Song of Solomon", chapter: 8, verse: 7, text: "Many waters cannot quench love, neither can the floods drown it: if a man would give all the substance of his house for love, it would utterly be contemned.", testament: "old" },
      ],
    },
    "11-24": {
      name: "Christmas Eve",
      themeHint:
        "Today is Christmas Eve — a night of sacred anticipation as we await the celebration of Christ's birth. The devotional should reflect themes of waiting, expectation, the promise of Emmanuel, and the quiet wonder of God entering the world.",
      verses: [
        { book: "Isaiah", chapter: 7, verse: 14, text: "Therefore the Lord himself shall give you a sign; Behold, a virgin shall conceive, and bear a son, and shall call his name Immanuel.", testament: "old" },
        { book: "Luke", chapter: 2, verse: 10, text: "And the angel said unto them, Fear not: for, behold, I bring you good tidings of great joy, which shall be to all people.", testament: "new" },
      ],
    },
    "11-25": {
      name: "Christmas Day",
      themeHint:
        "Today is Christmas Day — celebrating the birth of Jesus Christ, the incarnation of God in human form! The devotional should overflow with wonder, gratitude, and the mystery of God becoming man to dwell among us.",
      verses: [
        { book: "Luke", chapter: 2, verse: 11, text: "For unto you is born this day in the city of David a Saviour, which is Christ the Lord.", testament: "new" },
        { book: "Isaiah", chapter: 9, verse: 6, text: "For unto us a child is born, unto us a son is given: and the government shall be upon his shoulder: and his name shall be called Wonderful, Counsellor, The mighty God, The everlasting Father, The Prince of Peace.", testament: "old" },
        { book: "John", chapter: 1, verse: 14, text: "And the Word was made flesh, and dwelt among us, (and we beheld his glory, the glory as of the only begotten of the Father,) full of grace and truth.", testament: "new" },
        { book: "Matthew", chapter: 1, verse: 23, text: "Behold, a virgin shall be with child, and shall bring forth a son, and they shall call his name Emmanuel, which being interpreted is, God with us.", testament: "new" },
      ],
    },
    "11-31": {
      name: "New Year's Eve",
      themeHint:
        "Today is New Year's Eve — a time of reflection on the year past and anticipation of the year ahead. The devotional should reflect themes of gratitude, God's faithfulness, and trusting Him for what lies ahead.",
      verses: [
        { book: "Psalms", chapter: 90, verse: 12, text: "So teach us to number our days, that we may apply our hearts unto wisdom.", testament: "old" },
        { book: "Philippians", chapter: 3, verse: 13, text: "Brethren, I count not myself to have apprehended: but this one thing I do, forgetting those things which are behind, and reaching forth unto those things which are before.", testament: "new" },
        { book: "Deuteronomy", chapter: 31, verse: 8, text: "And the LORD, he it is that doth go before thee; he will be with thee, he will not fail thee, neither forsake thee: fear not, neither be dismayed.", testament: "old" },
      ],
    },
    "5-19": {
      name: "Juneteenth",
      themeHint:
        "Today is Juneteenth, celebrating the emancipation of enslaved people in the United States. The devotional should reflect themes of freedom, liberation, justice, God's heart for the oppressed, and the spiritual truth that all people are created equal in God's image.",
      verses: [
        { book: "Isaiah", chapter: 61, verse: 1, text: "The Spirit of the Lord GOD is upon me; because the LORD hath anointed me to preach good tidings unto the meek; he hath sent me to bind up the brokenhearted, to proclaim liberty to the captives, and the opening of the prison to them that are bound.", testament: "old" },
        { book: "Galatians", chapter: 5, verse: 13, text: "For, brethren, ye have been called unto liberty; only use not liberty for an occasion to the flesh, but by love serve one another.", testament: "new" },
        { book: "Psalms", chapter: 146, verse: 7, text: "Which executeth judgment for the oppressed: which giveth food to the hungry. The LORD looseth the prisoners.", testament: "old" },
      ],
    },
    "6-4": {
      name: "Independence Day",
      themeHint:
        "Today is Independence Day in the United States — a celebration of freedom and liberty. The devotional should reflect themes of spiritual freedom, liberty in Christ, gratitude for blessings, and the responsibility that comes with freedom.",
      verses: [
        { book: "Galatians", chapter: 5, verse: 1, text: "Stand fast therefore in the liberty wherewith Christ hath made us free, and be not entangled again with the yoke of bondage.", testament: "new" },
        { book: "2 Corinthians", chapter: 3, verse: 17, text: "Now the Lord is that Spirit: and where the Spirit of the Lord is, there is liberty.", testament: "new" },
        { book: "Psalms", chapter: 33, verse: 12, text: "Blessed is the nation whose God is the LORD; and the people whom he hath chosen for his own inheritance.", testament: "old" },
      ],
    },
    "7-6": {
      name: "Transfiguration",
      themeHint:
        "Today is the Feast of the Transfiguration, when Jesus was transfigured on the mountain and His divine glory was revealed to Peter, James, and John. The devotional should reflect themes of divine revelation, glory, transformation, and hearing God's voice.",
      verses: [
        { book: "Matthew", chapter: 17, verse: 2, text: "And was transfigured before them: and his face did shine as the sun, and his raiment was white as the light.", testament: "new" },
        { book: "2 Peter", chapter: 1, verse: 17, text: "For he received from God the Father honour and glory, when there came such a voice to him from the excellent glory, This is my beloved Son, in whom I am well pleased.", testament: "new" },
        { book: "Mark", chapter: 9, verse: 7, text: "And there was a cloud that overshadowed them: and a voice came out of the cloud, saying, This is my beloved Son: hear him.", testament: "new" },
      ],
    },
    "9-31": {
      name: "Reformation Day",
      themeHint:
        "Today is Reformation Day, commemorating Martin Luther's posting of the 95 Theses in 1517 and the birth of the Protestant Reformation. The devotional should reflect themes of faith alone, grace alone, Scripture alone, and the transforming power of God's Word.",
      verses: [
        { book: "Romans", chapter: 1, verse: 17, text: "For therein is the righteousness of God revealed from faith to faith: as it is written, The just shall live by faith.", testament: "new" },
        { book: "Ephesians", chapter: 2, verse: 8, text: "For by grace are ye saved through faith; and that not of yourselves: it is the gift of God.", testament: "new" },
        { book: "Hebrews", chapter: 4, verse: 12, text: "For the word of God is quick, and powerful, and sharper than any twoedged sword, piercing even to the dividing asunder of soul and spirit, and of the joints and marrow, and is a discerner of the thoughts and intents of the heart.", testament: "new" },
      ],
    },
    "10-1": {
      name: "All Saints' Day",
      themeHint:
        "Today is All Saints' Day, honoring all the saints and faithful who have gone before us. The devotional should reflect themes of the communion of saints, faithfulness, the cloud of witnesses, and the hope of eternal life.",
      verses: [
        { book: "Hebrews", chapter: 12, verse: 1, text: "Wherefore seeing we also are compassed about with so great a cloud of witnesses, let us lay aside every weight, and the sin which doth so easily beset us, and let us run with patience the race that is set before us.", testament: "new" },
        { book: "Revelation", chapter: 7, verse: 9, text: "After this I beheld, and, lo, a great multitude, which no man could number, of all nations, and kindreds, and people, and tongues, stood before the throne, and before the Lamb, clothed with white robes, and palms in their hands.", testament: "new" },
        { book: "Matthew", chapter: 5, verse: 8, text: "Blessed are the pure in heart: for they shall see God.", testament: "new" },
      ],
    },
    "10-11": {
      name: "Veterans Day",
      themeHint:
        "Today is Veterans Day, honoring those who have served in the armed forces. The devotional should reflect themes of courage, sacrifice, service to others, and the spiritual call to be strong and courageous.",
      verses: [
        { book: "Joshua", chapter: 1, verse: 9, text: "Have not I commanded thee? Be strong and of a good courage; be not afraid, neither be thou dismayed: for the LORD thy God is with thee whithersoever thou goest.", testament: "old" },
        { book: "Isaiah", chapter: 6, verse: 8, text: "Also I heard the voice of the Lord, saying, Whom shall I send, and who will go for us? Then said I, Here am I; send me.", testament: "old" },
        { book: "Romans", chapter: 13, verse: 7, text: "Render therefore to all their dues: tribute to whom tribute is due; custom to whom custom; fear to whom fear; honour to whom honour.", testament: "new" },
      ],
    },
    "0-5": {
      name: "Epiphany Eve",
      themeHint:
        "Today is Epiphany Eve, also known as Twelfth Night — the close of the Christmas season and the eve of the Magi's arrival. The devotional should reflect themes of seeking Christ, the journey of faith, and the light that guides us through darkness.",
      verses: [
        { book: "Matthew", chapter: 2, verse: 1, text: "Now when Jesus was born in Bethlehem of Judaea in the days of Herod the king, behold, there came wise men from the east to Jerusalem.", testament: "new" },
        { book: "Psalms", chapter: 72, verse: 10, text: "The kings of Tarshish and of the isles shall bring presents: the kings of Sheba and Seba shall offer gifts.", testament: "old" },
        { book: "Isaiah", chapter: 60, verse: 1, text: "Arise, shine; for thy light is come, and the glory of the LORD is risen upon thee.", testament: "old" },
      ],
    },
    "2-17": {
      name: "St. Patrick's Day",
      themeHint:
        "Today is St. Patrick's Day, honoring the missionary who brought Christianity to Ireland. The devotional should reflect themes of missionary calling, boldly sharing faith, God's power to transform nations, and the courage to go where He sends.",
      verses: [
        { book: "Romans", chapter: 10, verse: 15, text: "And how shall they preach, except they be sent? as it is written, How beautiful are the feet of them that preach the gospel of peace, and bring glad tidings of good things!", testament: "new" },
        { book: "Acts", chapter: 1, verse: 8, text: "But ye shall receive power, after that the Holy Ghost is come upon you: and ye shall be witnesses unto me both in Jerusalem, and in all Judaea, and in Samaria, and unto the uttermost part of the earth.", testament: "new" },
        { book: "1 Peter", chapter: 3, verse: 15, text: "But sanctify the Lord God in your hearts: and be ready always to give an answer to every man that asketh you a reason of the hope that is in you with meekness and fear.", testament: "new" },
      ],
    },
    "2-20": {
      name: "Spring Equinox",
      themeHint:
        "Today marks the Spring Equinox, when day and night are equal — the earth awakens to new life. The devotional should reflect themes of renewal, resurrection, the faithfulness of God's seasons, and new beginnings in creation.",
      verses: [
        { book: "Song of Solomon", chapter: 2, verse: 11, text: "For, lo, the winter is past, the rain is over and gone.", testament: "old" },
        { book: "Genesis", chapter: 8, verse: 22, text: "While the earth remaineth, seedtime and harvest, and cold and heat, and summer and winter, and day and night shall not cease.", testament: "old" },
        { book: "2 Corinthians", chapter: 5, verse: 17, text: "Therefore if any man be in Christ, he is a new creature: old things are passed away; behold, all things are become new.", testament: "new" },
      ],
    },
    "3-22": {
      name: "Earth Day",
      themeHint:
        "Today is Earth Day — a day to honor God's creation and our responsibility as stewards of the world He made. The devotional should reflect themes of creation's beauty, environmental stewardship, and recognizing God's handiwork in nature.",
      verses: [
        { book: "Genesis", chapter: 1, verse: 31, text: "And God saw every thing that he had made, and, behold, it was very good.", testament: "old" },
        { book: "Psalms", chapter: 24, verse: 1, text: "The earth is the LORD's, and the fulness thereof; the world, and they that dwell therein.", testament: "old" },
        { book: "Romans", chapter: 1, verse: 20, text: "For the invisible things of him from the creation of the world are clearly seen, being understood by the things that are made, even his eternal power and Godhead; so that they are without excuse.", testament: "new" },
      ],
    },
    "5-14": {
      name: "Flag Day",
      themeHint:
        "Today is Flag Day in the United States. The devotional should reflect themes of allegiance, loyalty, standing for truth, and the banners God sets before His people.",
      verses: [
        { book: "Psalms", chapter: 20, verse: 5, text: "We will rejoice in thy salvation, and in the name of our God we will set up our banners: the LORD fulfil all thy petitions.", testament: "old" },
        { book: "Isaiah", chapter: 11, verse: 10, text: "And in that day there shall be a root of Jesse, which shall stand for an ensign of the people; to it shall the Gentiles seek: and his rest shall be glorious.", testament: "old" },
        { book: "Psalms", chapter: 60, verse: 4, text: "Thou hast given a banner to them that fear thee, that it may be displayed because of the truth.", testament: "old" },
      ],
    },
    "5-21": {
      name: "Summer Solstice",
      themeHint:
        "Today is the Summer Solstice, the longest day of the year — when the sun reaches its zenith. The devotional should reflect themes of God as the source of all light, walking in the light, and the abundance of His provision in seasons of fullness.",
      verses: [
        { book: "Psalms", chapter: 19, verse: 4, text: "Their line is gone out through all the earth, and their words to the end of the world. In them hath he set a tabernacle for the sun.", testament: "old" },
        { book: "1 John", chapter: 1, verse: 5, text: "This then is the message which we have heard of him, and declare unto you, that God is light, and in him is no darkness at all.", testament: "new" },
        { book: "Malachi", chapter: 4, verse: 2, text: "But unto you that fear my name shall the Sun of righteousness arise with healing in his wings; and ye shall go forth, and grow up as calves of the stall.", testament: "old" },
      ],
    },
    "8-11": {
      name: "Patriot Day",
      themeHint:
        "Today is Patriot Day, a day of remembrance for the lives lost on September 11, 2001. The devotional should reflect themes of comfort in tragedy, God's nearness in suffering, healing for the brokenhearted, and hope that overcomes fear.",
      verses: [
        { book: "Psalms", chapter: 46, verse: 1, text: "God is our refuge and strength, a very present help in trouble.", testament: "old" },
        { book: "Isaiah", chapter: 41, verse: 10, text: "Fear thou not; for I am with thee: be not dismayed; for I am thy God: I will strengthen thee; yea, I will help thee; yea, I will uphold thee with the right hand of my righteousness.", testament: "old" },
        { book: "Psalms", chapter: 147, verse: 3, text: "He healeth the broken in heart, and bindeth up their wounds.", testament: "old" },
      ],
    },
    "8-21": {
      name: "International Day of Peace",
      themeHint:
        "Today is the International Day of Peace — a day devoted to strengthening the ideals of peace among all peoples. The devotional should reflect themes of peacemaking, reconciliation, the peace that God gives, and our calling to be instruments of His peace.",
      verses: [
        { book: "Isaiah", chapter: 2, verse: 4, text: "And he shall judge among the nations, and shall rebuke many people: and they shall beat their swords into plowshares, and their spears into pruninghooks: nation shall not lift up sword against nation, neither shall they learn war any more.", testament: "old" },
        { book: "Matthew", chapter: 5, verse: 9, text: "Blessed are the peacemakers: for they shall be called the children of God.", testament: "new" },
        { book: "Romans", chapter: 12, verse: 18, text: "If it be possible, as much as lieth in you, live peaceably with all men.", testament: "new" },
      ],
    },
    "8-22": {
      name: "Autumn Equinox",
      themeHint:
        "Today marks the Autumn Equinox, when day and night are again equal — a pivot toward the quieter, reflective months. The devotional should reflect themes of harvest, gratitude for God's provision, the rhythm of seasons, and preparing for seasons of rest.",
      verses: [
        { book: "Ecclesiastes", chapter: 3, verse: 1, text: "To every thing there is a season, and a time to every purpose under the heaven.", testament: "old" },
        { book: "Psalms", chapter: 67, verse: 6, text: "Then shall the earth yield her increase; and God, even our own God, shall bless us.", testament: "old" },
        { book: "Galatians", chapter: 6, verse: 9, text: "And let us not be weary in well doing: for in due season we shall reap, if we faint not.", testament: "new" },
      ],
    },
    "8-29": {
      name: "Michaelmas",
      themeHint:
        "Today is Michaelmas, the Feast of the Archangels — celebrating Michael, Gabriel, and Raphael. The devotional should reflect themes of spiritual warfare, angelic protection, God's heavenly armies, and the unseen battle between good and evil.",
      verses: [
        { book: "Revelation", chapter: 12, verse: 7, text: "And there was war in heaven: Michael and his angels fought against the dragon; and the dragon fought and his angels.", testament: "new" },
        { book: "Daniel", chapter: 10, verse: 13, text: "But the prince of the kingdom of Persia withstood me one and twenty days: but, lo, Michael, one of the chief princes, came to help me; and I remained there with the kings of Persia.", testament: "old" },
        { book: "Psalms", chapter: 91, verse: 11, text: "For he shall give his angels charge over thee, to keep thee in all thy ways.", testament: "old" },
      ],
    },
    "11-21": {
      name: "Winter Solstice",
      themeHint:
        "Today is the Winter Solstice, the longest night and shortest day — when darkness reaches its peak before the light begins to return. The devotional should reflect themes of light overcoming darkness, hope in the bleakest hour, and the anticipation of Christ as the Light of the World during Advent.",
      verses: [
        { book: "John", chapter: 1, verse: 5, text: "And the light shineth in darkness; and the darkness comprehended it not.", testament: "new" },
        { book: "Isaiah", chapter: 9, verse: 2, text: "The people that walked in darkness have seen a great light: they that dwell in the land of the shadow of death, upon them hath the light shined.", testament: "old" },
        { book: "Psalms", chapter: 139, verse: 12, text: "Yea, the darkness hideth not from thee; but the night shineth as the day: the darkness and the light are both alike to thee.", testament: "old" },
      ],
    },
  };

  const fixedKey = `${month}-${day}`;
  if (fixedHolidays[fixedKey]) return fixedHolidays[fixedKey];

  // ── Moveable non-Easter holidays ──

  // Mother's Day: 2nd Sunday in May
  if (month === 4 && date.getDay() === 0 && sameDay(date, getNthWeekday(year, 4, 0, 2))) {
    return {
      name: "Mother's Day",
      themeHint:
        "Today is Mother's Day — a day to honor mothers and the nurturing love that reflects God's own tender care. The devotional should reflect themes of maternal love, honor, and gratitude.",
      verses: [
        { book: "Proverbs", chapter: 31, verse: 28, text: "Her children arise up, and call her blessed; her husband also, and he praiseth her.", testament: "old" },
        { book: "Isaiah", chapter: 66, verse: 13, text: "As one whom his mother comforteth, so will I comfort you; and ye shall be comforted in Jerusalem.", testament: "old" },
        { book: "Proverbs", chapter: 31, verse: 26, text: "She openeth her mouth with wisdom; and in her tongue is the law of kindness.", testament: "old" },
      ],
    };
  }

  // Father's Day: 3rd Sunday in June
  if (month === 5 && date.getDay() === 0 && sameDay(date, getNthWeekday(year, 5, 0, 3))) {
    return {
      name: "Father's Day",
      themeHint:
        "Today is Father's Day — a day to honor fathers and the guiding love that reflects our Heavenly Father's care. The devotional should reflect themes of paternal guidance, protection, and God as our Father.",
      verses: [
        { book: "Proverbs", chapter: 22, verse: 6, text: "Train up a child in the way he should go: and when he is old, he will not depart from it.", testament: "old" },
        { book: "Psalms", chapter: 103, verse: 13, text: "Like as a father pitieth his children, so the LORD pitieth them that fear him.", testament: "old" },
        { book: "Ephesians", chapter: 6, verse: 4, text: "And, ye fathers, provoke not your children to wrath: but bring them up in the nurture and admonition of the Lord.", testament: "new" },
      ],
    };
  }

  // Thanksgiving: 4th Thursday in November
  if (month === 10 && date.getDay() === 4 && sameDay(date, getNthWeekday(year, 10, 4, 4))) {
    return {
      name: "Thanksgiving",
      themeHint:
        "Today is Thanksgiving — a day of gratitude and reflection on God's abundant provision. The devotional should reflect themes of thankfulness, God's generosity, and giving thanks in all circumstances.",
      verses: [
        { book: "Psalms", chapter: 100, verse: 4, text: "Enter into his gates with thanksgiving, and into his courts with praise: be thankful unto him, and bless his name.", testament: "old" },
        { book: "1 Thessalonians", chapter: 5, verse: 18, text: "In every thing give thanks: for this is the will of God in Christ Jesus concerning you.", testament: "new" },
        { book: "Colossians", chapter: 3, verse: 15, text: "And let the peace of God rule in your hearts, to the which also ye are called in one body; and be ye thankful.", testament: "new" },
      ],
    };
  }

  // Martin Luther King Jr. Day: 3rd Monday in January
  if (month === 0 && date.getDay() === 1 && sameDay(date, getNthWeekday(year, 0, 1, 3))) {
    return {
      name: "Martin Luther King Jr. Day",
      themeHint:
        "Today is Martin Luther King Jr. Day, honoring the legacy of Dr. King and his dream of justice, equality, and peace. The devotional should reflect themes of justice, righteousness, love for neighbor, and the biblical call to care for the oppressed.",
      verses: [
        { book: "Micah", chapter: 6, verse: 8, text: "He hath shewed thee, O man, what is good; and what doth the LORD require of thee, but to do justly, and to love mercy, and to walk humbly with thy God?", testament: "old" },
        { book: "Amos", chapter: 5, verse: 24, text: "But let judgment run down as waters, and righteousness as a mighty stream.", testament: "old" },
        { book: "Galatians", chapter: 3, verse: 28, text: "There is neither Jew nor Greek, there is neither bond nor free, there is neither male nor female: for ye are all one in Christ Jesus.", testament: "new" },
      ],
    };
  }

  // Presidents' Day: 3rd Monday in February
  if (month === 1 && date.getDay() === 1 && sameDay(date, getNthWeekday(year, 1, 1, 3))) {
    return {
      name: "Presidents' Day",
      themeHint:
        "Today is Presidents' Day, honoring the leaders of the United States. The devotional should reflect themes of righteous leadership, wisdom in governance, praying for those in authority, and servant leadership.",
      verses: [
        { book: "Romans", chapter: 13, verse: 1, text: "Let every soul be subject unto the higher powers. For there is no power but of God: the powers that be are ordained of God.", testament: "new" },
        { book: "Proverbs", chapter: 29, verse: 2, text: "When the righteous are in authority, the people rejoice: but when the wicked beareth rule, the people mourn.", testament: "old" },
        { book: "1 Timothy", chapter: 2, verse: 2, text: "For kings, and for all that are in authority; that we may lead a quiet and peaceable life in all godliness and honesty.", testament: "new" },
      ],
    };
  }

  // Memorial Day: Last Monday in May
  if (month === 4 && date.getDay() === 1 && sameDay(date, getLastWeekday(year, 4, 1))) {
    return {
      name: "Memorial Day",
      themeHint:
        "Today is Memorial Day, honoring those who gave their lives in service to their country. The devotional should reflect themes of sacrifice, laying down one's life for others, remembrance, and the hope of resurrection.",
      verses: [
        { book: "John", chapter: 15, verse: 13, text: "Greater love hath no man than this, that a man lay down his life for his friends.", testament: "new" },
        { book: "Isaiah", chapter: 40, verse: 31, text: "But they that wait upon the LORD shall renew their strength; they shall mount up with wings as eagles; they shall run, and not be weary; and they shall walk, and not faint.", testament: "old" },
        { book: "Psalms", chapter: 34, verse: 18, text: "The LORD is nigh unto them that are of a broken heart; and saveth such as be of a contrite spirit.", testament: "old" },
      ],
    };
  }

  // Labor Day: 1st Monday in September
  if (month === 8 && date.getDay() === 1 && sameDay(date, getNthWeekday(year, 8, 1, 1))) {
    return {
      name: "Labor Day",
      themeHint:
        "Today is Labor Day, honoring the dignity of work and workers. The devotional should reflect themes of purposeful labor, rest, God's design for work, and the balance between toil and sabbath.",
      verses: [
        { book: "Colossians", chapter: 3, verse: 23, text: "And whatsoever ye do, do it heartily, as to the Lord, and not unto men.", testament: "new" },
        { book: "Genesis", chapter: 2, verse: 15, text: "And the LORD God took the man, and put him into the garden of Eden to dress it and to keep it.", testament: "old" },
        { book: "Ecclesiastes", chapter: 3, verse: 13, text: "And also that every man should eat and drink, and enjoy the good of all his labour, it is the gift of God.", testament: "old" },
      ],
    };
  }

  // Baptism of Jesus: First Sunday after Epiphany (Jan 6)
  if (month === 0 && date.getDay() === 0) {
    const jan6 = new Date(year, 0, 6);
    const daysUntilSunday = (7 - jan6.getDay()) % 7;
    const baptismSunday = daysUntilSunday === 0
      ? addDays(jan6, 7)
      : addDays(jan6, daysUntilSunday);
    if (sameDay(date, baptismSunday)) {
      return {
        name: "Baptism of Jesus",
        themeHint:
          "Today celebrates the Baptism of Jesus, when He was baptized by John in the Jordan River and the Holy Spirit descended like a dove. The devotional should reflect themes of identity in God, obedience, the beginning of ministry, and our own baptism into Christ.",
        verses: [
          { book: "Matthew", chapter: 3, verse: 16, text: "And Jesus, when he was baptized, went up straightway out of the water: and, lo, the heavens were opened unto him, and he saw the Spirit of God descending like a dove, and lighting upon him.", testament: "new" },
          { book: "Matthew", chapter: 3, verse: 17, text: "And lo a voice from heaven, saying, This is my beloved Son, in whom I am well pleased.", testament: "new" },
          { book: "Mark", chapter: 1, verse: 8, text: "I indeed have baptized you with water: but he shall baptize you with the Holy Ghost.", testament: "new" },
        ],
      };
    }
  }

  // World Day of Prayer: 1st Friday in March
  if (month === 2 && date.getDay() === 5 && sameDay(date, getNthWeekday(year, 2, 5, 1))) {
    return {
      name: "World Day of Prayer",
      themeHint:
        "Today is the World Day of Prayer, a global ecumenical movement uniting Christians in prayer across nations. The devotional should reflect themes of the power of prayer, unity in Christ, intercession for the world, and the privilege of coming before God together.",
      verses: [
        { book: "Philippians", chapter: 4, verse: 6, text: "Be careful for nothing; but in every thing by prayer and supplication with thanksgiving let your requests be made known unto God.", testament: "new" },
        { book: "1 Thessalonians", chapter: 5, verse: 17, text: "Pray without ceasing.", testament: "new" },
        { book: "Matthew", chapter: 18, verse: 20, text: "For where two or three are gathered together in my name, there am I in the midst of them.", testament: "new" },
      ],
    };
  }

  // National Day of Prayer: 1st Thursday in May
  if (month === 4 && date.getDay() === 4 && sameDay(date, getNthWeekday(year, 4, 4, 1))) {
    return {
      name: "National Day of Prayer",
      themeHint:
        "Today is the National Day of Prayer, calling Americans of all faiths to pray for the nation. The devotional should reflect themes of praying for our land, seeking God's face, national repentance and renewal, and God's faithfulness to those who call upon Him.",
      verses: [
        { book: "2 Chronicles", chapter: 7, verse: 14, text: "If my people, which are called by my name, shall humble themselves, and pray, and seek my face, and turn from their wicked ways; then will I hear from heaven, and will forgive their sin, and will heal their land.", testament: "old" },
        { book: "Jeremiah", chapter: 29, verse: 12, text: "Then shall ye call upon me, and ye shall go and pray unto me, and I will hearken unto you.", testament: "old" },
        { book: "1 Timothy", chapter: 2, verse: 1, text: "I exhort therefore, that, first of all, supplications, prayers, intercessions, and giving of thanks, be made for all men.", testament: "new" },
      ],
    };
  }

  // Election Day: 1st Tuesday after 1st Monday in November
  if (month === 10 && date.getDay() === 2) {
    const firstMonday = getNthWeekday(year, 10, 1, 1);
    const electionDay = addDays(firstMonday, 1);
    if (sameDay(date, electionDay)) {
      return {
        name: "Election Day",
        themeHint:
          "Today is Election Day in the United States. The devotional should reflect themes of civic responsibility, praying for wisdom in leadership, seeking righteousness in governance, and trusting God's sovereignty over the nations.",
        verses: [
          { book: "Proverbs", chapter: 14, verse: 34, text: "Righteousness exalteth a nation: but sin is a reproach to any people.", testament: "old" },
          { book: "Proverbs", chapter: 11, verse: 14, text: "Where no counsel is, the people fall: but in the multitude of counsellors there is safety.", testament: "old" },
          { book: "Isaiah", chapter: 1, verse: 17, text: "Learn to do well; seek judgment, relieve the oppressed, judge the fatherless, plead for the widow.", testament: "old" },
        ],
      };
    }
  }

  // Christ the King Sunday: Last Sunday before Advent 1
  if (date.getDay() === 0 && month >= 9) {
    const adventSundaysForKing = getAdventSundays(year);
    const christTheKing = addDays(adventSundaysForKing[0], -7);
    if (sameDay(date, christTheKing)) {
      return {
        name: "Christ the King Sunday",
        themeHint:
          "Today is Christ the King Sunday, the final Sunday of the liturgical year, celebrating the universal sovereignty of Jesus Christ over all creation. The devotional should reflect themes of Christ's eternal kingship, His dominion over all things, and our allegiance to Him above all earthly powers.",
        verses: [
          { book: "Revelation", chapter: 19, verse: 16, text: "And he hath on his vesture and on his thigh a name written, KING OF KINGS, AND LORD OF LORDS.", testament: "new" },
          { book: "Daniel", chapter: 7, verse: 14, text: "And there was given him dominion, and glory, and a kingdom, that all people, nations, and languages, should serve him: his dominion is an everlasting dominion, which shall not pass away, and his kingdom that which shall not be destroyed.", testament: "old" },
          { book: "Colossians", chapter: 1, verse: 15, text: "Who is the image of the invisible God, the firstborn of every creature.", testament: "new" },
        ],
      };
    }
  }

  // Advent Sundays (4 Sundays before Christmas)
  if (date.getDay() === 0) {
    const adventSundays = getAdventSundays(year);
    const adventData: Array<{ name: string; themeHint: string; verses: SelectedVerse[] }> = [
      {
        name: "First Sunday of Advent",
        themeHint:
          "Today is the First Sunday of Advent, marking the beginning of the Advent season — a time of hope and expectation as we prepare for the celebration of Christ's birth and anticipate His return.",
        verses: [
          { book: "Isaiah", chapter: 9, verse: 2, text: "The people that walked in darkness have seen a great light: they that dwell in the land of the shadow of death, upon them hath the light shined.", testament: "old" },
          { book: "Romans", chapter: 15, verse: 13, text: "Now the God of hope fill you with all joy and peace in believing, that ye may abound in hope, through the power of the Holy Ghost.", testament: "new" },
          { book: "Jeremiah", chapter: 33, verse: 14, text: "Behold, the days come, saith the LORD, that I will perform that good thing which I have promised unto the house of Israel and to the house of Judah.", testament: "old" },
        ],
      },
      {
        name: "Second Sunday of Advent",
        themeHint:
          "Today is the Second Sunday of Advent, a time of peace and preparation. As John the Baptist prepared the way for Christ, we are called to prepare our hearts for His coming.",
        verses: [
          { book: "Isaiah", chapter: 11, verse: 6, text: "The wolf also shall dwell with the lamb, and the leopard shall lie down with the kid; and the calf and the young lion and the fatling together; and a little child shall lead them.", testament: "old" },
          { book: "Luke", chapter: 3, verse: 4, text: "As it is written in the book of the words of Esaias the prophet, saying, The voice of one crying in the wilderness, Prepare ye the way of the Lord, make his paths straight.", testament: "new" },
          { book: "Philippians", chapter: 4, verse: 7, text: "And the peace of God, which passeth all understanding, shall keep your hearts and minds through Christ Jesus.", testament: "new" },
        ],
      },
      {
        name: "Third Sunday of Advent",
        themeHint:
          "Today is the Third Sunday of Advent, also known as Gaudete Sunday — a day of joy and rejoicing as the celebration of Christ's birth draws near. The devotional should overflow with joy, gladness, and anticipation.",
        verses: [
          { book: "Isaiah", chapter: 35, verse: 10, text: "And the ransomed of the LORD shall return, and come to Zion with songs and everlasting joy upon their heads: they shall obtain joy and gladness, and sorrow and sighing shall flee away.", testament: "old" },
          { book: "Philippians", chapter: 4, verse: 4, text: "Rejoice in the Lord alway: and again I say, Rejoice.", testament: "new" },
          { book: "Zephaniah", chapter: 3, verse: 17, text: "The LORD thy God in the midst of thee is mighty; he will save, he will rejoice over thee with joy; he will rest in his love, he will joy over thee with singing.", testament: "old" },
        ],
      },
      {
        name: "Fourth Sunday of Advent",
        themeHint:
          "Today is the Fourth Sunday of Advent, a time of love and fulfillment as Christmas is almost here. The devotional should reflect themes of God's love made manifest, the faithfulness of Mary, and the nearness of Emmanuel.",
        verses: [
          { book: "Micah", chapter: 5, verse: 2, text: "But thou, Bethlehem Ephratah, though thou be little among the thousands of Judah, yet out of thee shall he come forth unto me that is to be ruler in Israel; whose goings forth have been from of old, from everlasting.", testament: "old" },
          { book: "Luke", chapter: 1, verse: 46, text: "And Mary said, My soul doth magnify the Lord.", testament: "new" },
          { book: "1 John", chapter: 4, verse: 9, text: "In this was manifested the love of God toward us, because that God sent his only begotten Son into the world, that we might live through him.", testament: "new" },
        ],
      },
    ];

    for (let i = 0; i < 4; i++) {
      if (sameDay(date, adventSundays[i])) {
        return adventData[i];
      }
    }
  }

  return null;
}

// ─── Verse selection ────────────────────────────────────────────────

// Verse selection lives in ../_shared/verse-selection.ts so it can be
// imported and tested directly; this file cannot (top-level Deno.serve).
function selectRandomVerse(testament: "old" | "new"): SelectedVerse {
  return sharedSelectRandomVerse(
    testament === "old" ? OT_BOOKS : NT_BOOKS,
    testament,
    testament === "old" ? "Psalms" : "John",
  );
}

function selectVerse(
  targetTestament: "old" | "new",
  holiday: Holiday | null
): SelectedVerse {
  if (holiday && holiday.verses.length > 0) {
    return holiday.verses[Math.floor(Math.random() * holiday.verses.length)];
  }
  return selectRandomVerse(targetTestament);
}

// ─── Date formatting ────────────────────────────────────────────────

function getFormattedDate(
  date?: Date
): { formatted: string; isoDate: string } {
  const now = date ?? new Date();
  const formatted = now.toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
  const isoDate = now.toISOString().split("T")[0];
  return { formatted, isoDate };
}

// ─── Prompt creation ────────────────────────────────────────────────

// Shared blocks injected into both single-verse and multi-verse prompts.
// Kept as module-level constants so v2 → v3 is one edit and the test can
// assert structure by reading the source.
const PROMPT_INTRO =
  "You are writing a daily devotional for SwiftBible, a Bible iOS app. The reader could be anyone — a long-time Christian, a returning seeker, someone reading scripture for the first time. Don't presume their biography.";

const PROMPT_VOICE_RULES = `VOICE
- Concrete over abstract. One real image beats three abstract claims.
- Vary sentence rhythm. Mix short statements, fragments, longer descriptive sentences, inverted constructions ("There is..."), and different syntactic openings. Do NOT write three subject-verb sentences in a row with the same shape — that is the single most common AI tell in this format.
- Direct address ("you"), not first-person ("I"). NEVER write fake personal admissions like "I have lied" / "I have grieved" / "I have buried someone" — those belong to a real human author standing behind them. The reader should not have a stranger's biography put in their mouth.
- When describing a possible reader experience, use conditionals: "If you have ever..." / "Maybe you have..." Open the door without claiming the reader is through it.
- Acknowledge the cost of obedience honestly. Don't be glib.
- Quiet warmth, like a pastor who knows the reader. Not seminary lecture; not Sunday confrontation.

STRUCTURE (four beats, in this order)
1. Empathy — open with a concrete, *observable* scene or recognizable posture, NOT a presumed personal experience. Good: "Someone at dinner mentions their father is failing. The room goes still." / "You read the verse, nod, and forget it by lunch." / "The phone is in your hand again before you noticed picking it up." Bad: "the voicemail you can't delete" (presumes loss), "the addiction you can't kick" (presumes biography). Keep it observable, not autobiographical. Vary sentence shape inside this beat — mix at least one fragment or inverted construction with declarative sentences.
2. Bible — what the verse(s) actually say. Surrounding scripture as needed, in markdown blockquotes with bolded citations. Include ONE short Hebrew/Greek nuance when an original-language word genuinely opens up the meaning (e.g., *hamartia* = "miss the mark"; *eremos* = "wilderness, stripped down"). Keep the etymology to a sentence or two — never a multi-paragraph word study, never a forced insert when no word in the verse has a meaningful etymology. Aim for 3–4 paragraphs of unpacking in this beat; do not exceed 6.
3. Mix — bring beats 1 and 2 together. Show how the verse meets the reader where they actually are. Acknowledge the cost. End on the real difficulty, not a tidy bow.
4. Prayer — short, open-handed, addressed to the Father by default ("Lord" is fine where it reads more naturally). Use a direct address to Jesus ("Lord Jesus") ONLY when the verse itself models prayer or a cry to Jesus (e.g. the dying thief's "Lord, remember me," or "Come, Lord Jesus"). Do NOT address the prayer to the Holy Spirit — in the New Testament pattern the Spirit carries prayer to the Father through the Son rather than receiving it. Anyone reading should be able to pray it honestly. Format as a single italic paragraph using *single asterisks* (NOT markdown blockquote — the iOS app's verse-link detector treats blockquotes as verse references). Flowing prose, no internal line breaks. End with "Amen."

AVOID (these are AI tells / preachy patterns; strict)
- "In a world where..." / "In our busy lives..."
- "Let us not forget..." / "We must remember..."
- Symmetric, parallel sentences OR fragments stacked in a row. BAD (subject-verb): "A phone screen lights up. A headline shouts. A video plays." BAD (fragments): "Not heroic. Not public. Just a small good." Three of anything in a row with the same shape is the pattern to break. Alternate sentence shapes, mix in a longer sentence, or condense to two.
- Bullet lists of abstractions, including reflective journaling questions at the end
- Generic "may you..." benediction
- Multi-paragraph Greek/Hebrew word study (a one-sentence etymology note is fine; a paragraph of word-study is not)
- Moralistic call-out language
- Doctrinal/seminary tone
- Em dashes (—) in prose. Use commas, periods, semicolons, or parentheses instead. The em dash is a strong AI tell in this format. Exception: structural title format "# Date — Reference: Title" is fine, as are em dashes in directly quoted scripture; nowhere else.
- Antithesis constructions of the form "It's not X, it's Y" / "Not X, but Y" / "X is not the point. Y is." This rhetorical pivot reads as ChatGPT cadence. Rephrase positively ("Y is the point.") or rebuild the sentence so the contrast isn't the structure carrying the meaning.`;

// Shared theological guardrails for the narrative + practical tracks. Keeps
// the new tracks aligned with the non-denominational / non-institutional
// Church of Christ sensibility that this app's audience leans on.
//
// SOURCE OF TRUTH for the tradition behind these rules is the `church-of-christ`
// skill (.claude/skills/church-of-christ/). This function is deployed and cannot
// read the repo, so these lines are a hand-copied derivative — when the skill's
// doctrine.md or non-institutional.md changes materially, update here too.
// Same applies to the Bassford and classroom voice tracks below, which derive
// from the matt-bassford and josh-tolbert skills. Not added
// to the empathy/technical tracks because their behavior is already tuned;
// these guardrails are explicit because narrative and practical are easier
// to drift into eisegesis (invented scenes) or moralistic therapeutic deism
// (action-as-self-improvement) without them.

function holidayPromptSection(holiday: Holiday): string {
  return `\nHOLIDAY\nThis devotional is for ${holiday.name}. ${holiday.themeHint}\n- Reference "${holiday.name}" in the title.\n- Beat 1's empathy can lean on what ${holiday.name} typically evokes for readers, without presuming any reader's experience.\n`;
}

// One neutral worked example showing the four beats in v3 voice — varied
// sentence rhythm, observable empathy, one short Greek nuance, conditional
// in beat 3, open-handed prayer. The model mirrors this far more reliably
// than it follows abstract rules. Keep this verse (Mark 1:35) different
// from any common selection so the model doesn't accidentally recycle it.
// AI-tell guardrails. The empathy track carries its own richer inline AVOID
// list; every other track pulls these in. Sourced from the hand-editing rules
// Adam applies to anything published in his name (see the adam-voice skill):
// no em dashes, no antithesis pivots, no manufactured threes, no self-narration.
const PROMPT_AI_TELLS = `AVOID (AI tells; strict)
- Em dashes (—) in prose. Use commas, periods, semicolons, or parentheses. Strong AI tell.
  Exception: the structural title line "# Date — Reference: Title" and directly quoted scripture.
- Antithesis constructions: "It's not X, it's Y" / "Not X, but Y" / "X is not the point. Y is."
  Rephrase positively, or rebuild the sentence so the contrast isn't the structure carrying it.
- Manufactured threes. Do not reach for three parallel adjectives, three-clause sentences, or
  three-item lists as a rhythm device. Use the number of items the content actually has, usually
  two or four. A real three is fine; a padded one is the tell. Same for symmetric sentences or
  stacked fragments in a row: vary the shape, or condense to two.
- Throat-clearing and self-narration. Never announce what you are about to do, and never comment on
  the writing while doing it. Cut on sight: "to be honest", "I want to be clear", "worth noting",
  "here's the thing", "let me be direct". A section that opens by explaining why the section
  matters should open with its first real sentence instead.
- "In a world where..." / "In our busy lives..." / "Let us not forget..." / "We must remember..."
- Generic "may you..." benedictions, moralistic call-outs, and seminary tone.`;

const PROMPT_FEW_SHOT = `# May 15 — Mark 1:35: Before the world wakes

**Why does the answer to the busiest day arrive at the quietest hour?**

> *"And in the morning, rising up a great while before day, he went out, and departed into a solitary place, and there prayed."*
> **Mark 1:35**

## The hour before the work

The first sound is the door clicking shut behind him. Not a slam. Careful, as if afraid of waking the world. He stops on the threshold a moment, listening. Around him is the small hum of a town that has not woken up: a distant dog, the wind, nothing else. No crowd. No one needing to be healed. Not yet.

There is, for now, just him, and the cold, and the dark, and the long walk to whatever solitary place he has in mind.

## What he chose

The Greek for "solitary place" is *eremos*, the same word the Gospels use for the wilderness where Jesus was tempted. Not just "alone." Stripped down. Without props.

He has just had what any of us would call a successful day. The whole city pressed at the door (Mark 1:33). Demons cast out. Fevers gone. The kind of day a ministry would build a website around.

And before any of it could harden into an identity, he leaves it.

## Your version of the hour

If you have ever felt like the day's noise starts the moment you open your eyes, you know how thin the margin gets. The hour Jesus chose is not magic. It is just the only hour the world has not yet asked for.

You may not have a hillside. You may have ten minutes in a parked car before walking into the building.

The geography is not the point. The order is.

## A prayer

*Father, before the day asks me for anything, let me ask You first. Teach me the hour You chose. Make me unhurried in it. You are worth the full attention, even when I have none to spare. Amen.*`;

function createPrompt(
  verse: SelectedVerse,
  formattedDate: string,
  holiday: Holiday | null
): string {
  return `${PROMPT_INTRO}

VERSE
${verse.book} ${verse.chapter}:${verse.verse} — "${verse.text}"

DATE
${formattedDate}
${holiday ? holidayPromptSection(holiday) : ""}
${PROMPT_VOICE_RULES}

EXAMPLE — voice and structure to mirror
The example below is for a different verse (Mark 1:35). Do NOT reuse this example. Mirror its sentence rhythm, beat structure, and overall voice — then write a new devotional for the actual verse above.

${PROMPT_FEW_SHOT}

END OF EXAMPLE — now write your devotional for the actual verse above, using the same voice and four-beat structure.

MARKDOWN OUTPUT (use exactly this skeleton; copy the verse text verbatim)

# ${formattedDate} — ${verse.book} ${verse.chapter}:${verse.verse}: {Title}

**{One-line bolded subtitle — prefer a question; observation or thematic line are acceptable. NOT first-person. Avoid claims that go beyond what the verse itself says (e.g., don't add "He notices" when the verse only asks rhetorical questions).}**

> *"${verse.text}"*
> **${verse.book} ${verse.chapter}:${verse.verse}**

## {Section header for beat 1}

{empathy content — concrete, observable, varied sentence rhythm, no presumed biography}

## {Section header for beat 2}

{Bible content; one short Hebrew/Greek nuance if a word in this verse genuinely opens up the meaning, otherwise skip}

## {Section header for beat 3}

{closing argument; acknowledge cost; end on the real difficulty}

## A prayer

*{Address — "Father" by default (or "Lord"); "Lord Jesus" only if the verse itself models prayer to Jesus; never the Holy Spirit}, {short open-handed prayer body in flowing prose — single paragraph, italic, no blockquote, no line breaks. Anyone reading should be able to pray it honestly.} Amen.*
`;
}

// ─── Multi-verse selection (cheap model) ────────────────────────────

async function selectMultiVerses(
  count: number,
  holiday: Holiday | null
): Promise<{
  verses: Array<{ book: string; chapter: number; verse: number }>;
  usage: TokenUsage;
  prompt: string;
}> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) throw new Error("Missing OPENAI_API_KEY env var");

  // Step 1: Pick the first verse randomly (guarantees variety)
  const firstTestament: "old" | "new" = Math.random() < 0.5 ? "old" : "new";
  const seedVerse = selectRandomVerse(firstTestament);
  console.log(
    `Multi-verse seed (random): ${seedVerse.book} ${seedVerse.chapter}:${seedVerse.verse}`
  );

  const companionCount = count - 1;
  const holidayContext = holiday
    ? `\n\nThis devotional is for ${holiday.name}. ${holiday.themeHint}`
    : "";

  const prompt = `Given this Bible verse from the King James Version (KJV):

${seedVerse.book} ${seedVerse.chapter}:${seedVerse.verse} — "${seedVerse.text}"

Select exactly ${companionCount} companion verse${companionCount > 1 ? "s" : ""} that ${companionCount > 1 ? "connect" : "connects"} thematically to create a powerful multi-verse devotional.${holidayContext}

Rules:
- Choose from a DIFFERENT book than ${seedVerse.book}
- The companion should add a new dimension to the theme — not just echo the same idea
- Use exact book names as they appear in the KJV (e.g. "Psalms" not "Psalm", "1 Corinthians" not "First Corinthians", "Song of Solomon" not "Song of Songs")
- Only use books from the 66-book Protestant canon

Return ONLY a JSON object in this exact format:
{
  "verses": [
    { "book": "BookName", "chapter": 1, "verse": 1 }
  ]
}`;

  const maxRetries = 2;
  let content: string | undefined;
  let lastError: Error | undefined;
  let usage: TokenUsage = extractUsage(null, VERSE_SELECTION_MODEL);

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    if (attempt > 0) {
      const delay = attempt * 1000;
      console.log(`selectMultiVerses retry ${attempt}/${maxRetries} after ${delay}ms`);
      await new Promise((r) => setTimeout(r, delay));
    }

    try {
      const response = await fetch(OPENAI_CHAT_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: VERSE_SELECTION_MODEL,
          messages: [
            {
              role: "system",
              content:
                "You are a Bible verse selector. Return only valid JSON with KJV verse references.",
            },
            { role: "user", content: prompt },
          ],
          response_format: { type: "json_object" },
          max_completion_tokens: 300,
        }),
        signal: AbortSignal.timeout(30000),
      });

      if (!response.ok) {
        let errorText: string | undefined;
        try {
          errorText = JSON.stringify(await response.json());
        } catch (_) {
          errorText = await response.text();
        }
        lastError = new Error(`Verse selection failed (${response.status}): ${errorText}`);
        continue;
      }

      const data = await response.json();
      console.log("selectMultiVerses response:", JSON.stringify(data, null, 2));
      content = data?.choices?.[0]?.message?.content;
      usage = extractUsage(data, VERSE_SELECTION_MODEL);
      if (!content) {
        lastError = new Error(`Empty verse selection response: ${JSON.stringify(data)}`);
        continue;
      }

      break;
    } catch (err) {
      lastError = err instanceof Error ? err : new Error(String(err));
    }
  }

  if (!content) throw lastError ?? new Error("Verse selection failed after retries");

  const parsed = JSON.parse(content);
  if (!Array.isArray(parsed.verses) || parsed.verses.length === 0) {
    throw new Error("Invalid verse selection format");
  }

  // Combine: random seed verse + GPT companion(s)
  const allVerses = [
    { book: seedVerse.book, chapter: seedVerse.chapter, verse: seedVerse.verse },
    ...parsed.verses,
  ];

  console.log(
    `Verse selection: ${allVerses.map((v: { book: string; chapter: number; verse: number }) => `${v.book} ${v.chapter}:${v.verse}`).join(", ")}`
  );

  return { verses: allVerses, usage, prompt };
}

// ─── Multi-verse prompt creation ────────────────────────────────────

function createMultiVersePrompt(
  verses: SelectedVerse[],
  formattedDate: string,
  holiday: Holiday | null
): string {
  const versesList = verses
    .map((v) => `- ${v.book} ${v.chapter}:${v.verse} — "${v.text}"`)
    .join("\n");
  const versesBlockquote = verses
    .map((v) => `> *"${v.text}"*\n> **${v.book} ${v.chapter}:${v.verse}**`)
    .join("\n>\n");
  const primary = verses[0];
  const titleRef = holiday
    ? `${holiday.name}`
    : `${primary.book} ${primary.chapter}:${primary.verse}`;

  return `${PROMPT_INTRO}

VERSES (weave these together — show how each illuminates the others, not just three echoes of one idea)
${versesList}

DATE
${formattedDate}
${holiday ? holidayPromptSection(holiday) : ""}
${PROMPT_VOICE_RULES}

EXAMPLE — voice and structure to mirror
The example below is single-verse (Mark 1:35), but the voice, beat structure, and rhythm apply equally to multi-verse. Do NOT reuse this example. Mirror its rhythm and four-beat shape — then write a new multi-verse devotional for the actual verses above, weaving them into one thread.

${PROMPT_FEW_SHOT}

END OF EXAMPLE — now write your multi-verse devotional for the actual verses above, using the same voice.

MULTI-VERSE NOTE
Present ALL verses together in the opening blockquote (each on its own line with bolded reference). In beat 2, unpack the thread that connects them — show how each verse from a different part of Scripture speaks to the same truth.

MARKDOWN OUTPUT (use exactly this skeleton; copy verse texts verbatim)

# ${formattedDate} — ${titleRef}: {Title}

**{One-line bolded subtitle — prefer a question; observation or thematic line are acceptable. NOT first-person. Should capture the unified thread without adding interpretive claims that go beyond what the verses themselves say.}**

${versesBlockquote}

## {Section header for beat 1}

{empathy content — concrete, observable, varied sentence rhythm, no presumed biography}

## {Section header for beat 2}

{Bible content; unpack each verse and the thread connecting them; one short Hebrew/Greek nuance if a word genuinely opens up the meaning, otherwise skip}

## {Section header for beat 3}

{closing argument bringing the verses together; acknowledge cost; end on the real difficulty}

## A prayer

*{Address — "Father" by default (or "Lord"); "Lord Jesus" only if the verses themselves model prayer to Jesus; never the Holy Spirit}, {short open-handed prayer drawing from all the verses together — single paragraph in flowing prose, italic, no blockquote, no line breaks. Anyone reading should be able to pray it honestly.} Amen.*
`;
}

// ─── Technical track: prompts ───────────────────────────────────────
// Restored from the original v1 prompt — numbered guidelines, heavier on
// historical/cultural/linguistic context, lighter on modern empathy.
// Mixed in alongside the empathy track for voice variety.

function createTechnicalPrompt(
  verse: SelectedVerse,
  formattedDate: string,
  holiday: Holiday | null
): string {
  const holidaySection = holiday
    ? `\n\nHoliday Context:\n${holiday.themeHint}\n`
    : "";

  return `Create a daily devotional for a Bible app based on the following Bible verse from the King James Version (KJV):

${verse.book} ${verse.chapter}:${verse.verse} - "${verse.text}"

Date: ${formattedDate}
${holidaySection}
Devotional Guidelines:

1. Title: Use # for the title at the top. Include the date and passage reference.${holiday ? ` Reference the holiday "${holiday.name}".` : ""}

2. Subtitle: A **bolded thematic summary** line immediately below the title. DO NOT include the date or passage reference in the subtitle.

3. Verse Block: Place the verse text in a Markdown blockquote directly beneath the title and subtitle:
   > "${verse.text}"
   > **${verse.book} ${verse.chapter}:${verse.verse}**

4. Devotional Content (use ## section headers for each major movement):
   - Contextual Background — the verse's place in the surrounding narrative and the broader biblical story.
   - Historical and Cultural Insights — customs, geography, political setting, and traditions relevant to the original audience.
   - Linguistic and Translational Insights — key Hebrew or Greek words, embedded in the prose with their meanings and any nuances. Use these freely; this track leans into language.

5. Modern Relevance: Connect the passage to contemporary themes${holiday ? ` and to the significance of ${holiday.name}` : ""}. Encourage application without reducing the verse to self-help.

6. Personal Reflection and Application: Include 4–6 reflective questions formatted as a Markdown bulleted list.

7. Final Meditation: Close with a short prayerful reflection formatted as a single paragraph in italics using *single asterisks* (NOT markdown blockquote — the iOS app's verse-link detector treats blockquotes as verse references). If it addresses God directly, address the Father by default; address Jesus directly ("Lord Jesus") only when the verse itself models prayer to Jesus, and do not address the Holy Spirit. End with "Amen."

${PROMPT_AI_TELLS}
`;
}

function createTechnicalMultiVersePrompt(
  verses: SelectedVerse[],
  formattedDate: string,
  holiday: Holiday | null
): string {
  const versesList = verses
    .map((v) => `${v.book} ${v.chapter}:${v.verse} — "${v.text}"`)
    .join("\n- ");
  const holidaySection = holiday
    ? `\n\nHoliday Context:\n${holiday.themeHint}\n`
    : "";

  return `Create a daily devotional for a Bible app that weaves together the following ${verses.length} thematically connected Bible verses from the King James Version (KJV)${holiday ? ` for ${holiday.name}` : ""}:

- ${versesList}

Date: ${formattedDate}
${holidaySection}
Devotional Guidelines:

1. Title: Use # for the title at the top. Include the date and the primary passage reference${holiday ? `, plus "${holiday.name}"` : ""}.

2. Subtitle: A **bolded thematic summary** line that captures the unified theme connecting all the verses. DO NOT include the date or passage references.

3. Verse Block: Present ALL verses together in a single Markdown blockquote — each verse on its own line with its bolded reference beneath it.

4. Thematic Thread: Explain the thread that connects the passages. Show how each verse illuminates and builds upon the others, creating a richer understanding than any single verse alone.

5. Devotional Content (use ## section headers):
   - Contextual Background — each verse's place in its surrounding narrative.
   - Historical and Cultural Insights — relevant customs, settings, and traditions.
   - Linguistic and Translational Insights — key Hebrew or Greek words embedded in the prose with their meanings.
   - Cross-Reference Connection — explicitly show how these verses from different parts of Scripture speak to the same truth.

6. Modern Relevance: Show how the combined message applies to contemporary life${holiday ? ` and the significance of ${holiday.name}` : ""}.

7. Personal Reflection and Application: Include 4–6 reflective questions formatted as a Markdown bulleted list. At least one question should ask the reader to consider what the verses together reveal that no single verse alone does.

8. Final Meditation: Close with a short prayerful reflection drawing from all the verses, formatted as a single paragraph in italics using *single asterisks* (NOT markdown blockquote). If it addresses God directly, address the Father by default; address Jesus directly ("Lord Jesus") only when the verses themselves model prayer to Jesus, and do not address the Holy Spirit. End with "Amen."

${PROMPT_AI_TELLS}
`;
}

// ─── Narrative track: prompts ───────────────────────────────────────
// Drops the reader inside the biblical scene — present tense, sensory,
// observational. No invented dialogue or internal monologue. CoC concern:
// staying close to the inspired text. No Ignatian "place yourself in the
// scene with Jesus" framings — kept observational, not invocational.

const PROMPT_NARRATIVE_RULES = `VOICE — narrative track
- Drop the reader inside the biblical scene. Sensory, observational, alive.
- Present tense, third-person observer ("Peter sees the door swing shut...") or limited second-person ("You're standing at the edge of the crowd...").
- Anchor concretely in 1st-century reality: heat, dust, lamp oil, crowd noise, the smell of fish, the sound of sandals on stone. Geographical and cultural inference is allowed.
- DO NOT invent dialogue, internal monologue, or character motivations that scripture doesn't supply. If a character doesn't say it in the text, don't put words in their mouth. If we don't know what someone thought or felt, don't tell us they thought or felt it.
- One scene, not a montage. Hold the camera in one place.
- No anachronisms. No phones, no traffic, no "in our 21st-century lives."
- Avoid Ignatian "place yourself in the scene with Jesus and ask Him a question" framings — keep it observational, not invocational.

STRUCTURE (four beats)
1. Scene — open inside the moment. Describe what a careful observer would have seen and heard. Build the room with specific, grounded detail (the rope coiled by the boat, the sweat on a forehead, the shadow of a tree). Vary sentence rhythm.
2. The moment the verse lands — quote the verse in a blockquote with bolded reference. Place it in the action. Why these specific words, in this specific moment. One short Hebrew/Greek nuance is allowed if a word genuinely opens the scene; otherwise skip.
3. And now — short bridge that pulls the scene into the reader's life. Honor that the cost back then echoes the cost now. Don't preach; observe. End on the real difficulty, not a tidy bow.
4. Prayer — short open-handed italic paragraph using *single asterisks* (NOT a blockquote — the iOS verse-link detector treats blockquotes as verse references). Address the Father by default; address Jesus directly ("Lord Jesus") only when the verse itself models prayer or a cry to Jesus, and do not address the Holy Spirit. End with "Amen."

AVOID
- Invented dialogue or internal thoughts that scripture doesn't supply
- "Imagine you are..." framings; drop the reader in directly
- Multi-scene montages or time-jumps
- Modern anachronisms
- Long historical exposition; this is a story, not a Wikipedia article
- Putting words in Jesus' mouth or guessing what He was feeling
- Closing flourish; the prayer is the close
- Em dashes (—) in prose. Use commas, periods, semicolons, or parentheses. Strong AI tell. Exception: structural title format and directly quoted scripture only.
- Antithesis constructions of the form "It's not X, it's Y" / "Not X, but Y" / "X is not the point. Y is." Rephrase positively or rebuild the sentence so the contrast isn't the structure carrying the meaning.`;

// Few-shot example for the narrative track. Luke 19:5 (Zacchaeus) — picked
// because the scripture supplies enough scene material (sycamore, crowd,
// "looked up") that the example can be vivid without inventing anything.
const PROMPT_NARRATIVE_FEW_SHOT = `# October 12 — Luke 19:5: Under the sycamore

**The tree is the only place left.**

> *"And when Jesus came to the place, he looked up, and saw him, and said unto him, Zacchaeus, make haste, and come down; for to day I must abide at thy house."*
> **Luke 19:5**

## The tree

The road into Jericho is dust and sandals. The crowd ahead is thick. Shoulders, robes, voices climbing over each other. Somewhere in the middle of it, the rabbi is moving slowly toward the city gate.

Behind the crowd, a short man has run ahead. His tunic is hiked up. His sandals slap the stones. He is not used to running like this.

A sycamore stands beside the road, ancient and wide, the branches starting low. He climbs. The bark scrapes his palms.

From up here he can see the road. He can see the back of the rabbi's head moving through the press. He cannot, from up here, be seen. That's the point. A tax collector is not loved in Jericho. A short, rich tax collector is the kind of man who watches from above.

## The moment

The crowd reaches the tree. The rabbi stops walking. He looks up.

The Greek behind "must" is *dei*, which carries the weight of necessity. Today. Your house.

The words are said publicly. Anyone in the crowd could have heard them. The branches above Jericho stop being a hiding place. They become a name spoken out loud in front of everyone who hates him.

## And now

You may know the version of climbing into a tree. The corner of a room where the conversation can't reach. The polite distance from the people who would not be glad to see you. The carefully arranged life where you are not, exactly, available.

Christ has a habit of stopping under exactly that tree.

## A prayer

*Father, You sent Your Son to find Zacchaeus in his hiding place and call him down by name. Find the tree I am in. Call me out of it, and give me the strength to come down. Amen.*`;

function createNarrativePrompt(
  verse: SelectedVerse,
  formattedDate: string,
  holiday: Holiday | null
): string {
  return `${PROMPT_INTRO}

VERSE
${verse.book} ${verse.chapter}:${verse.verse} — "${verse.text}"

DATE
${formattedDate}
${holiday ? holidayPromptSection(holiday) : ""}
${PROMPT_THEOLOGY_GUARDRAILS}

${PROMPT_NARRATIVE_RULES}

EXAMPLE — voice and structure to mirror
The example below is for a different verse (Luke 19:5). Do NOT reuse this example. Mirror its present-tense observational voice, its four-beat scene→moment→now→prayer structure, and its commitment to staying inside what scripture actually supplies. Then write a new devotional for the actual verse above.

${PROMPT_NARRATIVE_FEW_SHOT}

END OF EXAMPLE — now write your narrative devotional for the actual verse above.

MARKDOWN OUTPUT (use exactly this skeleton; copy the verse text verbatim)

# ${formattedDate} — ${verse.book} ${verse.chapter}:${verse.verse}: {Title — a phrase from the scene, not a sermon topic}

**{One-line bolded subtitle — observational, not first-person. A line that captures the moment.}**

> *"${verse.text}"*
> **${verse.book} ${verse.chapter}:${verse.verse}**

## {Section header naming the scene}

{The scene in concrete, sensory detail. Where are we? Who is present? What can be seen and heard? Hold the camera in one place. No invented dialogue or interior thoughts.}

## {Section header — the moment the verse lands}

{Let the verse arrive in the scene. Why these specific words, in this specific moment. One short Hebrew/Greek nuance only if a word genuinely opens the meaning.}

## {Section header — and now}

{Bridge to the reader. The scene then; the same kind of weight now. Acknowledge the cost. End on the real difficulty.}

## A prayer

*{Address — "Father" by default (or "Lord"); "Lord Jesus" only if the verse itself models prayer to Jesus; never the Holy Spirit}, {short open-handed prayer in flowing prose, single italic paragraph, no line breaks.} Amen.*

${PROMPT_AI_TELLS}
`;
}

function createNarrativeMultiVersePrompt(
  verses: SelectedVerse[],
  formattedDate: string,
  holiday: Holiday | null
): string {
  const versesList = verses
    .map((v) => `- ${v.book} ${v.chapter}:${v.verse} — "${v.text}"`)
    .join("\n");
  const versesBlockquote = verses
    .map((v) => `> *"${v.text}"*\n> **${v.book} ${v.chapter}:${v.verse}**`)
    .join("\n>\n");
  const primary = verses[0];
  const titleRef = holiday
    ? `${holiday.name}`
    : `${primary.book} ${primary.chapter}:${primary.verse}`;

  return `${PROMPT_INTRO}

VERSES (weave these together through a single scene — the primary verse anchors the moment; the companion verse(s) illuminate it without breaking the camera)
${versesList}

DATE
${formattedDate}
${holiday ? holidayPromptSection(holiday) : ""}
${PROMPT_THEOLOGY_GUARDRAILS}

${PROMPT_NARRATIVE_RULES}

MULTI-VERSE NOTE
The primary verse anchors a single scene. The companion verse(s) should appear naturally — quoted in beat 2 as a counterpoint or amplification — without pulling the camera to a second scene. Resist the urge to do two scenes; do one scene that the second verse helps explain.

MARKDOWN OUTPUT (use exactly this skeleton; copy the verse texts verbatim)

# ${formattedDate} — ${titleRef}: {Title — a phrase from the primary scene}

**{One-line bolded subtitle — observational, not first-person.}**

${versesBlockquote}

## {Section header naming the scene}

{The primary scene in concrete, sensory detail. One camera, one place.}

## {Section header — the moment the verse lands}

{The primary verse arriving in the scene. Then bring in the companion verse(s) as illumination — quoted again inline or referenced — showing the same truth from a different angle. No second scene.}

## {Section header — and now}

{Bridge to the reader. Acknowledge the cost. End on the real difficulty.}

## A prayer

*{Address — "Father" by default (or "Lord"); "Lord Jesus" only if the verses themselves model prayer to Jesus; never the Holy Spirit}, {short open-handed prayer drawing from the unified thread, single italic paragraph, no line breaks.} Amen.*

${PROMPT_AI_TELLS}
`;
}

// ─── Practical track: prompts ───────────────────────────────────────
// One concrete action for today. Short, direct, honest about the cost.
// CoC guardrail: action is response to grace, not earning. No moralistic
// therapeutic deism; no productivity-blog framing; no "5 ways to..."

const PROMPT_PRACTICAL_RULES = `VOICE — practical track
- Direct. Concrete. The reader has a few minutes. Give them one thing to do today.
- Second person OK. Conversational, not coach-speak. No pep-talk.
- Acknowledge the cost. Don't say obedience is easy when it isn't.
- One action, not three. Resist the "five ways to..." impulse. One concrete, specific, doable thing.
- Action is response to grace, not earning. Don't promise outcomes ("if you do X, God will give you Y") — obedience is not a transaction.

STRUCTURE (five beats — aim for ~350-450 words total)
1. Verse — quote in blockquote with bolded reference. Below the title, one bolded sentence that names what this devotional is asking the reader to do today.
2. What it says — one paragraph (3-5 sentences). What is this verse actually telling us, in plain language? No theology jargon. No "the Greek word here is..." — that's another track's job.
3. Today — header "## Today" (or one-word variant like "## Do this"). One concrete action in the imperative. Specific enough that the reader knows exactly what it looks like today. Then a sentence or two on why this is hard — name the cost honestly. Don't moralize.
4. When you try — header "## When you try" (or "## Where it gets hard"). Short honest paragraph naming the specific failure mode for THIS action: how it tends to go sideways in the actual doing of it. What the verse says to do when it falls apart mid-attempt. Don't moralize the failure. Be specific — not "you might find it hard" but "you will draft the message and then add a 'but'."
5. Prayer — single italic paragraph using *single asterisks* (NOT blockquote). Brief. Asks for help with the actual thing the reader is being asked to do. Address the Father by default; address Jesus directly ("Lord Jesus") only when the verse itself models prayer or a cry to Jesus, and do not address the Holy Spirit. End with "Amen."

ACTION EXAMPLES (seeds for the kind of specificity to aim for — do not reuse verbatim)
- "Text someone you owe an apology. Don't pad it with explanations or conditions."
- "Set aside the next ten dollars you'd spend on yourself. Give it away anonymously today."
- "Sit through one conversation today without preparing your reply while the other person is still talking."
- "Open your Bible to the chapter the verse comes from and read the next ten verses. No agenda. No notes."
- "Pick one person you keep meaning to call. Call them today, not tomorrow."
- "Take an unwon argument from yesterday and let it stay unwon. Don't bring it back up."

AVOID
- "Be your best self" / "live your truth" / "you've got this" (moralistic therapeutic deism is out)
- "Five ways to..." / "Three things you can do..." (one action only)
- Productivity-blog framing (no "habit stacking," no morning-routine talk, no "build a 30-day streak")
- Generic "spend time with God today" or "read your Bible more" (too abstract to act on)
- Promising outcomes ("if you do this, God will bless you with X"); obedience is response to grace, not transaction
- Long theological exposition; keep it tight
- Em dashes (—) in prose. Use commas, periods, semicolons, or parentheses. Strong AI tell. Exception: structural title format and directly quoted scripture only.
- Antithesis constructions of the form "It's not X, it's Y" / "Not X, but Y" / "X is not the point. Y is." Rephrase positively or rebuild the sentence so the contrast isn't the structure carrying the meaning.`;

// Few-shot example for the practical track. Matthew 5:24 — picked because
// the verse itself names a concrete action ("first be reconciled"), making
// it a natural template for the one-action structure.
const PROMPT_PRACTICAL_FEW_SHOT = `# October 14 — Matthew 5:24: First

**Don't bring the worship until the apology is sent.**

> *"Leave there thy gift before the altar, and go thy way; first be reconciled to thy brother, and then come and offer thy gift."*
> **Matthew 5:24**

## What it says

Jesus interrupts worship to send you on an errand. Reconciliation comes first, then the gift on the altar. He doesn't say "after you finish singing." He says leave the gift right there. Go fix what's broken first.

## Today

Text the one person you owe an apology to. Don't pad it with explanations. Don't make it conditional ("I'm sorry you took it that way…"). Just: "I was wrong about X. I'm sorry."

This is hard because you were probably right about something else, and the apology will feel one-sided. It will feel unfair. The verse doesn't say "first be reconciled if it's deserved." It says first.

## When you try

You will draft the message and then add a "but." You will want to be fair to your side of the story. Notice that Jesus does not say "first be reconciled if it's mutually equitable." He says first. Send the apology without the second half. The conversation about who else was wrong can happen tomorrow, in person, or never. Today's job is the first half.

## A prayer

*Father, You sent me on an errand before You will accept my worship. Help me go now, even though it costs my pride. Help me name what I did without softening it, and keep me from adding the "but." Amen.*`;

function createPracticalPrompt(
  verse: SelectedVerse,
  formattedDate: string,
  holiday: Holiday | null
): string {
  return `${PROMPT_INTRO}

VERSE
${verse.book} ${verse.chapter}:${verse.verse} — "${verse.text}"

DATE
${formattedDate}
${holiday ? holidayPromptSection(holiday) : ""}
${PROMPT_THEOLOGY_GUARDRAILS}

${PROMPT_PRACTICAL_RULES}

EXAMPLE — voice and structure to mirror
The example below is for a different verse (Matthew 5:24). Do NOT reuse this example. Mirror its tight three-section shape, the one-concrete-action discipline, and the honest naming of cost. Then write a new devotional for the actual verse above.

${PROMPT_PRACTICAL_FEW_SHOT}

END OF EXAMPLE — now write your practical devotional for the actual verse above.

MARKDOWN OUTPUT (use exactly this skeleton; copy the verse text verbatim)

# ${formattedDate} — ${verse.book} ${verse.chapter}:${verse.verse}: {Title — a verb or a short imperative phrase}

**{One-line bolded subtitle — names the action the reader is being asked to do today.}**

> *"${verse.text}"*
> **${verse.book} ${verse.chapter}:${verse.verse}**

## What it says

{One paragraph, 3-5 sentences. Plain language. What the verse actually says, no jargon.}

## Today

{One concrete action in the imperative. Specific enough that the reader knows exactly what it looks like today. Then a sentence or two on why this is hard — name the cost honestly, no moralizing.}

## When you try

{Short honest paragraph naming the specific failure mode for this action — how it tends to go sideways in the actual doing of it. What the verse says to do when it falls apart mid-attempt. Be specific, not abstract.}

## A prayer

*{Address — "Father" by default (or "Lord"); "Lord Jesus" only if the verse itself models prayer to Jesus; never the Holy Spirit}, {brief open-handed prayer asking for help with the actual action.} Amen.*

${PROMPT_AI_TELLS}
`;
}

function createPracticalMultiVersePrompt(
  verses: SelectedVerse[],
  formattedDate: string,
  holiday: Holiday | null
): string {
  const versesList = verses
    .map((v) => `- ${v.book} ${v.chapter}:${v.verse} — "${v.text}"`)
    .join("\n");
  const versesBlockquote = verses
    .map((v) => `> *"${v.text}"*\n> **${v.book} ${v.chapter}:${v.verse}**`)
    .join("\n>\n");
  const primary = verses[0];
  const titleRef = holiday
    ? `${holiday.name}`
    : `${primary.book} ${primary.chapter}:${primary.verse}`;

  return `${PROMPT_INTRO}

VERSES (these verses together point at one concrete action — find what they jointly ask of the reader)
${versesList}

DATE
${formattedDate}
${holiday ? holidayPromptSection(holiday) : ""}
${PROMPT_THEOLOGY_GUARDRAILS}

${PROMPT_PRACTICAL_RULES}

MULTI-VERSE NOTE
Both verses should jointly identify the one action. Quote them together in the opening blockquote, then in "What it says" name the thread that connects them — but don't unpack each verse separately. The action in "## Today" should be the natural intersection of what they're both asking for.

MARKDOWN OUTPUT (use exactly this skeleton; copy the verse texts verbatim)

# ${formattedDate} — ${titleRef}: {Title — a verb or short imperative phrase}

**{One-line bolded subtitle — names the action the reader is being asked to do today.}**

${versesBlockquote}

## What they say

{One paragraph, 3-5 sentences. Plain language. The shared thread these verses point at.}

## Today

{One concrete action in the imperative. Then the cost.}

## When you try

{Short honest paragraph naming the specific failure mode for this action and what the verses say to do when it goes sideways. Be specific.}

## A prayer

*{Address — "Father" by default (or "Lord"); "Lord Jesus" only if the verses themselves model prayer to Jesus; never the Holy Spirit}, {brief open-handed prayer for the action.} Amen.*

${PROMPT_AI_TELLS}
`;
}

// ─── Devotional generation (OpenAI) ─────────────────────────────────

async function generateDevotional(
  prompt: string
): Promise<{ message: string; usage: TokenUsage }> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) throw new Error("Missing OPENAI_API_KEY env var");
  const model = DEVOTIONAL_MODEL;

  const response = await fetch(OPENAI_CHAT_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages: [
        {
          role: "system",
          content:
            "You are a Christian devotional writing assistant. Return well-structured Markdown only, no extra commentary.",
        },
        { role: "user", content: prompt },
      ],
      max_completion_tokens: 4000,
    }),
    signal: AbortSignal.timeout(120000),
  });

  if (!response.ok) {
    let errorText: string | undefined;
    try {
      const errorData = await response.json();
      errorText = JSON.stringify(errorData);
    } catch (_) {
      errorText = await response.text();
    }
    throw new Error(
      `OpenAI Chat Completions failed with status ${response.status}: ${errorText}`
    );
  }

  const data = await response.json();
  console.log("OpenAI API Response:", JSON.stringify(data, null, 2));
  const usage = extractUsage(data, model);
  const content = data?.choices?.[0]?.message?.content;
  if (typeof content === "string" && content.trim().length > 0) {
    return { message: content.trim(), usage };
  }
  const alt = data?.choices?.[0]?.text;
  if (typeof alt === "string" && alt.trim().length > 0) {
    return { message: alt.trim(), usage };
  }
  console.log("Content was:", content, "Alt was:", alt);
  throw new Error("Empty model output from Chat Completions API");
}

// ─── Database operations ────────────────────────────────────────────

function createSupabaseClient() {
  return createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );
}

// Tracks rotate round-robin alongside (but independent of) the
// single/multi/testament rotation. Listed in cycle order; the next track
// is the one immediately after yesterday's in this array (wrapping). Add
// new tracks to the end and they get picked up automatically. Custom
// (Sunday) rows have a NULL track and don't advance the cycle — the next
// AI day picks up where the previous AI day left off.
// Order matters: it is the round-robin. Interleave the speaker-voice and
// mood tracks between the originals so no two adjacent days feel alike.
const TRACK_CYCLE = [
  "empathy", "technical", "narrative", "practical",
  "matt", "josh", "lament", "question", "character",
] as const;
type Track = typeof TRACK_CYCLE[number];


// ─── Six additional tracks ──────────────────────────────────────────
// matt / josh distil the *teaching method* of two real preachers whose
// archives live in speakers/. They are deliberately NOT impersonations:
// no first-person biography, no signature, no attribution. See
// speakers/matt-bassford/ and speakers/josh-tolbert/ for the voice
// profiles these were derived from.



const PROMPT_LAMENT_RULES = `VOICE — lament track
- This track does NOT resolve. That is its whole purpose; the other tracks resolve and this one
  fills the gap for readers who are not okay today.
- Sit inside the grief, doubt, or anger of the passage without hurrying to comfort.
- Never say "but" in the pivot position. No silver lining, no lesson-of-suffering, no theodicy.
- Do not explain why God permitted the thing. Scripture frequently does not, and neither should you.
- Name what is actually lost, plainly, without decorating it.
- The honest ending is often unresolved — the psalmists end mid-complaint more often than we admit.
  You may end on address rather than answer: the sufferer is still speaking to God.
- The prayer may ask for nothing but presence. It must not tidy the grief up.`;

const PROMPT_QUESTION_RULES = `VOICE — question-led track
- Open with one real question — one a thoughtful reader might actually ask, including the
  uncomfortable ones. Not rhetorical, not a set-up for an answer you already hold.
- Work toward it visibly. Let the reader watch the reasoning, including where it runs out.
- Consider the strongest objection in its strongest form, in the objector's own words, before
  answering. If it is not fully answerable, say so.
- Distinguish what scripture states, what it implies, and what is inference. Keep those separate.
- End with the question sharpened rather than dissolved, and one thing to do with it today.`;

const PROMPT_CHARACTER_RULES = `VOICE — character-study track
- One biblical person across an arc, not a single scene (that is the narrative track's job).
- Show change over time: who they were, what happened, who they became — and what God did with
  the failure rather than around it.
- Keep them a person, not a moral type. Specific, embodied, capable of being wrong.
- Do not flatten the ending. Some arcs in scripture end badly, and those still teach.
- Resist the hero read. The text is usually more interested in God's faithfulness than their virtue.
- Land on the reader's own arc without forcing a parallel that is not there.`;


// Markdown skeletons per new track. `h` is the heading line already built
// with date + reference, so each track only defines its own body sections.
function newTrackSkeleton(track: string, headingRef: string, verseBlock: string, formattedDate: string): string {
  const head = `# ${formattedDate} — ${headingRef}: {Title}`;
  const prayer = `## A prayer\n\n*{Address — "Father" by default (or "Lord"); "Lord Jesus" only if the verse itself models prayer to Jesus; never the Holy Spirit}, {short open-handed prayer in flowing prose, single italic paragraph, no line breaks.} Amen.*`;
  switch (track) {
    case "matt":
      return `${head}\n\n**{One-line bolded subtitle — flat and declarative, not a question.}**\n\n${verseBlock}\n\n## The thing itself\n\n{Open on concrete domestic detail. Short sentences. Let one land alone.}\n\n## What it actually says\n\n{Precise on the text — name which part of the passage carries the weight. Dry, accurate, unsentimental.}\n\n## So\n\n{Three to five short imperative clauses. Command voice. No summary, no flourish.}\n\n${prayer}`;
    case "josh":
      return `${head}\n\n**{One-line bolded subtitle — phrased as the question the lesson works on.}**\n\n${verseBlock}\n\n## A question first\n\n{Ask it plainly. Give the reader room to answer before you do.}\n\n## The world it was written into\n\n{Who wrote it, to whom, into what situation. Price your claims — say what is disputed or uncertain.}\n\n## Whose definition?\n\n{Name where a modern reading of a key word differs from what it meant there.}\n\n## Back to you\n\n{Hand the question back, sharpened. One thing to sit with today.}\n\n${prayer}`;
    case "lament":
      return `${head}\n\n**{One-line bolded subtitle — do not console in it.}**\n\n${verseBlock}\n\n## What is lost\n\n{Name it plainly and specifically. No decoration, no cushioning.}\n\n## The passage does not tidy this\n\n{Stay inside the text's own grief or protest. Do not supply a reason God has not supplied.}\n\n## Still speaking\n\n{The sufferer is still addressing God. That is the only resolution on offer, and it may be enough. Do not resolve further.}\n\n${prayer}`;
    case "question":
      return `${head}\n\n**{One-line bolded subtitle — the question itself.}**\n\n${verseBlock}\n\n## The question\n\n{One real question, including the uncomfortable form of it.}\n\n## The strongest objection\n\n{State it in its strongest form, in the objector's own words, before answering.}\n\n## What the text does and does not settle\n\n{Separate what scripture states, what it implies, and what is inference.}\n\n## Sharpened\n\n{End with the question sharpened rather than dissolved, plus one thing to do with it today.}\n\n${prayer}`;
    default: // character
      return `${head}\n\n**{One-line bolded subtitle — names the person and the turn.}**\n\n${verseBlock}\n\n## Who they were\n\n{Specific and embodied. A person, not a moral type.}\n\n## What happened\n\n{The turn. What God did with the failure rather than around it.}\n\n## How it ends\n\n{Do not flatten it. Some arcs end badly and still teach.}\n\n## Your arc\n\n{Land on the reader without forcing a parallel that is not there.}\n\n${prayer}`;
  }
}

function newTrackRules(track: string): string {
  switch (track) {
    case "matt": return PROMPT_MATT_RULES;
    case "josh": return PROMPT_JOSH_RULES;
    case "lament": return PROMPT_LAMENT_RULES;
    case "question": return PROMPT_QUESTION_RULES;
    default: return PROMPT_CHARACTER_RULES;
  }
}

function createNewTrackPrompt(
  track: string,
  verse: SelectedVerse,
  formattedDate: string,
  holiday: Holiday | null
): string {
  const ref = `${verse.book} ${verse.chapter}:${verse.verse}`;
  const verseBlock = `> *"${verse.text}"*\n> **${ref}**`;
  return `${PROMPT_INTRO}

VERSE
${ref} — "${verse.text}"

DATE
${formattedDate}
${holiday ? holidayPromptSection(holiday) : ""}
${PROMPT_THEOLOGY_GUARDRAILS}

${newTrackRules(track)}

MARKDOWN OUTPUT (use exactly this skeleton; copy the verse text verbatim)

${newTrackSkeleton(track, ref, verseBlock, formattedDate)}

${PROMPT_AI_TELLS}
`;
}

function createNewTrackMultiVersePrompt(
  track: string,
  verses: SelectedVerse[],
  formattedDate: string,
  holiday: Holiday | null
): string {
  const versesList = verses
    .map((v) => `- ${v.book} ${v.chapter}:${v.verse} — "${v.text}"`)
    .join("\n");
  const versesBlockquote = verses
    .map((v) => `> *"${v.text}"*\n> **${v.book} ${v.chapter}:${v.verse}**`)
    .join("\n>\n");
  const refs = verses
    .map((v) => `${v.book} ${v.chapter}:${v.verse}`)
    .join(", ");
  return `${PROMPT_INTRO}

VERSES (weave these together — do not treat them as a list)
${versesList}

DATE
${formattedDate}
${holiday ? holidayPromptSection(holiday) : ""}
${PROMPT_THEOLOGY_GUARDRAILS}

${newTrackRules(track)}

MULTI-VERSE NOTE
Find the single thread running through these passages and follow it. Do not walk them one at a
time; the devotional should read as one movement that happens to draw on several texts.

MARKDOWN OUTPUT (use exactly this skeleton; copy the verse texts verbatim)

${newTrackSkeleton(track, refs, versesBlockquote, formattedDate)}

${PROMPT_AI_TELLS}
`;
}

const PROMPT_VERSION_BY_TRACK: Record<Track, string> = {
  empathy: EMPATHY_PROMPT_VERSION,
  technical: TECHNICAL_PROMPT_VERSION,
  narrative: NARRATIVE_PROMPT_VERSION,
  practical: PRACTICAL_PROMPT_VERSION,
  matt: MATT_PROMPT_VERSION,
  josh: JOSH_PROMPT_VERSION,
  lament: LAMENT_PROMPT_VERSION,
  question: QUESTION_PROMPT_VERSION,
  character: CHARACTER_PROMPT_VERSION,
};

function buildSinglePrompt(
  track: Track,
  verse: SelectedVerse,
  formattedDate: string,
  holiday: Holiday | null,
): string {
  switch (track) {
    case "empathy": return createPrompt(verse, formattedDate, holiday);
    case "technical": return createTechnicalPrompt(verse, formattedDate, holiday);
    case "narrative": return createNarrativePrompt(verse, formattedDate, holiday);
    case "practical": return createPracticalPrompt(verse, formattedDate, holiday);
    default: return createNewTrackPrompt(track, verse, formattedDate, holiday);
  }
}

function buildMultiPrompt(
  track: Track,
  verses: SelectedVerse[],
  formattedDate: string,
  holiday: Holiday | null,
): string {
  switch (track) {
    case "empathy": return createMultiVersePrompt(verses, formattedDate, holiday);
    case "technical": return createTechnicalMultiVersePrompt(verses, formattedDate, holiday);
    case "narrative": return createNarrativeMultiVersePrompt(verses, formattedDate, holiday);
    case "practical": return createPracticalMultiVersePrompt(verses, formattedDate, holiday);
    default: return createNewTrackMultiVersePrompt(track, verses, formattedDate, holiday);
  }
}

function nextTrack(prev: string | null | undefined): Track {
  if (!prev) return TRACK_CYCLE[0];
  const idx = TRACK_CYCLE.indexOf(prev as Track);
  if (idx === -1) return TRACK_CYCLE[0];
  return TRACK_CYCLE[(idx + 1) % TRACK_CYCLE.length];
}

async function determineDevotionalType(
  supabase: ReturnType<typeof createClient>,
  today: Date,
  holiday: Holiday | null
): Promise<{
  type: "single" | "multi";
  targetTestament: "old" | "new";
  track: Track;
}> {
  // Walk back up to 7 days looking for the most recent AI-generated row
  // (one with a non-null track). Custom Sunday rows don't advance the
  // track cycle — we resume from the previous AI day's track.
  let mostRecentTrack: string | null = null;
  for (let daysBack = 1; daysBack <= 7 && mostRecentTrack === null; daysBack++) {
    const day = addDays(today, -daysBack);
    const dayStr = day.toISOString().split("T")[0];
    try {
      const { data } = await supabase
        .from("Daily Devotional")
        .select("track")
        .eq("for_date", dayStr)
        .maybeSingle();
      if (data?.track) mostRecentTrack = data.track as string;
    } catch {
      // ignore lookup errors and keep walking
    }
  }
  const track = nextTrack(mostRecentTrack);
  console.log(`Track cycle: prev=${mostRecentTrack ?? "none"}, next=${track}`);

  // Holidays: pick one curated verse (single-verse devotional)
  if (holiday) {
    const randomVerse = holiday.verses[Math.floor(Math.random() * holiday.verses.length)];
    return { type: "single", targetTestament: randomVerse.testament, track };
  }

  // Check yesterday's devotional for type/testament rotation: old single → new single → multi → repeat
  const yesterday = addDays(today, -1);
  const yesterdayStr = yesterday.toISOString().split("T")[0];

  try {
    const { data, error } = await supabase
      .from("Daily Devotional")
      .select("testament, devotional_type")
      .eq("for_date", yesterdayStr)
      .single();

    if (error || !data) {
      return { type: "single", targetTestament: "old", track };
    }

    const prevType = data.devotional_type || "single";
    const prevTestament = data.testament as "old" | "new";

    if (prevType === "multi") {
      return { type: "single", targetTestament: "old", track };
    } else if (prevTestament === "old") {
      return { type: "single", targetTestament: "new", track };
    } else {
      return {
        type: "multi",
        targetTestament: Math.random() < 0.5 ? "old" : "new",
        track,
      };
    }
  } catch {
    return { type: "single", targetTestament: "old", track };
  }
}

interface ThemeMetadata {
  holidayName?: string | null;
  holidayUrl?: string | null;
  anchorVerse?: string | null;
}

interface PromptCapture {
  prompt: string;
  version: string;
  track: string;
  verseSelectionPrompt: string | null;
}

async function saveDevotional(
  supabase: ReturnType<typeof createClient>,
  message: string,
  forDate: string,
  testament: string,
  devotionalType: string,
  verses: SelectedVerse[],
  model: string,
  usage: DevotionalUsage,
  promptCapture: PromptCapture,
  themeMetadata: ThemeMetadata = {}
): Promise<void> {
  const versesJson = verses.map((v) => ({
    book: v.book,
    chapter: v.chapter,
    verse: v.verse,
    testament: v.testament,
  }));
  const { error } = await supabase
    .from("Daily Devotional")
    .upsert(
      {
        message,
        for_date: forDate,
        testament,
        devotional_type: devotionalType,
        verses: versesJson,
        model,
        usage,
        prompt: promptCapture.prompt,
        prompt_version: promptCapture.version,
        track: promptCapture.track,
        verse_selection_prompt: promptCapture.verseSelectionPrompt,
        holiday_name: themeMetadata.holidayName ?? null,
        holiday_url: themeMetadata.holidayUrl ?? null,
        anchor_verse: themeMetadata.anchorVerse ?? null,
      },
      { onConflict: "for_date" }
    );
  if (error) throw error;
}

async function fetchExistingDevotional(
  supabase: ReturnType<typeof createClient>,
  forDate: string
): Promise<string | null> {
  const { data, error } = await supabase
    .from("Daily Devotional")
    .select("message")
    .eq("for_date", forDate)
    .maybeSingle();

  if (error) {
    console.warn(
      `[daily-devotional] cache lookup failed for ${forDate}; falling through to generation`,
      error,
    );
    return null;
  }
  return data?.message ?? null;
}

// ─── Main handler ───────────────────────────────────────────────────

initSentry("daily-devotional");

Deno.serve(async (req) => {
  // The shared secret is stored on the function as `SUPER_SECRET`. The caller
  // (daily cron) sends it in the `SuperSecret` header. Reading any other env
  // name leaves configuredSecret empty and 403s every request.
  const configuredSecret = Deno.env.get("SUPER_SECRET") ?? "";
  const providedSecret = req.headers.get("SuperSecret") ?? "";

  if (!configuredSecret || providedSecret !== configuredSecret) {
    return new Response(JSON.stringify({ error: "Forbidden" }), {
      status: 403,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const supabase = createSupabaseClient();

    // Optional body params:
    //   forDate (YYYY-MM-DD) — generate for a specific date; useful for
    //     testing or backfilling. Falls back to current date if absent.
    //   force (boolean) — when true, skip the existing-row check and
    //     regenerate even if a devotional already exists for the date.
    //     The upsert (onConflict: for_date) replaces the prior row.
    //     Useful when iterating on prompts.
    let targetDate = new Date();
    let force = false;
    try {
      const body = await req.json();
      if (typeof body?.forDate === "string" && body.forDate.length > 0) {
        const parsed = new Date(`${body.forDate}T00:00:00Z`);
        if (Number.isNaN(parsed.getTime())) {
          return new Response(
            JSON.stringify({ error: `Invalid forDate: ${body.forDate}` }),
            { status: 400, headers: { "Content-Type": "application/json" } }
          );
        }
        targetDate = parsed;
        console.log(`forDate override: ${body.forDate}`);
      }
      if (body?.force === true) {
        force = true;
        console.log("force=true: regenerating even if row exists");
      }
    } catch (_) {
      // Empty body or non-JSON is fine — fall back to current date.
    }

    const today = targetDate;
    const { formatted, isoDate } = getFormattedDate(targetDate);

    if (!force) {
      const existingDevotional = await fetchExistingDevotional(supabase, isoDate);
      if (existingDevotional) {
        console.log(`Devotional already exists for ${isoDate}; returning cached content.`);
        return new Response(existingDevotional, {
          headers: { "Content-Type": "text/plain" },
        });
      }
    }

    // Check for holiday
    const holiday = getHoliday(today);
    if (holiday) {
      console.log(`Holiday detected: ${holiday.name}`);
    }

    // Determine devotional type, testament, and track for this row.
    // Three independent cycles run together:
    //   - type/testament: old single → new single → multi → repeat
    //   - track:          empathy → technical → narrative → practical → repeat (round-robin via TRACK_CYCLE)
    //   - holidays override type to single, but still advance the track cycle
    const { type: devotionalType, targetTestament, track } =
      await determineDevotionalType(supabase, today, holiday);
    const promptVersion = PROMPT_VERSION_BY_TRACK[track];
    console.log(
      `Devotional type: ${devotionalType}, testament: ${targetTestament}, track: ${track} (${promptVersion})`
    );

    // Select verse(s) and create prompt
    let prompt: string;
    let verseSelectionPrompt: string | null = null;
    let versesUsed: SelectedVerse[];
    let selectionUsage: TokenUsage | undefined;

    if (devotionalType === "multi") {
      // Non-holiday multi-verse: random seed + GPT companion
      const { verses: verseRefs, usage, prompt: selPrompt } =
        await selectMultiVerses(2, null);
      selectionUsage = usage;
      verseSelectionPrompt = selPrompt;

      versesUsed = verseRefs.map((ref) => {
        const text = lookupVerseText(ref.book, ref.chapter, ref.verse);
        const isOT = OT_BOOKS.some((b) => b.name === ref.book);
        return {
          book: ref.book,
          chapter: ref.chapter,
          verse: ref.verse,
          text: text || `[${ref.book} ${ref.chapter}:${ref.verse}]`,
          testament: isOT ? ("old" as const) : ("new" as const),
        };
      });

      prompt = buildMultiPrompt(track, versesUsed, formatted, holiday);
    } else {
      const verse = selectVerse(targetTestament, holiday);
      // Resolve exact text from bible.json for holiday verses
      if (holiday) {
        const resolvedText = lookupVerseText(
          verse.book,
          verse.chapter,
          verse.verse
        );
        if (resolvedText) verse.text = resolvedText;
      }
      versesUsed = [verse];
      prompt = buildSinglePrompt(track, verse, formatted, holiday);
    }

    console.log(
      `Verses: ${versesUsed.map((v) => `${v.book} ${v.chapter}:${v.verse}`).join(", ")}`
    );

    // Generate devotional
    const { message: devotional, usage: generationUsage } =
      await generateDevotional(prompt);
    console.log("Generated Devotional:\n", devotional);

    const devotionalUsage: DevotionalUsage = {
      generation: generationUsage,
      ...(selectionUsage ? { selection: selectionUsage } : {}),
    };

    // Theme metadata for the iOS app's "why am I seeing this?" display.
    // Holidays get name + Wikipedia URL; single AI devotionals get the
    // seed verse so the reader can tap through to it.
    const themeMetadata: ThemeMetadata = holiday
      ? { holidayName: holiday.name, holidayUrl: holiday.wikipediaUrl ?? null }
      : devotionalType === "single" && versesUsed.length > 0
        ? { anchorVerse: `${versesUsed[0].book} ${versesUsed[0].chapter}:${versesUsed[0].verse}` }
        : {};

    // Save to database
    await saveDevotional(
      supabase,
      devotional,
      isoDate,
      targetTestament,
      devotionalType,
      versesUsed,
      DEVOTIONAL_MODEL,
      devotionalUsage,
      {
        prompt,
        version: promptVersion,
        track,
        verseSelectionPrompt,
      },
      themeMetadata
    );

    return new Response(devotional, {
      headers: { "Content-Type": "text/plain" },
    });
  } catch (error) {
    console.error("[daily-devotional] handler error", error);
    await captureException(error, { functionName: "daily-devotional" });
    return new Response(JSON.stringify({ error: "Failed to generate devotional" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/daily-devotional' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
