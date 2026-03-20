// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

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
}

// ─── Load local KJV Bible data ──────────────────────────────────────

// deno-lint-ignore no-explicit-any
import bibleJson from "./bible.json" with { type: "json" };
const bibleData: Book[] = bibleJson as any;

const OT_BOOKS = bibleData.slice(0, 39);
const NT_BOOKS = bibleData.slice(39);

const OPENAI_CHAT_URL = "https://api.openai.com/v1/chat/completions";

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

function sameDay(a: Date, b: Date): boolean {
  return a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate();
}

// ─── Holiday calendar ───────────────────────────────────────────────

function getHoliday(date: Date): Holiday | null {
  const year = date.getFullYear();
  const month = date.getMonth(); // 0-indexed
  const day = date.getDate();

  // ── Easter-based moveable feasts ──
  const easter = computeEaster(year);
  const easterHolidays: Array<{ offset: number; holiday: Holiday }> = [
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

  return null;
}

// ─── Verse selection ────────────────────────────────────────────────

function selectRandomVerse(testament: "old" | "new"): SelectedVerse {
  const books = testament === "old" ? OT_BOOKS : NT_BOOKS;
  const maxAttempts = 10;

  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    const book = books[Math.floor(Math.random() * books.length)];
    const chapter =
      book.chapters[Math.floor(Math.random() * book.chapters.length)];
    const paragraph =
      chapter.paragraphs[
        Math.floor(Math.random() * chapter.paragraphs.length)
      ];

    // Skip very long paragraphs (genealogies, census lists)
    if (paragraph.text.length > 400) continue;
    // Skip very short paragraphs
    if (paragraph.text.trim().length < 20) continue;

    return {
      book: book.name,
      chapter: chapter.number,
      verse: paragraph.startingVerse,
      text: paragraph.text.trim(),
      testament,
    };
  }

  // Fallback: pick from Psalms (OT) or John (NT) — always devotional-worthy
  const fallbackBook = testament === "old"
    ? OT_BOOKS.find((b) => b.name === "Psalms")!
    : NT_BOOKS.find((b) => b.name === "John")!;
  const chapter =
    fallbackBook.chapters[
      Math.floor(Math.random() * fallbackBook.chapters.length)
    ];
  const paragraph =
    chapter.paragraphs[Math.floor(Math.random() * chapter.paragraphs.length)];

  return {
    book: fallbackBook.name,
    chapter: chapter.number,
    verse: paragraph.startingVerse,
    text: paragraph.text.trim(),
    testament,
  };
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

function getFormattedDate(): { formatted: string; isoDate: string } {
  const now = new Date();
  const formatted = now.toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
  const isoDate = now.toISOString().split("T")[0];
  return { formatted, isoDate };
}

// ─── Prompt creation ────────────────────────────────────────────────

function createPrompt(
  verse: SelectedVerse,
  formattedDate: string,
  holiday: Holiday | null
): string {
  const holidaySection = holiday
    ? `\n\nHoliday Context:\n${holiday.themeHint}\n`
    : "";

  return `
Create a daily devotional for a Bible app based on the following Bible verse from the King James Version (KJV):

${verse.book} ${verse.chapter}:${verse.verse} - "${verse.text}"

Date: ${formattedDate}
${holidaySection}
Devotional Guidelines:

1. Title as a Heading: Use # for the title at the very top. Include the date and passage reference in this title.${holiday ? ` Reference the holiday "${holiday.name}" in the title.` : ""}

2. Subtitle (Context Summary Only): Provide a **bolded thematic summary** line immediately below the title that captures the main theme. DO NOT include the date or passage reference in this subtitle - only the theological/spiritual theme.

Example Markdown Structure

# October 5 - 2 Kings 2:3: A Season of Transition and Readiness

**Elijah's departure and Elisha's readiness to assume responsibility**

> "And the sons of the prophets that were at Bethel came forth to Elisha, and said unto him, Knowest thou that the LORD will take away thy master from thy head to day? And he said, Yea, I know it; hold ye your peace."
> **2 Kings 2:3**

2. Verse Block Formatting:
   - Place the verse text directly beneath the title and summary in a Markdown blockquote (using >) for emphasis, like this:
     > "${verse.text}"
     > **${verse.book} ${verse.chapter}:${verse.verse}**

3. Devotional Content Formatting:
   - Contextual Background: Begin the devotional with a natural flow, integrating the verse's background, add explicit section headers with ##.
   - Historical and Cultural Insights: Incorporate historical or cultural context within the devotional narrative, providing any relevant customs, events, or traditions to enrich understanding.
   - Linguistic and Translational Insights: Include key Hebrew or Greek words with their meanings and any nuances, seamlessly embedded in the text, to deepen the reader's understanding of the verse's original intent.

4. Modern Relevance: Guide the reader to relate the passage to contemporary themes or challenges. Encourage them to see how the verse can be applied in their own lives, reflecting on universal themes like change, courage, or faithfulness.${holiday ? ` Connect the verse to the significance of ${holiday.name} in modern life.` : ""}

5. Personal Reflection and Application:
   - Include reflective questions or journaling prompts at the end of the devotional, formatted in Markdown as a list for easy reading.
   - Example:
     - How does this verse resonate with a current season of transition in your life?
     - In what ways can you embody the faith or courage exemplified in this passage today?

6. Final Meditation:
   - Close with a short meditation or prayerful reflection to invite the reader into a moment of contemplation. Format this as a final paragraph in italics.
`;
}

// ─── Devotional generation (OpenAI) ─────────────────────────────────

async function generateDevotional(prompt: string): Promise<string> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) throw new Error("Missing OPENAI_API_KEY env var");
  const model = "gpt-5-mini";

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
  const content = data?.choices?.[0]?.message?.content;
  if (typeof content === "string" && content.trim().length > 0) {
    return content.trim();
  }
  const alt = data?.choices?.[0]?.text;
  if (typeof alt === "string" && alt.trim().length > 0) {
    return alt.trim();
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

async function getYesterdayTestament(
  supabase: ReturnType<typeof createClient>,
  today: Date
): Promise<"old" | "new" | null> {
  const yesterday = addDays(today, -1);
  const yesterdayStr = yesterday.toISOString().split("T")[0];

  try {
    const { data, error } = await supabase
      .from("Daily Devotional")
      .select("testament")
      .eq("for_date", yesterdayStr)
      .single();

    if (error || !data?.testament) return null;
    return data.testament as "old" | "new";
  } catch {
    return null;
  }
}

async function saveDevotional(
  supabase: ReturnType<typeof createClient>,
  message: string,
  forDate: string,
  testament: string
): Promise<void> {
  const { error } = await supabase
    .from("Daily Devotional")
    .upsert(
      { message, for_date: forDate, testament },
      { onConflict: "for_date" }
    );
  if (error) throw error;
}

// ─── Main handler ───────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (Deno.env.get("SUPABASE_URL") == req.headers.get("SuperSecret")) {
    return { statusCode: 403, body: "External calls are not allowed" };
  }

  const supabase = createSupabaseClient();
  const today = new Date();
  const { formatted, isoDate } = getFormattedDate();

  // Check for holiday
  const holiday = getHoliday(today);
  if (holiday) {
    console.log(`Holiday detected: ${holiday.name}`);
  }

  // Determine target testament (alternate from yesterday)
  const yesterdayTestament = await getYesterdayTestament(supabase, today);
  let targetTestament: "old" | "new";

  if (holiday) {
    // For holidays, use the testament of the selected verse
    targetTestament = holiday.verses[0].testament;
  } else if (yesterdayTestament) {
    targetTestament = yesterdayTestament === "old" ? "new" : "old";
  } else {
    // Fallback: alternate by day-of-year
    const start = new Date(today.getFullYear(), 0, 0);
    const dayOfYear = Math.floor(
      (today.getTime() - start.getTime()) / 86400000
    );
    targetTestament = dayOfYear % 2 === 0 ? "old" : "new";
  }

  // Select verse
  const verse = selectVerse(targetTestament, holiday);
  console.log(
    `Selected Verse: ${verse.book} ${verse.chapter}:${verse.verse} (${verse.testament}) - ${verse.text.substring(0, 80)}`
  );

  // Generate devotional
  const prompt = createPrompt(verse, formatted, holiday);
  const devotional = await generateDevotional(prompt);
  console.log("Generated Devotional:\n", devotional);

  // Save to database
  await saveDevotional(supabase, devotional, isoDate, verse.testament);

  return new Response(devotional, {
    headers: { "Content-Type": "text/plain" },
  });
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/daily-devotional' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
