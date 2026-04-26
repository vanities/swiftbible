// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { initSentry, captureException } from "../_shared/sentry.ts";

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

// ─── Verse text lookup from bible.json ──────────────────────────────

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
  // Strip <JESUS>...</JESUS> tags used for red-letter markup in bible.json
  return paragraph.text
    .trim()
    .replace(/<\/?JESUS>/g, "")
    .trim();
}

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

// ─── Multi-verse selection (cheap model) ────────────────────────────

async function selectMultiVerses(
  count: number,
  holiday: Holiday | null
): Promise<Array<{ book: string; chapter: number; verse: number }>> {
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
          model: "gpt-5.4-mini",
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

  return allVerses;
}

// ─── Multi-verse prompt creation ────────────────────────────────────

function createMultiVersePrompt(
  verses: SelectedVerse[],
  formattedDate: string,
  holiday: Holiday | null
): string {
  const versesBlock = verses
    .map((v) => `- ${v.book} ${v.chapter}:${v.verse} — "${v.text}"`)
    .join("\n");

  if (holiday) {
    return `
Create a daily devotional for a Bible app that weaves together the following ${verses.length} thematically connected Bible verses from the King James Version (KJV) for ${holiday.name}:

${versesBlock}

Date: ${formattedDate}

Holiday Context:
${holiday.themeHint}

Devotional Guidelines:

1. Title as a Heading: Use # for the title at the very top. Include the date and "${holiday.name}" in this title.

2. Subtitle (Context Summary Only): Provide a **bolded thematic summary** line that captures the main theme connecting all the verses. DO NOT include the date or passage references in this subtitle.

3. Verse Block Formatting:
   - Present ALL verses together in a Markdown blockquote (using >). List each verse on its own line within the blockquote with its reference bolded beneath it.

4. Thematic Thread: After the verses, explain the thematic thread that connects these passages. Show how each verse illuminates and builds upon the others, creating a richer understanding than any single verse alone.

5. Devotional Content:
   - Contextual Background: Integrate the verses' background naturally, using ## section headers.
   - Historical and Cultural Insights: Incorporate relevant historical or cultural context.
   - Linguistic and Translational Insights: Include key Hebrew or Greek words with their meanings.
   - Cross-Reference Connection: Explicitly show how these verses from different parts of Scripture speak to the same truth.

6. Modern Relevance: Guide the reader to relate the connected passages to contemporary themes. Connect the verses to the significance of ${holiday.name} in modern life.

7. Personal Reflection and Application:
   - Include reflective questions formatted as a Markdown list.
   - At least one question should ask the reader to consider how the verses together reveal something they wouldn't see from one verse alone.

8. Final Meditation:
   - Close with a short meditation or prayerful reflection in italics that draws from all the verses together.
`;
  }

  // Non-holiday multi-verse
  return `
Create a daily devotional for a Bible app that weaves together the following ${verses.length} thematically connected Bible verses from the King James Version (KJV):

${versesBlock}

Date: ${formattedDate}

Devotional Guidelines:

1. Title as a Heading: Use # for the title at the very top. Include the date and the primary passage reference in this title.

2. Subtitle (Context Summary Only): Provide a **bolded thematic summary** line that captures the unified theme connecting all the verses. DO NOT include the date or passage references in this subtitle.

3. Verse Block Formatting:
   - Present ALL verses together in a Markdown blockquote (using >). List each verse on its own line within the blockquote with its reference bolded beneath it.

4. Thematic Thread: After the verses, explain the thematic thread that connects these passages. Show how each verse illuminates and builds upon the others, creating a richer understanding than any single verse alone.

5. Devotional Content:
   - Contextual Background: Integrate the verses' background naturally, using ## section headers.
   - Historical and Cultural Insights: Incorporate relevant historical or cultural context.
   - Linguistic and Translational Insights: Include key Hebrew or Greek words with their meanings.
   - Cross-Reference Connection: Explicitly show how these verses from different parts of Scripture speak to the same truth.

6. Modern Relevance: Guide the reader to relate the connected passages to contemporary themes or challenges. Show how the combined message applies to daily life.

7. Personal Reflection and Application:
   - Include reflective questions formatted as a Markdown list.
   - At least one question should ask the reader to consider how the verses together reveal something they wouldn't see from one verse alone.

8. Final Meditation:
   - Close with a short meditation or prayerful reflection in italics that draws from all the verses together.
`;
}

// ─── Devotional generation (OpenAI) ─────────────────────────────────

async function generateDevotional(prompt: string): Promise<string> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) throw new Error("Missing OPENAI_API_KEY env var");
  const model = "gpt-5.4";

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

async function determineDevotionalType(
  supabase: ReturnType<typeof createClient>,
  today: Date,
  holiday: Holiday | null
): Promise<{ type: "single" | "multi"; targetTestament: "old" | "new" }> {
  // Holidays: pick one curated verse (single-verse devotional)
  if (holiday) {
    const randomVerse = holiday.verses[Math.floor(Math.random() * holiday.verses.length)];
    return { type: "single", targetTestament: randomVerse.testament };
  }

  // Check yesterday's devotional for rotation: old single → new single → multi → repeat
  const yesterday = addDays(today, -1);
  const yesterdayStr = yesterday.toISOString().split("T")[0];

  try {
    const { data, error } = await supabase
      .from("Daily Devotional")
      .select("testament, devotional_type")
      .eq("for_date", yesterdayStr)
      .single();

    if (error || !data) {
      return { type: "single", targetTestament: "old" };
    }

    const prevType = data.devotional_type || "single";
    const prevTestament = data.testament as "old" | "new";

    if (prevType === "multi") {
      return { type: "single", targetTestament: "old" };
    } else if (prevTestament === "old") {
      return { type: "single", targetTestament: "new" };
    } else {
      return {
        type: "multi",
        targetTestament: Math.random() < 0.5 ? "old" : "new",
      };
    }
  } catch {
    return { type: "single", targetTestament: "old" };
  }
}

async function saveDevotional(
  supabase: ReturnType<typeof createClient>,
  message: string,
  forDate: string,
  testament: string,
  devotionalType: string,
  verses: SelectedVerse[]
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

  if (error) throw error;
  return data?.message ?? null;
}

// ─── Main handler ───────────────────────────────────────────────────

initSentry("daily-devotional");

Deno.serve(async (req) => {
  if (Deno.env.get("SUPABASE_URL") == req.headers.get("SuperSecret")) {
    return { statusCode: 403, body: "External calls are not allowed" };
  }

  try {
    const supabase = createSupabaseClient();
    const today = new Date();
    const { formatted, isoDate } = getFormattedDate();

    const existingDevotional = await fetchExistingDevotional(supabase, isoDate);
    if (existingDevotional) {
      console.log(`Devotional already exists for ${isoDate}; returning cached content.`);
      return new Response(existingDevotional, {
        headers: { "Content-Type": "text/plain" },
      });
    }

    // Check for holiday
    const holiday = getHoliday(today);
    if (holiday) {
      console.log(`Holiday detected: ${holiday.name}`);
    }

    // Determine devotional type and target testament
    // Rotation: old single → new single → multi → old single → ...
    // Holidays always use multi-verse with all curated verses
    const { type: devotionalType, targetTestament } =
      await determineDevotionalType(supabase, today, holiday);
    console.log(
      `Devotional type: ${devotionalType}, Target testament: ${targetTestament}`
    );

    // Select verse(s) and create prompt
    let prompt: string;
    let versesUsed: SelectedVerse[];

    if (devotionalType === "multi") {
      // Non-holiday multi-verse: random seed + GPT companion
      const verseRefs = await selectMultiVerses(2, null);

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

      prompt = createMultiVersePrompt(versesUsed, formatted, holiday);
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
      prompt = createPrompt(verse, formatted, holiday);
    }

    console.log(
      `Verses: ${versesUsed.map((v) => `${v.book} ${v.chapter}:${v.verse}`).join(", ")}`
    );

    // Generate devotional
    const devotional = await generateDevotional(prompt);
    console.log("Generated Devotional:\n", devotional);

    // Save to database
    await saveDevotional(
      supabase,
      devotional,
      isoDate,
      targetTestament,
      devotionalType,
      versesUsed
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
