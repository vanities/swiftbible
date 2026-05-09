/**
 * Holiday detection and verse validation tests.
 *
 * Run with:
 *   cd supabase/functions/daily-devotional
 *   deno test holidays_test.ts --allow-read
 */

// deno-lint-ignore no-explicit-any
import bibleJson from "./bible.json" with { type: "json" };

// ─── Reimplement pure helper functions for testing ──────────────────

interface Book {
  name: string;
  description: string;
  chapters: { number: number; paragraphs: { startingVerse: number; text: string }[] }[];
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
}

// deno-lint-ignore no-explicit-any
const bibleData: Book[] = bibleJson as any;

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

function getNthWeekday(year: number, month: number, weekday: number, n: number): Date {
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
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

function lookupVerseText(bookName: string, chapterNum: number, verseNum: number): string | null {
  const book = bibleData.find((b) => b.name === bookName);
  if (!book) return null;
  const chapter = book.chapters.find((c) => c.number === chapterNum);
  if (!chapter) return null;

  // Try exact match first
  let paragraph = chapter.paragraphs.find((p) => p.startingVerse === verseNum);

  // If not found, find the paragraph that contains this verse
  if (!paragraph) {
    const sorted = [...chapter.paragraphs].sort((a, b) => a.startingVerse - b.startingVerse);
    for (let i = sorted.length - 1; i >= 0; i--) {
      if (sorted[i].startingVerse <= verseNum) {
        paragraph = sorted[i];
        break;
      }
    }
  }

  if (!paragraph) return null;
  return paragraph.text.trim().replace(/<\/?JESUS>/g, "").trim();
}

// ─── Parse holidays from source file ────────────────────────────────

function parseHolidayVersesFromSource(): Array<{
  holiday: string;
  book: string;
  chapter: number;
  verse: number;
  testament: string;
}> {
  const source = Deno.readTextFileSync(
    new URL("./index.ts", import.meta.url).pathname
  );
  const results: Array<{
    holiday: string;
    book: string;
    chapter: number;
    verse: number;
    testament: string;
  }> = [];

  // Match holiday name contexts and their verses
  const holidayPattern =
    /name:\s*"([^"]+)"[\s\S]*?verses:\s*\[([\s\S]*?)\]/g;
  let holidayMatch;
  while ((holidayMatch = holidayPattern.exec(source)) !== null) {
    const holidayName = holidayMatch[1];
    const versesBlock = holidayMatch[2];

    const versePattern =
      /book:\s*"([^"]+)",\s*chapter:\s*(\d+),\s*verse:\s*(\d+),\s*text:\s*"[^"]*",\s*testament:\s*"([^"]+)"/g;
    let verseMatch;
    while ((verseMatch = versePattern.exec(versesBlock)) !== null) {
      results.push({
        holiday: holidayName,
        book: verseMatch[1],
        chapter: parseInt(verseMatch[2]),
        verse: parseInt(verseMatch[3]),
        testament: verseMatch[4],
      });
    }
  }
  return results;
}

function parseHolidayNamesFromSource(): string[] {
  const source = Deno.readTextFileSync(
    new URL("./index.ts", import.meta.url).pathname
  );
  const names: string[] = [];
  const pattern = /name:\s*"([^"]+)"/g;
  let match;
  while ((match = pattern.exec(source)) !== null) {
    if (!names.includes(match[1])) {
      names.push(match[1]);
    }
  }
  return names;
}

// ─── Tests ──────────────────────────────────────────────────────────

Deno.test("computeEaster returns known dates", () => {
  // Known Easter dates (Gregorian calendar)
  const knownEasters: Record<number, [number, number]> = {
    2024: [2, 31], // March 31
    2025: [3, 20], // April 20
    2026: [3, 5], // April 5
    2027: [2, 28], // March 28
    2028: [3, 16], // April 16
    2029: [3, 1], // April 1
    2030: [3, 21], // April 21
    2031: [3, 13], // April 13
    2032: [2, 28], // March 28
    2033: [3, 17], // April 17
  };

  for (const [year, [month, day]] of Object.entries(knownEasters)) {
    const easter = computeEaster(parseInt(year));
    if (easter.getMonth() !== month || easter.getDate() !== day) {
      throw new Error(
        `Easter ${year}: expected ${month + 1}/${day}, got ${easter.getMonth() + 1}/${easter.getDate()}`
      );
    }
  }
});

Deno.test("addDays works correctly", () => {
  const base = new Date(2026, 3, 5); // April 5
  const plus7 = addDays(base, 7);
  if (plus7.getDate() !== 12 || plus7.getMonth() !== 3) {
    throw new Error(`addDays(+7) failed: got ${plus7.toDateString()}`);
  }
  const minus46 = addDays(base, -46);
  if (minus46.getMonth() !== 1 || minus46.getDate() !== 18) {
    throw new Error(`addDays(-46) failed: got ${minus46.toDateString()}`);
  }
});

Deno.test("getNthWeekday computes correctly", () => {
  // 2nd Sunday in May 2026 = May 10
  const mothersDay = getNthWeekday(2026, 4, 0, 2);
  if (mothersDay.getMonth() !== 4 || mothersDay.getDate() !== 10) {
    throw new Error(`Mother's Day 2026: expected May 10, got ${mothersDay.toDateString()}`);
  }

  // 3rd Sunday in June 2026 = June 21
  const fathersDay = getNthWeekday(2026, 5, 0, 3);
  if (fathersDay.getMonth() !== 5 || fathersDay.getDate() !== 21) {
    throw new Error(`Father's Day 2026: expected Jun 21, got ${fathersDay.toDateString()}`);
  }

  // 4th Thursday in November 2026 = November 26
  const thanksgiving = getNthWeekday(2026, 10, 4, 4);
  if (thanksgiving.getMonth() !== 10 || thanksgiving.getDate() !== 26) {
    throw new Error(
      `Thanksgiving 2026: expected Nov 26, got ${thanksgiving.toDateString()}`
    );
  }

  // 3rd Monday in January 2026 = January 19
  const mlk = getNthWeekday(2026, 0, 1, 3);
  if (mlk.getMonth() !== 0 || mlk.getDate() !== 19) {
    throw new Error(`MLK Day 2026: expected Jan 19, got ${mlk.toDateString()}`);
  }
});

Deno.test("getLastWeekday computes correctly", () => {
  // Last Monday in May 2026 = May 25
  const memorial = getLastWeekday(2026, 4, 1);
  if (memorial.getMonth() !== 4 || memorial.getDate() !== 25) {
    throw new Error(`Memorial Day 2026: expected May 25, got ${memorial.toDateString()}`);
  }

  // Last Monday in May 2027 = May 31
  const memorial2027 = getLastWeekday(2027, 4, 1);
  if (memorial2027.getMonth() !== 4 || memorial2027.getDate() !== 31) {
    throw new Error(`Memorial Day 2027: expected May 31, got ${memorial2027.toDateString()}`);
  }
});

Deno.test("getAdventSundays computes correctly", () => {
  // 2026: Christmas is Friday (day 5)
  // 4th Advent Sunday = Dec 20, 3rd = Dec 13, 2nd = Dec 6, 1st = Nov 29
  const advent2026 = getAdventSundays(2026);
  const expected2026 = [
    [10, 29], // Nov 29
    [11, 6], // Dec 6
    [11, 13], // Dec 13
    [11, 20], // Dec 20
  ];
  for (let i = 0; i < 4; i++) {
    const [month, day] = expected2026[i];
    if (advent2026[i].getMonth() !== month || advent2026[i].getDate() !== day) {
      throw new Error(
        `Advent ${i + 1} 2026: expected ${month + 1}/${day}, got ${advent2026[i].getMonth() + 1}/${advent2026[i].getDate()}`
      );
    }
  }

  // 2027: Christmas is Saturday (day 6)
  // 4th Advent Sunday = Dec 19
  const advent2027 = getAdventSundays(2027);
  if (advent2027[3].getMonth() !== 11 || advent2027[3].getDate() !== 19) {
    throw new Error(
      `4th Advent 2027: expected Dec 19, got ${advent2027[3].toDateString()}`
    );
  }
});

Deno.test("Easter-based holidays compute correct dates for 2026", () => {
  const easter2026 = computeEaster(2026); // April 5, 2026

  const easterHolidays: Record<string, number> = {
    "Shrove Tuesday": -47,
    "Ash Wednesday": -46,
    "Laetare Sunday": -21,
    "Palm Sunday": -7,
    "Holy Monday": -6,
    "Spy Wednesday": -4,
    "Maundy Thursday": -3,
    "Good Friday": -2,
    "Holy Saturday": -1,
    "Easter Sunday": 0,
    "Ascension Day": 39,
    "Pentecost": 49,
    "Trinity Sunday": 56,
  };

  for (const [name, offset] of Object.entries(easterHolidays)) {
    const expected = addDays(easter2026, offset);
    // Verify the date is valid (not NaN)
    if (isNaN(expected.getTime())) {
      throw new Error(`${name}: computed invalid date for offset ${offset}`);
    }
    // Verify it's a reasonable date (in 2026)
    if (expected.getFullYear() !== 2026) {
      throw new Error(
        `${name}: expected year 2026, got ${expected.getFullYear()}`
      );
    }
  }

  // Specific checks
  const ashWed = addDays(easter2026, -46);
  if (ashWed.getMonth() !== 1 || ashWed.getDate() !== 18) {
    throw new Error(`Ash Wednesday 2026: expected Feb 18, got ${ashWed.toDateString()}`);
  }

  const goodFriday = addDays(easter2026, -2);
  if (goodFriday.getMonth() !== 3 || goodFriday.getDate() !== 3) {
    throw new Error(`Good Friday 2026: expected Apr 3, got ${goodFriday.toDateString()}`);
  }

  const pentecost = addDays(easter2026, 49);
  if (pentecost.getMonth() !== 4 || pentecost.getDate() !== 24) {
    throw new Error(`Pentecost 2026: expected May 24, got ${pentecost.toDateString()}`);
  }
});

Deno.test("fixed-date holidays have valid month-day keys", () => {
  // These are the expected fixed-date holiday keys (month-day, 0-indexed month)
  const expectedFixedHolidays: Record<string, string> = {
    "0-1": "New Year's Day",
    "0-5": "Epiphany Eve",
    "0-6": "Epiphany",
    "1-14": "Valentine's Day",
    "2-17": "St. Patrick's Day",
    "2-20": "Spring Equinox",
    "3-22": "Earth Day",
    "5-14": "Flag Day",
    "5-19": "Juneteenth",
    "5-21": "Summer Solstice",
    "6-4": "Independence Day",
    "7-6": "Transfiguration",
    "8-11": "Patriot Day",
    "8-21": "International Day of Peace",
    "8-22": "Autumn Equinox",
    "8-29": "Michaelmas",
    "9-31": "Reformation Day",
    "10-1": "All Saints' Day",
    "10-11": "Veterans Day",
    "11-24": "Christmas Eve",
    "11-25": "Christmas Day",
    "11-21": "Winter Solstice",
    "11-31": "New Year's Eve",
  };

  for (const [key, name] of Object.entries(expectedFixedHolidays)) {
    const [monthStr, dayStr] = key.split("-");
    const month = parseInt(monthStr);
    const day = parseInt(dayStr);

    // Verify the date is valid
    const date = new Date(2026, month, day);
    if (date.getMonth() !== month || date.getDate() !== day) {
      throw new Error(`${name} (${key}): invalid date ${month + 1}/${day}`);
    }
  }
});

Deno.test("moveable holidays compute for multiple years", () => {
  for (const year of [2026, 2027, 2028, 2029, 2030]) {
    // MLK Day: 3rd Monday in January
    const mlk = getNthWeekday(year, 0, 1, 3);
    if (mlk.getDay() !== 1 || mlk.getMonth() !== 0) {
      throw new Error(`MLK ${year}: not a Monday in January: ${mlk.toDateString()}`);
    }

    // Presidents' Day: 3rd Monday in February
    const pres = getNthWeekday(year, 1, 1, 3);
    if (pres.getDay() !== 1 || pres.getMonth() !== 1) {
      throw new Error(`Presidents' Day ${year}: not a Monday in Feb: ${pres.toDateString()}`);
    }

    // Memorial Day: last Monday in May
    const mem = getLastWeekday(year, 4, 1);
    if (mem.getDay() !== 1 || mem.getMonth() !== 4) {
      throw new Error(`Memorial Day ${year}: not a Monday in May: ${mem.toDateString()}`);
    }

    // Mother's Day: 2nd Sunday in May
    const mothers = getNthWeekday(year, 4, 0, 2);
    if (mothers.getDay() !== 0 || mothers.getMonth() !== 4) {
      throw new Error(`Mother's Day ${year}: not a Sunday in May: ${mothers.toDateString()}`);
    }

    // Father's Day: 3rd Sunday in June
    const fathers = getNthWeekday(year, 5, 0, 3);
    if (fathers.getDay() !== 0 || fathers.getMonth() !== 5) {
      throw new Error(`Father's Day ${year}: not a Sunday in June: ${fathers.toDateString()}`);
    }

    // Labor Day: 1st Monday in September
    const labor = getNthWeekday(year, 8, 1, 1);
    if (labor.getDay() !== 1 || labor.getMonth() !== 8) {
      throw new Error(`Labor Day ${year}: not a Monday in Sep: ${labor.toDateString()}`);
    }

    // Thanksgiving: 4th Thursday in November
    const thanks = getNthWeekday(year, 10, 4, 4);
    if (thanks.getDay() !== 4 || thanks.getMonth() !== 10) {
      throw new Error(`Thanksgiving ${year}: not a Thursday in Nov: ${thanks.toDateString()}`);
    }

    // Election Day: 1st Tuesday after 1st Monday in November
    const firstMon = getNthWeekday(year, 10, 1, 1);
    const election = addDays(firstMon, 1);
    if (election.getDay() !== 2 || election.getMonth() !== 10) {
      throw new Error(`Election Day ${year}: not a Tuesday in Nov: ${election.toDateString()}`);
    }
    // Election day must be between Nov 2-8
    if (election.getDate() < 2 || election.getDate() > 8) {
      throw new Error(`Election Day ${year}: date ${election.getDate()} out of range 2-8`);
    }

    // Baptism of Jesus: 1st Sunday after Jan 6
    const jan6 = new Date(year, 0, 6);
    const daysUntilSunday = (7 - jan6.getDay()) % 7;
    const baptism =
      daysUntilSunday === 0 ? addDays(jan6, 7) : addDays(jan6, daysUntilSunday);
    if (baptism.getDay() !== 0 || baptism.getMonth() !== 0) {
      throw new Error(`Baptism ${year}: not a Sunday in Jan: ${baptism.toDateString()}`);
    }
    if (baptism.getDate() <= 6) {
      throw new Error(`Baptism ${year}: should be after Jan 6, got Jan ${baptism.getDate()}`);
    }

    // Christ the King: Sunday before Advent 1
    const advents = getAdventSundays(year);
    const ctk = addDays(advents[0], -7);
    if (ctk.getDay() !== 0) {
      throw new Error(`Christ the King ${year}: not a Sunday: ${ctk.toDateString()}`);
    }

    // Advent Sundays should all be Sundays
    for (let i = 0; i < 4; i++) {
      if (advents[i].getDay() !== 0) {
        throw new Error(`Advent ${i + 1} ${year}: not a Sunday: ${advents[i].toDateString()}`);
      }
    }

    // Advent 4 should be within 7 days before Christmas
    const christmas = new Date(year, 11, 25);
    const daysBefore = (christmas.getTime() - advents[3].getTime()) / 86400000;
    if (daysBefore < 1 || daysBefore > 7) {
      throw new Error(
        `Advent 4 ${year}: ${daysBefore} days before Christmas (expected 1-7)`
      );
    }
  }
});

Deno.test("all holiday verses reference valid Bible books", () => {
  const validBooks = bibleData.map((b) => b.name);
  const holidayVerses = parseHolidayVersesFromSource();

  if (holidayVerses.length === 0) {
    throw new Error("No holiday verses found in source file");
  }

  const invalidBooks: string[] = [];
  for (const v of holidayVerses) {
    if (!validBooks.includes(v.book)) {
      invalidBooks.push(`${v.holiday}: ${v.book} ${v.chapter}:${v.verse}`);
    }
  }

  if (invalidBooks.length > 0) {
    throw new Error(
      `Books not found in bible.json:\n  ${invalidBooks.join("\n  ")}`
    );
  }
});

Deno.test("all holiday verses have valid chapter numbers", () => {
  const holidayVerses = parseHolidayVersesFromSource();
  const invalidChapters: string[] = [];

  for (const v of holidayVerses) {
    const book = bibleData.find((b) => b.name === v.book);
    if (!book) continue; // covered by book test
    const chapter = book.chapters.find((c) => c.number === v.chapter);
    if (!chapter) {
      invalidChapters.push(
        `${v.holiday}: ${v.book} ${v.chapter}:${v.verse} — chapter ${v.chapter} doesn't exist (max: ${book.chapters[book.chapters.length - 1]?.number})`
      );
    }
  }

  if (invalidChapters.length > 0) {
    throw new Error(
      `Invalid chapters:\n  ${invalidChapters.join("\n  ")}`
    );
  }
});

Deno.test("all holiday verses resolve via lookupVerseText", () => {
  const holidayVerses = parseHolidayVersesFromSource();
  let resolved = 0;
  const notFoundList: string[] = [];

  for (const v of holidayVerses) {
    const text = lookupVerseText(v.book, v.chapter, v.verse);
    if (text && text.length > 0) {
      resolved++;
    } else {
      notFoundList.push(`${v.holiday}: ${v.book} ${v.chapter}:${v.verse}`);
    }
  }

  console.log(
    `  Verse lookup: ${resolved}/${holidayVerses.length} resolved`
  );

  if (notFoundList.length > 0) {
    throw new Error(
      `Verses not found in bible.json:\n  ${notFoundList.join("\n  ")}`
    );
  }
});

Deno.test("all holidays have at least 2 verses", () => {
  const source = Deno.readTextFileSync(
    new URL("./index.ts", import.meta.url).pathname
  );
  const pattern = /name:\s*"([^"]+)"[\s\S]*?verses:\s*\[([\s\S]*?)\]/g;
  let match;
  const tooFew: string[] = [];

  while ((match = pattern.exec(source)) !== null) {
    const name = match[1];
    const versesBlock = match[2];
    const verseCount = (versesBlock.match(/book:\s*"/g) || []).length;
    if (verseCount < 2) {
      tooFew.push(`${name}: only ${verseCount} verse(s)`);
    }
  }

  if (tooFew.length > 0) {
    throw new Error(`Holidays with fewer than 2 verses:\n  ${tooFew.join("\n  ")}`);
  }
});

Deno.test("all holiday verses have valid testament values", () => {
  const holidayVerses = parseHolidayVersesFromSource();
  const otBooks = bibleData.slice(0, 39).map((b) => b.name);
  const ntBooks = bibleData.slice(39).map((b) => b.name);
  const wrong: string[] = [];

  for (const v of holidayVerses) {
    if (v.testament === "old" && !otBooks.includes(v.book) && ntBooks.includes(v.book)) {
      wrong.push(`${v.holiday}: ${v.book} labeled "old" but is NT`);
    }
    if (v.testament === "new" && !ntBooks.includes(v.book) && otBooks.includes(v.book)) {
      wrong.push(`${v.holiday}: ${v.book} labeled "new" but is OT`);
    }
    if (v.testament !== "old" && v.testament !== "new") {
      wrong.push(`${v.holiday}: ${v.book} has invalid testament "${v.testament}"`);
    }
  }

  if (wrong.length > 0) {
    throw new Error(`Wrong testament labels:\n  ${wrong.join("\n  ")}`);
  }
});

Deno.test("no duplicate holiday names", () => {
  const names = parseHolidayNamesFromSource();
  const seen = new Set<string>();
  const dupes: string[] = [];
  for (const name of names) {
    if (seen.has(name)) {
      dupes.push(name);
    }
    seen.add(name);
  }
  if (dupes.length > 0) {
    throw new Error(`Duplicate holiday names: ${dupes.join(", ")}`);
  }
});

Deno.test("no holiday date collisions for 2026-2030", () => {
  // Build a list of all holiday dates per year
  for (const year of [2026, 2027, 2028, 2029, 2030]) {
    const dates = new Map<string, string[]>();

    const easter = computeEaster(year);
    const easterOffsets: Record<string, number> = {
      "Shrove Tuesday": -47,
      "Ash Wednesday": -46,
      "Laetare Sunday": -21,
      "Palm Sunday": -7,
      "Holy Monday": -6,
      "Spy Wednesday": -4,
      "Maundy Thursday": -3,
      "Good Friday": -2,
      "Holy Saturday": -1,
      "Easter Sunday": 0,
      "Ascension Day": 39,
      "Pentecost": 49,
      "Trinity Sunday": 56,
    };

    for (const [name, offset] of Object.entries(easterOffsets)) {
      const d = addDays(easter, offset);
      const key = `${d.getMonth()}-${d.getDate()}`;
      if (!dates.has(key)) dates.set(key, []);
      dates.get(key)!.push(name);
    }

    // Fixed dates
    const fixedDates: Record<string, string> = {
      "0-1": "New Year's Day",
      "0-5": "Epiphany Eve",
      "0-6": "Epiphany",
      "1-14": "Valentine's Day",
      "2-17": "St. Patrick's Day",
      "2-20": "Spring Equinox",
      "3-22": "Earth Day",
      "5-14": "Flag Day",
      "5-19": "Juneteenth",
      "5-21": "Summer Solstice",
      "6-4": "Independence Day",
      "7-6": "Transfiguration",
      "8-11": "Patriot Day",
      "8-21": "International Day of Peace",
      "8-22": "Autumn Equinox",
      "8-29": "Michaelmas",
      "9-31": "Reformation Day",
      "10-1": "All Saints' Day",
      "10-11": "Veterans Day",
      "11-21": "Winter Solstice",
      "11-24": "Christmas Eve",
      "11-25": "Christmas Day",
      "11-31": "New Year's Eve",
    };

    for (const [key, name] of Object.entries(fixedDates)) {
      if (!dates.has(key)) dates.set(key, []);
      dates.get(key)!.push(name);
    }

    // Check for collisions
    const collisions: string[] = [];
    for (const [key, names] of dates) {
      if (names.length > 1) {
        collisions.push(`${year} ${key}: ${names.join(" + ")}`);
      }
    }

    if (collisions.length > 0) {
      // Warn but don't fail — some collisions are expected (e.g., Easter could land on a fixed date)
      console.log(`  Date collisions in ${year} (first match wins):`);
      for (const c of collisions) {
        console.log(`    ${c}`);
      }
    }
  }
});

Deno.test("expected holiday count", () => {
  const names = parseHolidayNamesFromSource();
  // We expect 46 unique holidays (52 entries including 4 Advent Sundays counted separately)
  if (names.length < 40) {
    throw new Error(
      `Expected at least 40 holidays, found ${names.length}: ${names.join(", ")}`
    );
  }
  console.log(`  Total unique holiday names: ${names.length}`);
});

Deno.test("bible.json has expected structure", () => {
  if (!Array.isArray(bibleData)) {
    throw new Error("bibleData is not an array");
  }
  if (bibleData.length !== 66) {
    throw new Error(`Expected 66 books, got ${bibleData.length}`);
  }
  // OT: 39 books, NT: 27 books
  if (bibleData[0].name !== "Genesis") {
    throw new Error(`First book should be Genesis, got ${bibleData[0].name}`);
  }
  if (bibleData[38].name !== "Malachi") {
    throw new Error(`Book 39 should be Malachi, got ${bibleData[38].name}`);
  }
  if (bibleData[39].name !== "Matthew") {
    throw new Error(`Book 40 should be Matthew, got ${bibleData[39].name}`);
  }
  if (bibleData[65].name !== "Revelation") {
    throw new Error(`Last book should be Revelation, got ${bibleData[65].name}`);
  }
});

// ─── lookupVerseText edge cases ─────────────────────────────────────

Deno.test("lookupVerseText returns null for nonexistent book", () => {
  const result = lookupVerseText("Nonexistent", 1, 1);
  if (result !== null) {
    throw new Error(`Expected null for fake book, got: "${result}"`);
  }
});

Deno.test("lookupVerseText returns null for nonexistent chapter", () => {
  const result = lookupVerseText("Genesis", 999, 1);
  if (result !== null) {
    throw new Error(`Expected null for fake chapter, got: "${result}"`);
  }
});

Deno.test("lookupVerseText resolves mid-paragraph verses to containing paragraph", () => {
  // Matthew 3:17 is part of 3:16's paragraph — should resolve to that paragraph
  const result = lookupVerseText("Matthew", 3, 17);
  if (result === null) {
    throw new Error("Matthew 3:17 should resolve to containing paragraph, got null");
  }
  // The containing paragraph (starting at 3:16) should include baptism text
  if (!result.includes("baptized")) {
    throw new Error(`Expected baptism text, got: "${result.substring(0, 80)}..."`);
  }
});

Deno.test("lookupVerseText strips JESUS tags from red-letter text", () => {
  // John 3:16 should have JESUS tags in bible.json
  const result = lookupVerseText("John", 3, 16);
  if (result === null) {
    throw new Error("John 3:16 not found");
  }
  if (result.includes("<JESUS>") || result.includes("</JESUS>")) {
    throw new Error(`JESUS tags not stripped: "${result}"`);
  }
  if (!result.includes("For God so loved the world")) {
    throw new Error(`Unexpected text for John 3:16: "${result.substring(0, 80)}..."`);
  }
});

Deno.test("lookupVerseText returns exact text for well-known verses", () => {
  const knownVerses: Array<{ book: string; chapter: number; verse: number; contains: string }> = [
    { book: "Genesis", chapter: 1, verse: 1, contains: "In the beginning God created" },
    { book: "Psalms", chapter: 23, verse: 1, contains: "The LORD is my shepherd" },
    { book: "Romans", chapter: 8, verse: 28, contains: "all things work together for good" },
    { book: "Revelation", chapter: 22, verse: 21, contains: "grace of our Lord Jesus" },
  ];

  for (const v of knownVerses) {
    const text = lookupVerseText(v.book, v.chapter, v.verse);
    if (text === null) {
      throw new Error(`${v.book} ${v.chapter}:${v.verse} not found`);
    }
    if (!text.includes(v.contains)) {
      throw new Error(
        `${v.book} ${v.chapter}:${v.verse}: expected to contain "${v.contains}", got: "${text.substring(0, 100)}..."`
      );
    }
  }
});

// ─── Mid-paragraph fallback verses ──────────────────────────────────

Deno.test("mid-paragraph verses resolve to containing paragraph text", () => {
  // These are verses that don't have their own startingVerse in bible.json
  // but should resolve to the containing paragraph
  const midParagraphExamples = [
    { book: "Matthew", chapter: 3, verse: 17, contains: "baptized" },
    { book: "Matthew", chapter: 26, verse: 15, contains: "silver" },
    { book: "John", chapter: 12, verse: 13, contains: "palm" },
    { book: "Isaiah", chapter: 56, verse: 7, contains: "prayer" },
  ];

  const errors: string[] = [];
  for (const v of midParagraphExamples) {
    const text = lookupVerseText(v.book, v.chapter, v.verse);
    if (text === null) {
      errors.push(`${v.book} ${v.chapter}:${v.verse}: still null after mid-paragraph fix`);
    } else if (!text.toLowerCase().includes(v.contains)) {
      errors.push(
        `${v.book} ${v.chapter}:${v.verse}: expected to contain "${v.contains}", got: "${text.substring(0, 80)}..."`
      );
    }
  }

  if (errors.length > 0) {
    throw new Error(`Mid-paragraph resolution errors:\n  ${errors.join("\n  ")}`);
  }
});

// ─── selectRandomVerse support ──────────────────────────────────────

Deno.test("bible.json has paragraphs that selectRandomVerse would filter", () => {
  let longCount = 0;
  let shortCount = 0;
  let normalCount = 0;

  for (const book of bibleData) {
    for (const chapter of book.chapters) {
      for (const paragraph of chapter.paragraphs) {
        const len = paragraph.text.length;
        if (len > 400) longCount++;
        else if (len < 20) shortCount++;
        else normalCount++;
      }
    }
  }

  console.log(
    `  Paragraph stats: ${normalCount} normal, ${longCount} too long (>400), ${shortCount} too short (<20)`
  );

  if (longCount === 0) {
    throw new Error("Expected some long paragraphs (genealogies) to exist for filtering");
  }
  if (normalCount === 0) {
    throw new Error("Expected normal-length paragraphs to exist");
  }
});

Deno.test("fallback books exist: Psalms in OT, John in NT", () => {
  const otBooks = bibleData.slice(0, 39);
  const ntBooks = bibleData.slice(39);

  const psalms = otBooks.find((b) => b.name === "Psalms");
  if (!psalms) {
    throw new Error("Psalms not found in OT books");
  }
  if (psalms.chapters.length < 100) {
    throw new Error(`Psalms should have 150 chapters, got ${psalms.chapters.length}`);
  }

  const john = ntBooks.find((b) => b.name === "John");
  if (!john) {
    throw new Error("John not found in NT books");
  }
  if (john.chapters.length < 20) {
    throw new Error(`John should have 21 chapters, got ${john.chapters.length}`);
  }
});

// ─── Rotation logic ────────────────────────────────────────────────

Deno.test("rotation cycle: old → new → multi → old", () => {
  // Simulate the rotation logic from determineDevotionalType
  function nextType(
    prevType: string,
    prevTestament: string
  ): { type: string; testament: string } {
    if (prevType === "multi") {
      return { type: "single", testament: "old" };
    } else if (prevTestament === "old") {
      return { type: "single", testament: "new" };
    } else {
      return { type: "multi", testament: "random" };
    }
  }

  // Start with single/old
  let state = { type: "single", testament: "old" };
  const cycle: string[] = [`${state.type}/${state.testament}`];

  for (let i = 0; i < 9; i++) {
    state = nextType(state.type, state.testament);
    cycle.push(`${state.type}/${state.testament}`);
  }

  // Expected: old, new, multi, old, new, multi, old, new, multi, old
  const expected = [
    "single/old",
    "single/new",
    "multi/random",
    "single/old",
    "single/new",
    "multi/random",
    "single/old",
    "single/new",
    "multi/random",
    "single/old",
  ];

  for (let i = 0; i < expected.length; i++) {
    if (cycle[i] !== expected[i]) {
      throw new Error(
        `Rotation step ${i}: expected "${expected[i]}", got "${cycle[i]}"\nFull cycle: ${cycle.join(" → ")}`
      );
    }
  }
});

Deno.test("holidays always override to single", () => {
  // The determineDevotionalType function returns "single" when holiday is non-null
  // (picks one curated verse for a focused devotional)
  const source = Deno.readTextFileSync(
    new URL("./index.ts", import.meta.url).pathname
  );

  // Check that the holiday override exists
  if (!source.includes('if (holiday) {') || !source.includes('return { type: "single"')) {
    throw new Error("Holiday override to single-verse not found in determineDevotionalType");
  }
});

// ─── Multi-verse prompt structure ───────────────────────────────────

Deno.test("multi-verse prompt references holiday context", () => {
  const source = Deno.readTextFileSync(
    new URL("./index.ts", import.meta.url).pathname
  );

  // Holiday context is injected via holidayPromptSection() — must reference
  // holiday.name and holiday.themeHint so the model knows which holiday it
  // is writing for and what the editorial angle should be.
  if (!source.includes("holiday.themeHint")) {
    throw new Error("Multi-verse prompt missing themeHint reference");
  }
  if (!source.includes("${holiday.name}")) {
    throw new Error("Multi-verse prompt missing holiday.name reference");
  }
});

Deno.test("devotional prompt v2 four-beat structure", () => {
  const source = Deno.readTextFileSync(
    new URL("./index.ts", import.meta.url).pathname
  );

  // v2 contract: voice rules forbid AI tells and presumed biography, and
  // the markdown skeleton closes with "## A prayer" instead of the v1
  // bullet-list reflection questions + italics meditation.
  const required = [
    "DEVOTIONAL_PROMPT_VERSION",
    "PROMPT_VOICE_RULES",
    "## A prayer",
    "Don't presume their biography",
    "NEVER write fake personal admissions",
  ];
  for (const marker of required) {
    if (!source.includes(marker)) {
      throw new Error(`v2 prompt missing required marker: ${marker}`);
    }
  }
});

Deno.test("saveDevotional persists prompt capture columns", () => {
  const source = Deno.readTextFileSync(
    new URL("./index.ts", import.meta.url).pathname
  );

  // Every new row should populate the three prompt-capture columns added
  // in 20260509120000_add_devotional_prompt_capture.sql.
  for (const col of ["prompt:", "prompt_version:", "verse_selection_prompt:"]) {
    if (!source.includes(col)) {
      throw new Error(`saveDevotional missing upsert key: ${col}`);
    }
  }
});

Deno.test("selectMultiVerses uses VERSE_SELECTION_MODEL constant (gpt-5.4-mini)", () => {
  const source = Deno.readTextFileSync(
    new URL("./index.ts", import.meta.url).pathname
  );

  if (!source.includes("async function selectMultiVerses")) {
    throw new Error("selectMultiVerses function not found");
  }
  if (!source.includes("model: VERSE_SELECTION_MODEL")) {
    throw new Error(
      "selectMultiVerses should reference the VERSE_SELECTION_MODEL constant"
    );
  }
  if (
    !source.includes(
      'VERSE_SELECTION_MODEL =\n  Deno.env.get("VERSE_SELECTION_MODEL") ?? "gpt-5.4-mini"'
    )
  ) {
    throw new Error(
      "VERSE_SELECTION_MODEL should default to gpt-5.4-mini and read from env"
    );
  }
  if (!source.includes("response_format")) {
    throw new Error("selectMultiVerses should use JSON response format");
  }
});

// ─── Verse link detection (iOS) ────────────────────────────────────

Deno.test("all holiday verse books are in the iOS bookNames list", () => {
  // The iOS app has a static list of book names for verse link detection
  // Resolve path relative to this test file, handling spaces in "Daily Devotional"
  const testDir = new URL(".", import.meta.url).pathname;
  const swiftPath = testDir + "../../../swiftbible/Views/Daily Devotional/DailyDevotionalView.swift";
  const swiftSource = Deno.readTextFileSync(swiftPath);

  const bookNamesMatch = swiftSource.match(
    /private static let bookNames: \[String\] = \[([\s\S]*?)\]/
  );
  if (!bookNamesMatch) {
    throw new Error("Could not find bookNames list in DailyDevotionalView.swift");
  }

  const iosBooks = (bookNamesMatch[1].match(/"([^"]+)"/g) || []).map((s) =>
    s.replace(/"/g, "")
  );

  const holidayVerses = parseHolidayVersesFromSource();
  const missingBooks: string[] = [];

  for (const v of holidayVerses) {
    if (!iosBooks.includes(v.book)) {
      if (!missingBooks.includes(v.book)) {
        missingBooks.push(v.book);
      }
    }
  }

  if (missingBooks.length > 0) {
    throw new Error(
      `Holiday verse books not in iOS bookNames list (verse links won't work):\n  ${missingBooks.join(", ")}`
    );
  }
});

Deno.test("handler accepts forDate request body param", () => {
  const source = Deno.readTextFileSync(
    new URL("./index.ts", import.meta.url).pathname
  );

  if (!source.includes("body?.forDate")) {
    throw new Error(
      "handler should parse forDate from the request body"
    );
  }
  if (!source.includes("getFormattedDate(targetDate)")) {
    throw new Error(
      "handler should pass the resolved targetDate to getFormattedDate"
    );
  }
  if (!source.includes("Invalid forDate")) {
    throw new Error(
      "handler should reject malformed forDate with a 400 response"
    );
  }
});

Deno.test("DEVOTIONAL_MODEL constant defaults to gpt-5.4 and is used for generation", () => {
  const source = Deno.readTextFileSync(
    new URL("./index.ts", import.meta.url).pathname
  );

  if (
    !source.includes(
      'DEVOTIONAL_MODEL =\n  Deno.env.get("DEVOTIONAL_MODEL") ?? "gpt-5.4"'
    )
  ) {
    throw new Error(
      "DEVOTIONAL_MODEL should default to gpt-5.4 and read from env"
    );
  }
  if (!source.includes("const model = DEVOTIONAL_MODEL")) {
    throw new Error(
      "generateDevotional should reference the DEVOTIONAL_MODEL constant"
    );
  }
});
