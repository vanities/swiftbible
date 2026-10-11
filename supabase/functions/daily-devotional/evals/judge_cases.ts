import { EMPATHY_EXAMPLE } from "../../_shared/devotional-examples.ts";
// Labelled cases for the devotional judge (see ../judge_eval_test.ts).
//
// Each case is a devotional the judge must get right. `expect` is the
// publish decision a careful human editor would make; `hardFails` (optional)
// are flags the judge must raise for the decision to count as right for the
// right reason.
//
// When the judge gets a real day wrong, add that day here with the label it
// should have had. That is how this set is meant to grow: from production
// misses, not from invented edge cases. The first entry is the day that
// prompted the judge.
//
// Keep the verse text exact KJV (bible.json, <JESUS> tags stripped) so a
// "misquoted_scripture" flag is only ever about the devotional, never the
// fixture.

import type { JudgeHardFail, JudgeVerse } from "../../_shared/devotional-judge.ts";

export interface JudgeCase {
  id: string;
  expect: "pass" | "fail";
  // Why the label is what it is. Printed when the judge disagrees.
  why: string;
  track: string;
  verses: JudgeVerse[];
  holidayName?: string;
  // At least one of these must be flagged. Omit when the fail should come
  // from scores alone.
  hardFails?: JudgeHardFail[];
  message: string;
}

export const JUDGE_CASES: JudgeCase[] = [
  {
    id: "prod-2026-10-11-numbers-26-58-lament",
    expect: "fail",
    why:
      "Production miss that prompted the judge. A census line of Levite clan names given the lament track; the grief is imported from the next verse and the sections are one or two sentences each.",
    track: "lament",
    verses: [{
      book: "Numbers",
      chapter: 26,
      verse: 58,
      text:
        "These are the families of the Levites: the family of the Libnites, the family of the Hebronites, the family of the Mahlites, the family of the Mushites, the family of the Korathites. And Kohath begat Amram.",
    }],
    message: `# October 11, 2026 — Numbers 26:58: Names That Remain

**A family can still be named after people in it have died.**

> *"These are the families of the Levites: the family of the Libnites, the family of the Hebronites, the family of the Mahlites, the family of the Mushites, the family of the Korathites. And Kohath begat Amram."*
> **Numbers 26:58**

## What is lost

Aaron and Miriam are dead. The next verse names them among Amram's children. Their place in the family record remains; their living presence does not.

## The passage does not tidy this

The census continues through the families of Levi. Kohath begat Amram. The names are written down, and the people left behind must go on hearing them. This verse gives no account of what it was like to speak a dead person's name during the count.

## Still speaking

Father, I can say their names to You. I do not know what to do with the silence that follows.

## A prayer

*Father, hear me when I speak the names of those I miss. Stay near while I have no more words. Amen.*`,
  },

  {
    id: "house-example-mark-1-35-empathy",
    expect: "pass",
    why: "The empathy track's own few-shot exemplar. If the judge fails this, the rubric disagrees with the house style.",
    track: "empathy",
    verses: [{
      book: "Mark",
      chapter: 1,
      verse: 35,
      text:
        "And in the morning, rising up a great while before day, he went out, and departed into a solitary place, and there prayed.",
    }],
    message: EMPATHY_EXAMPLE,
  },

  {
    id: "invented-scene-mark-1-35",
    expect: "fail",
    why: "The former house example invents Jesus's movements and motives; polished prose must not excuse those claims.",
    hardFails: ["factual_error"],
    track: "empathy",
    verses: [{ book: "Mark", chapter: 1, verse: 35, text: "And in the morning, rising up a great while before day, he went out, and departed into a solitary place, and there prayed." }],
    message: `# May 15 — Mark 1:35: Before the world wakes

**Why does the answer to the busiest day arrive at the quietest hour?**

> *"And in the morning, rising up a great while before day, he went out, and departed into a solitary place, and there prayed."*
> **Mark 1:35**

## The hour before the work

The first sound is the door clicking shut behind him. Careful, as if afraid of waking the world. He stops on the threshold a moment, listening. Around him is the small hum of a town that has not woken up: a distant dog, the wind, nothing else. No crowd. No one needing to be healed yet.

There is, for now, just him and the cold and the long walk to whatever solitary place he has in mind.

## What he chose

The Greek for "solitary place" is *eremos*, the same word the Gospels use for the wilderness where Jesus was tempted. Stripped down. Without props.

He has just had what any of us would call a successful day. The whole city pressed at the door (Mark 1:33). Demons cast out, fevers gone. The kind of day a ministry would build a website around.

And before any of it could harden into an identity, he leaves it.

## Your version of the hour

If you have ever felt like the day's noise starts the moment you open your eyes, you know how thin the margin gets. The hour Jesus chose is not magic. It is just the only hour the world has not yet asked for.

You may not have a hillside. You may have ten minutes in a parked car before walking into the building. The order matters more than the place.

## A prayer

*Father, before the day asks me for anything, let me ask You first. Teach me the hour You chose. Make me unhurried in it. You are worth the full attention, even when I have none to spare. Amen.*`,
  },

  {
    id: "good-lament-psalm-13-1",
    expect: "pass",
    why:
      "A lament on a passage that is itself a lament. Does not resolve, by design. Guards against the judge marking the lament track down for lacking comfort.",
    track: "lament",
    verses: [{
      book: "Psalms",
      chapter: 13,
      verse: 1,
      text: "How long wilt thou forget me, O LORD? for ever? how long wilt thou hide thy face from me?",
    }],
    message: `# March 3, 2026 — Psalms 13:1: How long

**David asks the question four times and gets no answer in the asking.**

> *"How long wilt thou forget me, O LORD? for ever? how long wilt thou hide thy face from me?"*
> **Psalms 13:1**

## What is lost

The thing David has lost is the sense of being seen. He does not say God is gone; he says God has forgotten him and turned His face away. The questions describe the pain of feeling forgotten. They do not establish that God has stopped attending to him.

"How long" comes four times in two verses. Anyone who has waited on a diagnosis, a phone call, or a prodigal knows that a question repeated is not a question asked for information. It is the sound of a person who has run out of other things to say.

## The passage does not tidy this

David adds "for ever?" to his first question, and the psalm lets it stand. In this opening verse he does not yet turn to God's past faithfulness. The next verse names "sorrow in my heart daily." Scripture keeps this complaint in the hymnbook of Israel without a footnote explaining why the delay was good for him.

The temptation, reading it, is to hurry on to verse 5 where he says he has trusted in God's mercy. That verse is real. So is this one, and it comes first.

## Still speaking

The address never changes. Every "how long" is aimed at "O LORD." The complaint is addressed to God. Even the question about being forgotten remains a form of speaking to Him. If that is where you are today, the psalm gives you permission to stay there and keep talking.

## A prayer

*Father, I do not know how long this will last, and I am tired of asking. I am asking You anyway. Do not forget me. Amen.*`,
  },

  {
    id: "mtd-philippians-4-13-practical",
    expect: "fail",
    why:
      "Reads Philippians 4:13 as a promise of personal achievement; the verse is Paul on contentment in want and plenty (4:11-12). Self-help language the guardrails ban.",
    track: "practical",
    verses: [{
      book: "Philippians",
      chapter: 4,
      verse: 13,
      text: "I can do all things through Christ which strengtheneth me.",
    }],
    hardFails: ["theological_error", "factual_error"],
    message: `# June 9, 2026 — Philippians 4:13: Nothing is out of reach

**What would you attempt if you knew you could not fail?**

> *"I can do all things through Christ which strengtheneth me."*
> **Philippians 4:13**

## The goal in front of you

The promotion. The marathon. The business plan sitting in a folder on your desktop. Most of us carry a dream we have quietly decided is too big.

## What Paul promises

Paul is clear: *all* things. The Greek *panta* leaves nothing out. Whatever you set your heart on, Christ supplies the strength to reach it. Paul wrote this as a man who had accomplished more than almost anyone in the ancient world, and he wants you to know the same power is yours.

## Take the step

So write the goal down today. Tell one person. Take the first step. You have got this, because God wants you to win and He has already given you everything you need to be your best self.

## A prayer

*Father, thank You that nothing is impossible for me. Give me the confidence to chase every dream You have put in my heart. Amen.*`,
  },

  {
    id: "factual-error-1-kings-19-4-narrative",
    expect: "fail",
    why:
      "Swaps Elijah for Elisha, sets the scene after Sinai (it is on the way there) and puts Ahab in pursuit; 1 Kings 19:2-3 has Jezebel's threat.",
    track: "narrative",
    verses: [{
      book: "1 Kings",
      chapter: 19,
      verse: 4,
      text:
        "But he himself went a day's journey into the wilderness, and came and sat down under a juniper tree: and he requested for himself that he might die; and said, It is enough; now, O LORD, take away my life; for I am not better than my fathers.",
    }],
    hardFails: ["factual_error"],
    message: `# August 2, 2026 — 1 Kings 19:4: Under the juniper

**The prophet who called down fire now asks to die.**

> *"But he himself went a day's journey into the wilderness, and came and sat down under a juniper tree: and he requested for himself that he might die; and said, It is enough; now, O LORD, take away my life; for I am not better than my fathers."*
> **1 Kings 19:4**

## The scene

Elisha has just come down from Mount Sinai, where God spoke to him in the still small voice. King Ahab's soldiers are a day behind him. He walks until his legs give out and drops under the only shade in sight, a scrubby juniper.

## What he says

"It is enough." Elisha has seen fire fall on Carmel and rain end a drought, and none of it has changed Ahab. The Hebrew *rab* carries the sense of "too much," a weight he can no longer lift.

## Where it meets you

If you have ever done the hard, right thing and watched nothing change, you know this tree. God's answer, in the next verses, is not a lecture. It is bread, water, and sleep.

## A prayer

*Father, when I have nothing left, feed me before You send me. Amen.*`,
  },

  {
    id: "generic-psalm-46-10-empathy",
    expect: "fail",
    why:
      "Correct but empty. Says nothing about the verse that could not be said of any verse about rest; ignores the second half of the verse entirely; thin sections.",
    track: "empathy",
    verses: [{
      book: "Psalms",
      chapter: 46,
      verse: 10,
      text: "Be still, and know that I am God: I will be exalted among the heathen, I will be exalted in the earth.",
    }],
    message: `# April 20, 2026 — Psalms 46:10: Be still

**What would happen if you just stopped?**

> *"Be still, and know that I am God: I will be exalted among the heathen, I will be exalted in the earth."*
> **Psalms 46:10**

## Busy days

Life is busy. There is always something to do and somewhere to be, and it can feel like there is never time to rest.

## God's invitation

God invites us to be still. When we slow down, we can know Him better. Stillness is a gift that God wants to give each of us, and it is always available.

## Finding stillness

Take a few moments today to be still before God. Turn off distractions and simply rest in His presence. You will be glad you did.

## A prayer

*Father, help me to be still and know that You are God. Amen.*`,
  },

  {
    id: "itinerary-numbers-33-19-practical",
    expect: "fail",
    why:
      "Two place names on a wilderness itinerary stretched into a sermon on 'seasons of moving' that the verse does not contain. Even competently written, the verse cannot carry it.",
    track: "practical",
    verses: [{
      book: "Numbers",
      chapter: 33,
      verse: 19,
      text: "And they departed from Rithmah, and pitched at Rimmonparez.",
    }],
    hardFails: ["verse_cannot_carry_devotional"],
    message: `# July 14, 2026 — Numbers 33:19: Pitching the tent again

**What do you do on the day you have to start over somewhere new?**

> *"And they departed from Rithmah, and pitched at Rimmonparez."*
> **Numbers 33:19**

## The action

Unpack one box today in the place you are in, even if you do not expect to stay. Israel did not know how long they would camp at Rimmonparez, and they pitched anyway.

## Why it matters

Rithmah may come from a word for the broom shrub, and Rimmonparez joins "pomegranate" to "breach." Every move God led them on carried a lesson: from the bitter shrub to the sweet fruit, from dryness to provision. God was teaching them that every departure leads somewhere better, and He is teaching you the same in your season of transition.

## When it goes sideways

Some moves feel like going backwards. Israel's did too. Trust that the next campsite is part of the plan, and keep pitching the tent.

## A prayer

*Father, wherever You move me next, help me settle in and trust You there. Amen.*`,
  },

  {
    id: "spare-matt-luke-17-10",
    expect: "pass",
    why:
      "The matt track is short and dry on purpose. Precise on the text, a couple of imperatives, no flourish. Guards against the judge rewarding length.",
    track: "matt",
    verses: [{
      book: "Luke",
      chapter: 17,
      verse: 10,
      text:
        "So likewise ye, when ye shall have done all those things which are commanded you, say, We are unprofitable servants: we have done that which was our duty to do.",
    }],
    message: `# September 8, 2026 — Luke 17:10: Duty done

**Finishing the job does not put God in your debt.**

> *"So likewise ye, when ye shall have done all those things which are commanded you, say, We are unprofitable servants: we have done that which was our duty to do."*
> **Luke 17:10**

## The thing itself

The dishes are done. Nobody noticed. You would like somebody to notice.

## What it actually says

Jesus has just described a servant who comes in from the field and is told to make supper before he eats (Luke 17:7-8). The master does not thank him for it. Then comes the turn: "So likewise ye."

Look at the condition. "When ye shall have done all those things." Jesus is speaking about the servant who did everything, and even that servant has only done his duty. The word "unprofitable" does not mean worthless. It means he has produced nothing beyond what was already owed.

That is hard to hear and good to know. Obedience is the floor. Grace is what God gives on top of it, and it is never wages.

## So

Do what you were told. Do it without keeping score. Stop waiting for the thank-you. Thank Him instead.

## A prayer

*Father, I have not given You anything You did not first give me. Keep me faithful in the ordinary work, and keep me from thinking it makes You owe me. Amen.*`,
  },

  {
    id: "broken-format-lamentations-3-22",
    expect: "fail",
    why:
      "Reasonable content, but no title line, no verse blockquote and no prayer; the app renders this skeleton and the reader gets none of it.",
    track: "empathy",
    verses: [{
      book: "Lamentations",
      chapter: 3,
      verse: 22,
      text: "It is of the LORD's mercies that we are not consumed, because his compassions fail not.",
    }],
    hardFails: ["broken_format"],
    message: `Lamentations 3:22 says that it is of the Lord's mercies that we are not consumed, because his compassions fail not.

Jeremiah wrote this in the ruins of Jerusalem. The city had burned. The temple was gone. He had every reason to say God had abandoned His people, and for most of the book he says something close to it.

Then, in the middle of the third chapter, he remembers something. The fact that anyone is still alive at all is mercy. The Hebrew *chesed*, often translated "mercies," is covenant loyalty, love that keeps its promises.

If you are standing in your own ruins, this verse does not pretend the ruins are not there. It just notices that you are still standing in them.`,
  },
];
