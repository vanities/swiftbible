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
- Em dashes (—) in prose. Use commas, periods, semicolons, or parentheses. The em dash is a strong AI tell. Exception: structural title format `# Date — Reference: Title` is fine; nowhere else.
- Antithesis constructions of the form "It's not X, it's Y" / "Not X, but Y" / "X is not the point. Y is." Reads as ChatGPT cadence. Rephrase positively or rebuild the sentence so the contrast isn't the structure carrying the meaning.

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

When using the Matt Bassford research skill (`skills/matt-bassford/`), Matt's positions match this framework — see `references/theology.md` for anchor posts on each.

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
| 3 | **2026-06-28** ✅ | **Miss the mark** | "I'm not a bad person — I haven't broken any big rules." | The Greek for sin is *hamartia* — to miss the mark. The bullseye is the glory of God, and the rule-keeper falls short of it just like the rule-breaker. | Rom 3:23, Heb 4:15, Matt 5:48, Luke 18:9-14 |
| 4 | 2026-07-26 | Sell what you have | "Be a generous giver out of your surplus." | Sell everything. Hold all things in common with the church. The rich young ruler walked away — the early church didn't. | Mark 10:17-31, Acts 2:44-45, Acts 4:32-37 |
| 5 | 2026-08-23 | Take no thought for tomorrow | "Plan wisely but don't worry." | Stop storing up. Stop planning for tomorrow. Trust God for today's bread the way Israel ate manna. | Matt 6:25-34, Ex 16:4-21, Phil 4:6-7 |
| 6 | 2026-09-20 | Seventy times seven | "Forgive when they apologize." | Forgive while still being wronged. Forgive the unrepentant. Pray for them by name today. | Matt 18:21-35, Luke 23:34, Eph 4:32 |
| 7 | 2026-10-18 | Glory in tribulation | "Endure suffering with hope." | **Thank God for the suffering.** Sing in the prison cell. Treat trials as gift, not enemy. | James 1:2-4, Acts 16:25, Rom 5:3-5, Acts 5:41 |
| 8 | 2026-11-15 | Seek the lower seat | "Don't seek attention." | Take the lowest seat **on purpose**. Refuse promotion. Wash feet. Become invisible while others rise. | Luke 14:7-11, Mark 9:35, John 13:1-17 |
| 9 | 2026-12-13 | Hate father and mother | "Love God first, but family is also important." | Christ will be a sword between you and your family if it comes to it. Be ready. | Luke 14:25-33, Matt 10:34-39, Mark 8:34-38 |
| 10 | 2027-01-10 | Confess me before men | "Live a quiet Christian life." | Lose your job for the gospel. Lose your friends. Be ready to be martyred. Being ashamed of Christ is being denied by him. | Mark 8:38, Matt 10:32-33, Rom 1:16, Acts 5:41 |
| 11 | 2027-02-07 | Anger is murder | "Anger isn't a sin if I don't act on it." | Jesus equates anger in the heart with murder. Hatred for a brother is killing him in your heart. | Matt 5:21-26, 1 John 3:15, James 1:19-20 |
| 12 | 2027-03-07 | Take up your cross daily | "I committed to Christ years ago." | Discipleship is *daily.* The cross isn't a moment of conversion — it's the habit of choosing Christ over the self that wants the easier path, every day, until you die. | Luke 9:23, 1 Cor 15:31, Gal 2:20, Rom 6:6 |
| 13 | 2027-04-04 | That's someone's son | "He died for my sins" — as flat doctrine. | A son. A mother watched him be tortured to death. The Father sent him *knowing.* Stop and feel what you have stopped feeling. | John 19:25-27, Luke 2:35, John 3:16, Isa 53 |
| 14 | 2027-05-02 | Be fruitful and multiply | "Christianity is private. I don't push it on anyone." | God's first command was *multiply.* The modern Christian has settled into sterility — few disciples, often few kids, no investment. Your faith should reproduce. | Gen 1:28, Ps 127:3-5, Matt 28:19-20, John 15:8, 2 Tim 2:2 |

Order is not fixed — Adam may handpick the next Faith topic each cycle based on what he's been thinking and praying about.

**Strong runner-ups** (swap in if a theme hits):
- Bless the one who hurt you (Matt 5:43-48, Luke 6:27-36, Rom 12:14-21) — *originally Week 3; swapped out for "Miss the mark" on 2026-05-07. Still strong — pray for your abuser by name, do good while still bleeding.*
- Ice cream before every meal (Mark 12:31, Heb 12:5-11, 1 Cor 9:27, Prov 13:24) — *parental empathy as a self-discipline lens. You wouldn't let your kid eat ice cream before every meal — you love him too much. But you let yourself binge on whatever your version of ice cream is. You'd discipline your kid out of love; you won't discipline yourself. Faith-extreme: "love your neighbor as yourself" assumes you actually love yourself well — most of us love our kids well and ourselves badly. Title preference confirmed; sister-piece in spirit to W13 ("That's someone's son") — that one uses parental love to measure the Father's grief; this one uses it to measure your self-neglect.*
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
| 2026-05-17 | Rest #1 (The bread that breeds worms) ✅ published |
| 2026-05-24 | Delight #1 |
| 2026-05-31 | Faith #2 (Mourn in the present tense) ✅ drafted |
| 2026-06-07 | Grace #2 |
| 2026-06-14 | Rest #2 |
| 2026-06-21 | Delight #2 |
| 2026-06-28 | Faith #3 (Miss the mark) ✅ published |
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

### Week 3 — Miss the mark (2026-06-28)

The reframe: most Christians treat sin as a moralistic checklist — "I haven't murdered, stolen, or committed adultery, so I'm fine." The Greek word *hamartia* (ἁμαρτία) is an archery word — *to miss the mark.* Paul stacks two archery words in Rom 3:23: *all have sinned* (hamartia) *and come short* (hystereō) *of the glory of God.* The bullseye is not "don't do the bad stuff" — it's the glory of God, and Christ is the only one who hit it (Heb 4:15).

Lead with: the comfortable Christian's daily ledger — didn't murder, didn't steal, didn't lie (much), didn't commit adultery, didn't get drunk. The internal scoreboard that grades you against the murderer on the news. The respectable Christian who passes the rules-tally and never notices the arrow is in the dirt.

The pivot via the Pharisee and the tax collector (Luke 18:9-14): the Pharisee aimed at *being better than the tax collector* and hit it every time. The tax collector knew his arrow was nowhere near the gold. Only one went home justified. The Pharisee was hitting the wrong target — one he had drawn on the wall himself.

**I anchor possibilities:** *"I am not a bad person. I have used this sentence as a defense."* / *"I have spent my life not breaking the big rules. I have called that holiness."* / *"I have been winning the wrong game."*

Anchor verses: Rom 3:23 (*hamartia* + *hystereō* — both archery), Heb 4:15 (Christ tempted, yet without sin — the only arrow that found the gold), Matt 5:48 (*teleios* — complete/hitting-the-goal), Luke 18:9-14 (Pharisee/tax collector). Closing: 1 Pet 3:18 (the just for the unjust), Rom 8:1 (no condemnation in Christ).

End the empathy+Bible mix on: *"I'm not a bad person"* is a sentence from another religion — the religion of comparison. The Christian sentence is the tax collector's: *God be merciful to me a sinner.* Saying it once, and meaning it, is the door into a different scoring system entirely — Christ's arrow is the one God measures.

**CoC framing:** close with "in him, in the obedience of faith" — keep grace + obedience as two halves of the whole (Matt Bassford's phrasing). Don't collapse into "just believe" or "just call." The arrow keeps falling short *after* you come into him; daily repentance is part of walking with Christ.

**Matt Bassford research (TODO before final edit):** likely-rich themes — "Grace despite disgust" (theme #3), self-righteousness, his unflinching seriousness about the gospel as wound-then-heal. Search the archive for posts on Romans 3:23, the Pharisee/tax collector, and "good person." Borrow phrasing if anything fits.

Prayer: returns to the bold subtitle as refrain — *"I am not a bad person. I have used this sentence as a defense for as long as I can remember."* Closes with re-aim, walking in him, his score not mine.

### Week 13 — That's someone's son (2027-04-04, week after Easter)

The reframe: most Christians have abstracted the cross into theology. *"He died for my sins."* Said often enough, it stops landing. The pivot: Jesus had a mother. Mary stood at the foot of the cross (John 19:25-27) and watched her son be tortured to death — fulfilling Simeon's prophecy from 33 years earlier that a sword would pierce through her own soul (Luke 2:35). The Father sent him *knowing.* Whatever you can imagine about watching your own son die, that is what the Father chose. John 3:16: *"For God so loved the world that he gave his only begotten Son."* The verb is *gave.* He handed his son over.

The "week after Easter" slot is intentional — most Easter services skip from the empty tomb to brunch reservations. This devotional sits in what got skipped: the cost on the way to the resurrection.

Lead with: the comfortable Christian who can say *"Christ died for our sins"* without flinching. The flat way the crucifixion lives in your head — a doctrinal coordinate, not a scene. The Sunday school flannelgraph. The Easter service that resolves too quickly.

Concrete sensory pivots: imagine your son. The soldiers stripping him. The nails. His mother in the crowd. Don't theologize past it — sit in it.

**Parental-imagination beat (load-bearing for this draft):** use the universal parental impulse to measure what the Father actually did. *"You wouldn't let your kid skin his knee if you could prevent it. You'd take the fall instead of him. You'd run into traffic. You'd bleed first. Now imagine handing your kid over to soldiers. Choosing the nails. Choosing not to intervene when he cried out."* The reader's own parental love — real, imagined, or remembered from their own father — becomes the measuring rod for the Father's love and the gravity of sin. *That* is what John 3:16 means by *gave.* Adam heard this angle from a sermon; keep the empathic logic load-bearing in the draft, not decorative.

**I anchor possibilities:** *"I have learned to say 'He died for my sins' without flinching. I have forgotten that's someone's son."* / *"I have read the crucifixion as theology. I have not read it as grief."* / *"I have not let it cost me what it cost her."*

Anchor verses: John 19:25-27 (*"Now there stood by the cross of Jesus his mother"* — three sentences in scripture; sit with them), Luke 2:35 (*"a sword shall pierce through thy own soul"* — Simeon to Mary in the temple, 33 years before the sword arrived), John 3:16 (the Father *gave* — the cost is in the verb), Isaiah 53:3-5 (the suffering servant), Matt 27:46 (*"My God, my God, why hast thou forsaken me?"* — the Father turning).

**CoC framing:** Mary is biblical, not Marian. She was the mother of Jesus and she watched him die — that's narrative, not Mariology. Don't pray to her. Don't elevate her. *Do* let yourself feel the sword Simeon promised. Her grief is a window into the Father's grief.

End the empathy+Bible mix on: the cost on the *Father's* side. The triune God grieving the death of the Son. The hidden weight of *"he gave his only begotten."* That is what your sin cost — not an abstract debt, but a son.

**Matt Bassford research (TODO before final edit):** Matt wrote often on the cross and on the cost of discipleship. Search for posts on the crucifixion narrative, John 3:16 specifically, and Mary at the cross. His eschatological frame (world-broken / hope-elsewhere) likely pairs well here — the cross is the wound through which the hope arrives.

Prayer: returns to the bold subtitle as refrain. Specific request for the heart to feel what it has stopped feeling. End softer than usual — this devotional has done its wounding in the body; the prayer should let the reader sit, not strive.

### Week 14 — Be fruitful and multiply (2027-05-02)

The reframe: God's first command, given to humanity in the garden before sin, was *be fruitful and multiply* (Gen 1:28). Repeated to Noah after the flood. Echoed in the Great Commission (Matt 28:19) — make disciples of all nations. The biblical posture is *multiplication.* The modern Christian has quietly settled into sterility in every direction — few disciples, often few children, no spiritual investment in the next generation. Christianity has become a private consumption good. The first command says it was never supposed to be.

Lead with: the church member who's been faithful for 20 years and never led anyone to Christ. The couple who decided two was enough and never thought hard about it. The Bible app read alone in bed. The faith that has nowhere to go because you never planted it anywhere. The quiet assumption that your salvation is a private possession.

**The squeeze** (both halves carry weight, but spiritual fruit does the heavier lifting):
- **Spiritual sterility**: when did you last share the gospel? When did you last disciple someone? When did you last cause faith to multiply? Paul to Timothy: *"the things that thou hast heard of me among many witnesses, the same commit thou to faithful men, who shall be able to teach others also"* (2 Tim 2:2) — four generations in one verse.
- **Physical fruitlessness**: not a guilt trip, not a contraception screed — a question. Are children, in your imagination, a *blessing* (Ps 127:3-5) or a *cost*? The Christian view is the former. The cultural default is the latter. Which one is shaping your decisions?

**I anchor possibilities:** *"I have been a Christian for years and made no Christians."* / *"My faith has reproduced in no one."* / *"I have called my faith private. The first command called it multiplication."*

Anchor verses: Gen 1:28 (the first command — be fruitful, multiply, fill, subdue), Ps 127:3-5 (children are an heritage of the LORD), Matt 28:19-20 (Great Commission as spiritual multiplication), John 15:8 (*"herein is my Father glorified, that ye bear much fruit"*), 2 Tim 2:2 (four generations of discipling in one verse).

**CoC framing:** stay clear of advocating against contraception — CoC has no official teaching here, and this is personal-conviction territory. The strongest indictment is the spiritual sterility side. The physical side opens the question without prescribing the answer. Frame: *"the cultural default has shaped you more than you noticed."* Don't shame the infertile, the single, or those with smaller families — *fruit* in scripture is broader than offspring (Phil 1:22, Rom 1:13).

**Matt Bassford research (TODO before final draft):** Matt wrote extensively on personal evangelism, discipleship, and the church as a multiplying body. Search the archive for posts on evangelism reluctance, "private faith," and the Great Commission. Likely rich anchor material; his late-voice work on the church's mission is the place to start.

End the empathy+Bible mix on: the question is not *am I a good Christian.* The question is *has my faith reproduced.* The first command and the last both say *multiply.*

Prayer: short, specific. Names the sterility honestly. Asks for fruitfulness in whatever direction God appoints — children, disciples, both, or fruit in unexpected forms.

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
├── 03-miss-the-mark.md                 # week 3 (published 2026-06-28)
├── ...
└── archive/                            # published markdown after edits, for reference
```

---

## Reference

- Skill: `skills/custom-devotional-crafter/` (Claude Code also sees it through `.claude/skills/`)
- Format guide: `skills/custom-devotional-crafter/references/format-guide.md`
- Matt Bassford research skill: `skills/matt-bassford/` (use for theme research, voice borrows, theological pushback flags)
- Engagement dashboard: https://us.posthog.com/project/335021/dashboard/1512720
