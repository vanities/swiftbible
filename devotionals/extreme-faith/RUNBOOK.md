# Extreme Faith — Sunday Devotional Series Runbook

A recurring Sunday-only custom devotional series for SwiftBible. Each entry confronts a real gap between what Christians say they believe and how they actually behave. The goal is loving confrontation, not preachiness — meet readers in the natural human reaction, then refuse to leave them there.

**Why Sunday only:** PostHog data shows Sunday gets ~28% of all weekly devotional views (highest day of the week). Custom Sunday content is where the audience actually is.

**Why "Extreme Faith":** Like extreme programming — pushing a discipline to its honest limit. Each devotional names a specific behavioral pattern that's at odds with biblical command.

**Sister series (round-robin rotation):** Grace → Rest → Delight → Faith. See [Rotation](#rotation) below.

---

## Markdown structure

Every entry in this series uses the same markdown skeleton — matching the AI-generated devotionals so the visual rhythm of the app stays consistent. **No `---` horizontal rules** — use `##` section headers between beats instead.

```markdown
# {Month Day} — {Lead Verse Reference}: {Title}

**{One-line bolded subtitle — first-person admission ("I have ..." / "I am ..."). No date or reference here.}**

> *"{Lead verse text}"*
> **{Lead Verse Reference}**

## {Section header for beat 1}

{empathy content}

## {Section header for beat 2}

{Bible content with inline blockquotes for additional verses}

> *"{Verse text}"*
> **{Citation}**

{...}

## A prayer

{short, specific prayer ending in Amen.}
```

## The four beats

Within that skeleton, each entry hits these four moves:

1. **Empathize** — the natural human reaction. Specific sensory details, not abstractions. Acknowledge what's actually hard.
2. **Bible** — what scripture says. The "faith-extreme" position. Direct quotes in blockquotes with bold citations.
3. **Mix of empathy + Bible** — the closing argument. Acknowledge the cost frankly. Don't pretend the faith-extreme is easy. Show how the two aren't actually in conflict.
4. **Prayer / meditation** — short, specific, personal. Not a benediction. Something the reader can actually pray. Always under `## A prayer`.

Beats 1–3 can span 2–3 `##` sections depending on how the argument unfolds; beat 4 is always a single `## A prayer` section.

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
- **Anchor with "I" first.** The bold subtitle is a personal admission. The prayer returns to first-person. The body of the devotional can universalize to "you" / "we", but the frame is **I → we → I**.
- Lead with concrete sensory detail. Not "we feel sad" — "we play their voicemail, we can't sleep."
- Vary sentence length. Use short ones for emphasis.
- Direct address. "You" not "we" sometimes.
- Ask questions.
- Acknowledge the cost. Don't be glib.
- End the empathy beat on the real difficulty, not a tidy resolution.
- Keep the final prayer specific. Not flowery.
- Match the prayer's address to the devotional's content — *Father*, *King Jesus*, *Lord*, *Holy Spirit*, etc. No fixed series-wide form.

**Tone:** Light talking, morale. A pastor who knows you, not a preacher on a stage. Concrete, frank, warm, willing to be uncomfortable.

These voice rules are shared across all four series (Faith, Grace, Rest, Delight). The series-specific content is the schedule and per-devotional notes below.

---

## CoC theological framework

These devotionals are written from a (non-institutional) Church of Christ lens. The four-series rotation is unified theologically — key distinctives that shape drafting:

- **Sabbath fulfilled in Christ** (Heb 4). The *principle* of cessation is real (carried by the Extreme Rest series), but Christians don't keep the Sabbath as binding command. Use Heb 4, Mark 2:27, Matt 11:28-30 — not Ex 20:8-11 as Christian command.
- **Baptism is for the remission of sins** (Acts 2:38, 22:16, Rom 6:3-4). Salvation in the New Covenant comes through faith expressed in baptism. Grace devotionals must not collapse into "just call on the name" or "just believe." The thief on the cross was under the Old Covenant (pre-Pentecost); Saul was baptized after Damascus; "anyone who calls" is paired with baptism in Acts 22:16.
- **A cappella congregational worship.** OT psalms reference instruments, but the NT pattern (Eph 5:19, Col 3:16, Heb 13:15) is vocal congregational worship. Delight devotionals must not advocate for instrumental church music.
- **Lord's Supper weekly, memorial-symbolic.** First day of every week. Anti-transubstantiation.
- **Hell is literal and eternal.** Anti-universalism, anti-annihilationism.
- **Free will + responsibility.** Anti-Calvinist on individual predestination.
- **Grace and obedience are inseparable.** Salvation by grace through faith, with obedience as the response. Not antinomianism; not works-righteousness. (Matt Bassford: *"two halves of the same whole."*)
- **Anti-premillennial.** Kingdom = Christ's present reign over hearts and the church, not a future earthly millennium.

When using the Matt Bassford research skill (`.claude/skills/matt-bassford/`), Matt's positions match this framework — see `references/theology.md` for anchor posts on each.

### Topics flagged for extra CoC care

| Series | Week | Topic | Care needed |
|---|---|---|---|
| Grace | 2 | Five minutes is enough (thief) | Thief was under the Old Covenant (pre-Pentecost). Don't let this collapse into "baptism isn't necessary." |
| Grace | 4 | The persecutor becomes the apostle (Saul) | Saul was baptized after Damascus (Acts 22:16). Frame extreme as God choosing the persecutor, not as conversion-without-baptism. |
| Grace | 8 | The five-times-divorced theologian | Keep both halves of grace + repent. CoC reads divorce/remarriage strictly (Matt 19:9). |
| Grace | 9 | The death penalty refused | *"Go and sin no more"* is part of the grace, not a footnote. |
| Grace | 11 | Anyone who calls | Acts 22:16 ties calling to baptism. Verses include Acts 22:16 to remind the drafter. |
| Rest | 2 | A 24-hour confession | Frame as cessation principle (Sabbath fulfilled in Christ), not binding Sabbath command. Use Heb 4, not Ex 20. |
| Delight | 2 | More wine for the party | Joy in good gifts, within moderation. Not glorifying drunkenness. |
| Delight | 9 | Mandatory feasts | OT festivals are Old Covenant. Draw the principle (commanded celebration), don't bind the festival. |
| Delight | 10 | David danced | Personal worship before God. Not a precedent for instrumental or dance worship in congregational assembly. |
| Delight | 11 | When the room sings | A cappella reframe — congregation as instrument. Don't use Ps 150 as precedent for instrumental church music. |

---

## Series schedule

The 12 Faith topics queue across the [round-robin rotation](#rotation) — Faith gets every 4th Sunday (last in the cycle, after Delight). Faith #1 ran on 2026-05-03 ahead of the rotation start.

Each entry contrasts the **comfortable middle** (where most Christians actually live) with the **extreme claim** (what Jesus and the apostles actually require). The four-beat structure lets the empathy land first; the extreme claim is the pivot — never softened, always anchored in scripture.

| # | Sunday | Title | Comfortable middle | Extreme claim | Anchor verses |
|---|---|---|---|---|---|
| 1 | **2026-05-03** ✅ | **Maranatha** | "Jesus will come back — *eventually*." | Pray for him to come back **tonight**, even before your kids grow up. | Rev 22:20, 2 Pet 3:9, Phil 3:20 |
| 2 | **2026-05-31** ✅ | **Mourn in the present tense** | "Mourn the loss but hold onto hope." | Mourn AND speak of them in the present tense. Carry the wound for forty years AND know it's not the whole story. | 1 Thess 4:13, John 11:35, Phil 1:21-23, 1 Cor 15:55 |
| 3 | 2026-06-28 | Bless the one who hurt you | "Forgive them, but keep your distance." | Pray for your abuser **by name**. Do good to them concretely. While still bleeding. | Matt 5:43-48, Luke 6:27-36, Rom 12:14-21 |
| 4 | 2026-07-26 | Sell what you have | "Be a generous giver out of your surplus." | Sell everything. Hold all things in common with the church. The rich young ruler walked away — the early church didn't. | Mark 10:17-31, Acts 2:44-45, Acts 4:32-37 |
| 5 | 2026-08-23 | Take no thought for tomorrow | "Plan wisely but don't worry." | Stop storing up. Stop planning for tomorrow. Trust God for today's bread the way Israel ate manna. | Matt 6:25-34, Ex 16:4-21, Phil 4:6-7 |
| 6 | 2026-09-20 | Seventy times seven | "Forgive when they apologize." | Forgive while still being wronged. Forgive the unrepentant. Pray for them by name today. | Matt 18:21-35, Luke 23:34, Eph 4:32 |
| 7 | 2026-10-18 | Glory in tribulation | "Endure suffering with hope." | **Thank God for the suffering.** Sing in the prison cell. Treat trials as gift, not enemy. | James 1:2-4, Acts 16:25, Rom 5:3-5, Acts 5:41 |
| 8 | 2026-11-15 | Seek the lower seat | "Don't seek attention." | Take the lowest seat **on purpose**. Refuse promotion. Wash feet. Become invisible while others rise. | Luke 14:7-11, Mark 9:35, John 13:1-17 |
| 9 | 2026-12-13 | Hate father and mother | "Love God first, but family is also important." | Christ will be a sword between you and your family if it comes to it. Be ready. | Luke 14:25-33, Matt 10:34-39, Mark 8:34-38 |
| 10 | 2027-01-10 | Confess me before men | "Live a quiet Christian life." | Lose your job for the gospel. Lose your friends. Be ready to be martyred. Being ashamed of Christ is being denied by him. | Mark 8:38, Matt 10:32-33, Rom 1:16, Acts 5:41 |
| 11 | 2027-02-07 | Anger is murder | "Anger isn't a sin if I don't act on it." | Jesus equates anger in the heart with murder. Hatred for a brother is killing him in your heart. | Matt 5:21-26, 1 John 3:15, James 1:19-20 |
| 12 | 2027-03-07 | Take up your cross daily | "I committed to Christ years ago." | Discipleship is *daily.* The cross isn't a moment of conversion — it's the habit of choosing Christ over the self that wants the easier path, every day, until you die. | Luke 9:23, 1 Cor 15:31, Gal 2:20, Rom 6:6 |

Order is not fixed — Adam may handpick the next Faith topic each cycle based on what he's been thinking and praying about.

**Strong runner-ups** (swap in if a theme hits):
- Lust as adultery / pluck out your eye (Matt 5:27-30)
- Turn the other cheek, give to everyone who asks (Matt 5:38-42)
- Let your yes be yes — no oaths, no white lies (Matt 5:33-37)
- Eat my flesh, drink my blood — the disciples left over this (John 6:53-66)
- The cost of being last (Mark 10:31, the great reversal)
- Cease entirely (Heb 4:1-11) — *originally Week 12; swapped out because the CoC lens reads Sabbath as fulfilled in Christ. The cessation theme is fully carried by the Extreme Rest series. Could still work here as "practicing cessation as confession of trust" if reframed away from binding-command.*

**Diagnostic for "is this extreme enough?"**: if a smart secular reader would nod along with the claim, it's not extreme yet. The faith-extreme position should make the comfortable Christian wince, *then* invite them in with empathy and the cross.

---

## Rotation

**Round-robin across four series:** Grace → Rest → Delight → Faith → repeat. Each series gets every 4th Sunday. Faith #1 (Maranatha) ran 2026-05-03 ahead of the rotation start; the rotation cycle proper begins 2026-05-10 with Grace #1.

| Sunday | Series |
|---|---|
| 2026-05-03 | Faith #1 (Maranatha) ✅ |
| 2026-05-10 | Grace #1 |
| 2026-05-17 | Rest #1 |
| 2026-05-24 | Delight #1 |
| 2026-05-31 | Faith #2 (Mourn in the present tense) ✅ drafted |
| 2026-06-07 | Grace #2 |
| 2026-06-14 | Rest #2 |
| 2026-06-21 | Delight #2 |
| 2026-06-28 | Faith #3 |
| 2026-07-05 | Grace #3 |
| ... | (continues rotating) |

The rotation prevents the audience from getting only hard demands every Sunday. Each series has its own RUNBOOK with full schedule and per-devotional notes:

- [extreme-grace/RUNBOOK.md](../extreme-grace/RUNBOOK.md) — surprising mercy
- [extreme-rest/RUNBOOK.md](../extreme-rest/RUNBOOK.md) — radical cessation
- [extreme-delight/RUNBOOK.md](../extreme-delight/RUNBOOK.md) — commanded joy

Deviate from strict rotation if a topic is pressing — round-robin is the default, not a rule.

---

## Per-devotional notes

### Week 1 — Maranatha (2026-05-03)

Lead with: most Christians don't actually pray for Christ's return. Why? Because we have plans. Specific things we'd lose: the wedding, the kids growing up, the trip we saved for, the book we want to write. Honest about the unspoken reason — *we're not ready*.

Pivot via the world: scroll the news for five minutes. Wars, trafficking, mental health collapse, drug overdoses, family breakdown — keep concrete but **non-political**, no partisan framing. The world is groaning (Rom 8:22). The early church looked at Roman occupation and cried *Maranatha*.

Anchor verses: Rev 22:20 (last words of the Bible), 2 Pet 3:11-13, Phil 3:20, Titus 2:13, Matt 24:6-7.

End the empathy+Bible mix on: loving life and longing for Christ aren't enemies. Paul could say "to die is gain" without hating life. The longing actually deepens love for the people around you.

Prayer: short, specific. *"I have prayed around your return for too long. Let me cry it now."* Land on *Maranatha*.

### Week 2 — Mourn in the present tense (2026-05-31)

The reframe (originally "Rejoice at the grave"): Matt Bassford's writing on grief — especially `2015-07-28-weeping-with-those-who-weep.md`, `2019-01-04-mourning-with-hope.md`, and `2022-03-23-the-lunch-lady.md` — pushes hard against "throw the party" framing. He treats grief and hope as compatible *but distinct chords* in the same hymn. The faith-extreme position isn't joy minus grief; it's *grief in the present tense.* Mourn AND speak of them as alive somewhere right now.

Lead with: the well-meaning friend who tells you "they wouldn't want you to be sad." The pressure to perform acceptable mourning on a respectable timeline. The voicemail you can't delete. The sweater that still smells like them.

Anchor verses: 1 Thess 4:13 (sorrow not *as* those who have no hope — the "as" is doing the work), John 11:35 (Jesus weeps even though he's about to raise Lazarus — grief is a function of love, not failure of faith), Phil 1:21-23 (Paul's "far better" math), 1 Cor 15:55 (Paul taunting death).

End the empathy+Bible mix on: the Christian doesn't choose between weeping and rejoicing. He gets to do both, often at the same time. Borrow Matt's line: *"Some wounds do not heal this side of Jordan. We should not expect them to. And. The wound is not the whole story."*

Prayer: short, specific. Returns to the bold subtitle as a refrain — *"I have been told to be over it. Some part of me has agreed."*

---

## Drafting workflow

1. **Compose draft** — write in `devotionals/extreme-faith/NN-slug.md` as plain markdown. Follow the four-beat structure. Match the voice rules.
2. **Adam edits** — Adam handpicks and rewrites in his own voice. Treat AI drafts as starting material, never final.
3. **Convert to JSON payload** — pass the edited markdown directly via `--message-file` so you don't have to hand-edit the JSON:
   ```bash
   python3 skills/custom-devotional-crafter/scripts/compose_custom_devotional.py \
     --for-date 2026-05-03 \
     --theme "Maranatha" \
     --audience "General" \
     --tone "Pastoral" \
     --verse "Revelation 22:20" \
     --verse "2 Peter 3:9" \
     --verse "Philippians 3:20" \
     --series-name "Extreme Faith" \
     --series-part 1 \
     --message-file devotionals/extreme-faith/01-maranatha.md \
     --output /tmp/maranatha-payload.json
   ```
4. **Dry-run publish** — `python3 skills/custom-devotional-crafter/scripts/push_custom_devotional.py --file /tmp/maranatha-payload.json --dry-run`
5. **Publish** — load credentials and run without `--dry-run`:
   ```bash
   set -a && source .env.production && set +a
   python3 skills/custom-devotional-crafter/scripts/push_custom_devotional.py --file /tmp/maranatha-payload.json
   ```
   Upserts on `for_date`. The iOS app renders the tappable "Custom" badge (with attribution alert) plus a context line: *"Extreme Faith · Week N"*.

---

## File layout

```
devotionals/extreme-faith/
├── RUNBOOK.md                          # this file
├── 01-maranatha.md                     # week 1 (published 2026-05-03)
├── 02-mourn-in-the-present-tense.md    # week 2 (drafted, scheduled 2026-05-31)
├── ...
└── archive/                            # published markdown after edits, for reference
```

---

## Reference

- Skill: `skills/custom-devotional-crafter/` (also symlinked to `.claude/skills/`)
- Format guide: `skills/custom-devotional-crafter/references/format-guide.md`
- Matt Bassford research skill: `.claude/skills/matt-bassford/` (use for theme research, voice borrows, theological pushback flags)
- Engagement dashboard: https://us.posthog.com/project/335021/dashboard/1512720
