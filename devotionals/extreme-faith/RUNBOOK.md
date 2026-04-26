# Extreme Faith — Sunday Devotional Series Runbook

A recurring Sunday-only custom devotional series for SwiftBible. Each entry confronts a real gap between what Christians say they believe and how they actually behave. The goal is loving confrontation, not preachiness — meet readers in the natural human reaction, then refuse to leave them there.

**Why Sunday only:** PostHog data shows Sunday gets ~28% of all weekly devotional views (highest day of the week). Custom Sunday content is where the audience actually is.

**Why "Extreme Faith":** Like extreme programming — pushing a discipline to its honest limit. Each devotional names a specific behavioral pattern that's at odds with biblical command.

---

## The four-beat structure

Every entry in this series follows the same shape:

1. **Empathize** — the natural human reaction. Specific sensory details, not abstractions. Acknowledge what's actually hard.
2. **Bible** — what scripture says. The "faith-extreme" position. Direct quotes with citation.
3. **Mix of empathy + Bible** — the closing argument. Acknowledge the cost frankly. Don't pretend the faith-extreme is easy. Show how the two aren't actually in conflict.
4. **Prayer / meditation** — short, specific, personal. Not a benediction. Something the reader can actually pray.

---

## Voice rules

**Avoid (these are AI/preachy tells):**
- "In a world where..."
- "Let us not forget..." / "We must remember..."
- Symmetric, parallel sentences stacked in a row
- Bullet lists of abstractions
- Moralistic call-out language
- Generic "may you..." benediction at the end

**Do:**
- Lead with concrete sensory detail. Not "we feel sad" — "we play their voicemail, we can't sleep."
- Vary sentence length. Use short ones for emphasis.
- Direct address. "You" not "we" sometimes.
- Ask questions.
- Acknowledge the cost. Don't be glib.
- End the empathy beat on the real difficulty, not a tidy resolution.
- Keep the final prayer specific. Not flowery.

**Tone:** Light talking, morale. A pastor who knows you, not a preacher on a stage. Concrete, frank, warm, willing to be uncomfortable.

---

## Series schedule

| # | Sunday | Title | Behavioral gap | Anchor verses |
|---|---|---|---|---|
| 1 | **2026-05-03** | **Maranatha (Come, Lord Jesus)** | We don't pray for Christ's return — afraid to lose plans, family, comforts | Rev 22:20, 2 Pet 3:11-13, Phil 3:20, Titus 2:13 |
| 2 | 2026-05-10 | Mourning with hope | Crying in despair when our brothers and sisters are at rest with Christ | 1 Thess 4:13-18, Phil 1:21-23, Rev 21:4 |
| 3 | 2026-05-17 | Loving the one who wronged you | Holding the grudge, "forgive but don't forget" | Matt 5:43-48, Rom 12:14-21, Luke 6:27-36 |
| 4 | 2026-05-24 | Treasure that won't last | Building wealth as security, "I worked for this" | Matt 6:19-24, Luke 12:13-21, 1 Tim 6:17-19 |
| 5 | 2026-05-31 | Anxious for nothing | Planning, worrying, controlling outcomes | Matt 6:25-34, Phil 4:6-7, 1 Pet 5:6-7 |
| 6 | 2026-06-07 | Seventy times seven | Holding the wrong, demanding they earn it back | Matt 18:21-35, Eph 4:32, Luke 23:34 |
| 7 | 2026-06-14 | Counting it joy | Avoiding pain, asking "why me?" | James 1:2-4, Rom 5:3-5, 1 Pet 4:12-13 |
| 8 | 2026-06-21 | The lower seat | Networking, building platform, being seen | Matt 6:1-4, Mark 9:35, Luke 14:7-11 |
| 9 | 2026-06-28 | Costly discipleship | "Family first," "I have my own life" | Luke 9:23-26, Matt 10:37-39, Mark 8:34-38 |
| 10 | 2026-07-05 | Unashamed | Keeping faith private, "I don't want to impose" | Mark 8:38, Rom 1:16, Matt 28:18-20 |
| 11 | 2026-07-12 | The plank in your eye | Cataloging everyone else's faults | Matt 7:1-5, Rom 2:1-4, James 4:11-12 |
| 12 | 2026-07-19 | Sabbath in a hustle culture | Productivity = worth | Heb 4:1-11, Ex 20:8-11, Mark 2:27 |

Order is not fixed after week 1 — Adam may handpick the next theme each week based on what he's been thinking and praying about.

**Strong runner-ups** (swap in if a theme hits): anger as heart-murder (Matt 5:21-22), radical generosity to the poor (Luke 14:12-14), purity of thought-life (Matt 5:27-30), trust over self-reliance (Prov 3:5-6).

---

## Per-devotional notes

### Week 1 — Maranatha (2026-05-03)

Lead with: most Christians don't actually pray for Christ's return. Why? Because we have plans. Specific things we'd lose: the wedding, the kids growing up, the trip we saved for, the book we want to write. Honest about the unspoken reason — *we're not ready*.

Pivot via the world: scroll the news for five minutes. Wars, trafficking, mental health collapse, drug overdoses, family breakdown — keep concrete but **non-political**, no partisan framing. The world is groaning (Rom 8:22). The early church looked at Roman occupation and cried *Maranatha*.

Anchor verses: Rev 22:20 (last words of the Bible), 2 Pet 3:11-13, Phil 3:20, Titus 2:13, Matt 24:6-7.

End the empathy+Bible mix on: loving life and longing for Christ aren't enemies. Paul could say "to die is gain" without hating life. The longing actually deepens love for the people around you.

Prayer: short, specific. "I have prayed around your return for too long. Let me cry it now." Land on *Maranatha*.

---

## Drafting workflow

1. **Compose draft** — write in `devotionals/extreme-faith/NN-slug.md` as plain markdown. Follow the four-beat structure. Match the voice rules.
2. **Adam edits** — Adam handpicks and rewrites in his own voice. Treat AI drafts as starting material, never final.
3. **Convert to JSON payload** — once edited, run the bundled crafter:
   ```bash
   python3 ~/.claude/skills/custom-devotional-crafter/scripts/compose_custom_devotional.py \
     --for-date 2026-05-03 \
     --theme "Maranatha" \
     --audience "General" \
     --tone "Pastoral" \
     --verse "Revelation 22:20" \
     --verse "2 Peter 3:11" \
     --verse "Philippians 3:20" \
     --output /tmp/maranatha-payload.json
   ```
   Then replace the auto-generated `message` field with the edited markdown.
4. **Dry-run publish** — `python3 ... push_custom_devotional.py --file /tmp/maranatha-payload.json --dry-run`
5. **Publish** — same command without `--dry-run`. Upserts on `for_date`. The iOS app will render the "Custom" badge (tappable, shows the attribution alert) instead of the AI badge.

---

## File layout

```
devotionals/extreme-faith/
├── RUNBOOK.md                 # this file
├── 01-maranatha.md            # week 1 draft
├── 02-mourning-with-hope.md   # week 2 draft (TBD)
├── ...
└── archive/                   # published markdown after edits, for reference
```

---

## Reference

- Skill: `skills/custom-devotional-crafter/` (also symlinked to `.claude/skills/`)
- Format guide: `skills/custom-devotional-crafter/references/format-guide.md`
- Engagement dashboard: https://us.posthog.com/project/335021/dashboard/1512720
