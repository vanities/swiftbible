package biz.am2.swiftbible.data.history

object SplitsHistory {

    val splitsChalcedon = HistoryArticle(
        id = "splits-chalcedon",
        title = "451 — The Council of Chalcedon",
        subtitle = "An older split: how the Oriental Orthodox went their own way.",
        era = "451 AD",
        estimatedMinutes = 5,
        body = listOf(
            BodyBlock.Paragraph("Six centuries before the East-West Schism of 1054, an earlier and equally important rupture took place at the Council of Chalcedon in 451 AD. The dispute centered on a question that had occupied Christian theologians for decades: how exactly are the divine and human natures of Christ related?"),
            BodyBlock.Heading("The question"),
            BodyBlock.Paragraph("All sides agreed that Jesus Christ is both fully God and fully human. They disagreed on how to articulate the relationship between his divinity and humanity in technical theological language. Two schools of thought, associated with the great Eastern cities of Antioch and Alexandria, had been debating the matter for nearly a century."),
            BodyBlock.Heading("The Chalcedonian Definition"),
            BodyBlock.Paragraph("The Council of Chalcedon, attended by some 520 bishops, adopted a formula stating that Christ is 'one and the same Son… acknowledged in two natures, without confusion, without change, without division, without separation.' This phrasing — sometimes called the dyophysite (two-nature) formula — became the Christological standard for the churches of Rome and Constantinople, and through them for nearly all later Western Christianity."),
            BodyBlock.Heading("Who left"),
            BodyBlock.Paragraph("A significant portion of the Eastern church rejected the Chalcedonian formula. They preferred to speak of 'one nature of the Word incarnate' — a phrase from Cyril of Alexandria, the great Eastern theologian. Their critics accused them of confusing or merging Christ's divinity and humanity (monophysitism); they replied that they affirmed both fully but believed the Chalcedonian language risked separating them."),
            BodyBlock.Heading("The Oriental Orthodox today"),
            BodyBlock.Paragraph("The churches that rejected Chalcedon are today known collectively as the Oriental Orthodox Communion. They include:"),
            BodyBlock.BulletList(listOf(
                    "Coptic Orthodox Church of Egypt (~10 million members).",
                    "Ethiopian Orthodox Tewahedo Church (~50 million).",
                    "Eritrean Orthodox Tewahedo Church.",
                    "Syriac Orthodox Church.",
                    "Malankara Orthodox Syrian Church of India.",
                    "Armenian Apostolic Church (~9 million)."
            )),
    BodyBlock.Heading("Modern reconciliation"),
    BodyBlock.Paragraph("Modern theological dialogue between Eastern Orthodox and Oriental Orthodox churches in the twentieth century concluded that the historical dispute may have been more about terminology than substance. Joint declarations from the 1980s and 1990s affirmed that both communions hold the same Christological faith expressed in different theological idioms. Formal communion has not been restored, but the relationship is closer than at any point since 451.")
    ),
    pullQuotes = listOf(
        PullQuote(
            text = "We… confess one and the same Christ, Son, Lord, Only-begotten, in two natures, without confusion, without change, without division, without separation.",
            attribution = "The Definition of Chalcedon",
            context = "451 AD"
        )
    ),
    sources = listOf(
        HistorySource(title = "Council of Chalcedon", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Council_of_Chalcedon", note = null),
        HistorySource(title = "Oriental Orthodoxy", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Oriental_Orthodox_Churches", note = null),
        HistorySource(title = "The Definition of Chalcedon", author = null, kind = SourceKind.PRIMARY, url = null, note = "Conciliar text, 451 AD."),
        HistorySource(title = "Christ in Eastern Christian Thought", author = "John Meyendorff", kind = SourceKind.SCHOLARLY, url = null, note = "St. Vladimir's Seminary Press, 1969.")
    ),
    related = listOf("splits-1054", "denominations-comparison")
    )



    val splits1054 = HistoryArticle(
        id = "splits-1054",
        title = "1054 — The East/West Schism",
        subtitle = "How the Greek and Latin halves of Christendom became two churches.",
        era = "1054 AD",
        estimatedMinutes = 6,
        body = listOf(
            BodyBlock.Paragraph("The traditional date for the split between Catholic and Orthodox Christianity is July 16, 1054. On that day, papal legates from Rome — led by Cardinal Humbert — laid a bull of excommunication on the altar of the Hagia Sophia in Constantinople against Patriarch Michael Cerularius. The patriarch responded with his own anathemas. Both excommunications were technically against individuals, not against entire churches, but the symbolic weight was enormous, and the rupture proved permanent."),
            BodyBlock.Heading("Why it happened"),
            BodyBlock.Paragraph("The 1054 events were the climax of pressures that had been building for centuries. The Roman Empire had effectively split into two halves — the Latin-speaking West, increasingly dominated by Rome, and the Greek-speaking East, centered on Constantinople. Language, culture, liturgy, theology, and politics drifted apart. By 1054, two profoundly different Christian cultures could not always understand each other."),
            BodyBlock.Heading("The theological flashpoints"),
            BodyBlock.BulletList(listOf(
                    "The Filioque clause. Western churches had added the phrase 'and the Son' (Latin: Filioque) to the Nicene Creed, describing the Spirit as proceeding 'from the Father and the Son.' Eastern churches considered the addition both theologically wrong and procedurally illegitimate — no one had the authority to alter an ecumenical creed unilaterally.",
                    "Papal authority. Rome claimed the bishop of Rome held universal jurisdiction over all Christians. The East accepted Rome as a senior patriarchate ('first among equals') but rejected supreme authority over the other ancient sees of Constantinople, Alexandria, Antioch, and Jerusalem.",
                    "Liturgical practice. The West used unleavened bread (azymes) for the Eucharist; the East used leavened bread. Western priests were required to be celibate; Eastern priests could be married before ordination.",
                    "Political tensions. The crowning of Charlemagne as 'Holy Roman Emperor' in 800 — by the pope, in defiance of the actual emperor in Constantinople — had already strained relations badly."
            )),
    BodyBlock.Heading("What happened next"),
    BodyBlock.Paragraph("For roughly a century after 1054, ordinary Christians continued to participate in each other's churches. The breach hardened into something irreparable in 1204, when Crusaders sacked Constantinople, looted the city, and installed a Latin patriarch. Eastern Christians never forgot. Reunion attempts at the Second Council of Lyons (1274) and the Council of Florence (1439) produced agreements that were rejected by the Eastern population."),
    BodyBlock.Heading("Today"),
    BodyBlock.Paragraph("In 1965, Pope Paul VI and Patriarch Athenagoras formally lifted the mutual excommunications of 1054. The two churches remain separated, but dialogue continues. The Eastern Orthodox Church today comprises about 220 million members, organized as a communion of self-governing (autocephalous) churches — Greek, Russian, Romanian, Bulgarian, Serbian, and others — that share liturgy, doctrine, and sacraments while governing themselves locally.")
    ),
    pullQuotes = listOf(
        PullQuote(
            text = "The unity which we have lost we wish to find.",
            attribution = "Pope Paul VI",
            context = "Tomos Agapis, 1965 — at the lifting of the mutual excommunications"
        )
    ),
    sources = listOf(
        HistorySource(title = "East–West Schism", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/East%E2%80%93West_Schism", note = null),
        HistorySource(title = "Filioque", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Filioque", note = null),
        HistorySource(title = "The Eastern Schism", author = "Steven Runciman", kind = SourceKind.SCHOLARLY, url = null, note = "Oxford, 1955."),
        HistorySource(title = "East and West: The Making of a Rift in the Church", author = "Henry Chadwick", kind = SourceKind.SCHOLARLY, url = null, note = "Oxford, 2003.")
    ),
    related = listOf("splits-chalcedon", "splits-reformation", "denominations-comparison")
    )



    val splitsReformation = HistoryArticle(
        id = "splits-reformation",
        title = "1517 — The Reformation",
        subtitle = "A monk's protest that fractured Western Christianity into hundreds of pieces.",
        era = "1517 — 1648 AD",
        estimatedMinutes = 7,
        body = listOf(
            BodyBlock.Paragraph("On October 31, 1517, an Augustinian monk and university professor named Martin Luther sent a letter to his archbishop objecting to the sale of indulgences in Germany. Tradition says he also nailed his 95 theses to the door of the Castle Church in Wittenberg — a standard way of advertising an academic disputation. Within a few years, what began as a local theological argument had set Western Europe on a course of religious, political, and cultural upheaval that lasted more than a century."),
            BodyBlock.Heading("The immediate trigger"),
            BodyBlock.Paragraph("Indulgences were certificates promising the remission of temporal punishment for sin, traditionally granted in connection with acts of penance. By the early 1500s, particularly in Germany, indulgences were being sold to fund building projects — most notoriously, the rebuilding of St. Peter's Basilica in Rome. Luther's 95 theses attacked the practice as a corruption of the gospel. Other concerns rapidly followed: clerical corruption, the wealth of the church, the sale of offices, and theological questions about authority and salvation."),
            BodyBlock.Heading("Luther's core claims"),
            BodyBlock.Paragraph("As the dispute escalated, Luther articulated several positions that became the rallying points of the broader Protestant Reformation:"),
            BodyBlock.BulletList(listOf(
                    "Sola scriptura — Scripture alone is the final, infallible authority for Christian faith and life.",
                    "Sola fide — justification is by faith alone, not through any human work or merit.",
                    "Sola gratia — salvation is by God's grace alone.",
                    "Solus Christus — Christ alone mediates between God and humanity, without secondary mediators.",
                    "Soli Deo gloria — all glory belongs to God alone."
            )),
    BodyBlock.Heading("Multiple reformations"),
    BodyBlock.Paragraph("The Reformation was not a single movement. Within a generation, several distinct streams emerged:"),
    BodyBlock.BulletList(listOf(
            "Lutheran — Germany and Scandinavia; high view of sacraments, confessional creeds (Augsburg Confession, 1530).",
            "Reformed/Calvinist — Switzerland (Zwingli, then Calvin in Geneva), spreading to France, the Netherlands, Scotland, and parts of Germany; emphasized God's sovereignty and a thoroughly biblical worship.",
            "Anglican — England, where Henry VIII broke with Rome in 1534 over the annulment of his marriage; later developed a via media between Catholicism and Protestantism.",
            "Anabaptist ('Radical Reformation') — small communities that rejected infant baptism in favor of believer's baptism, and often pacifism and separation of church and state."
    )),
    BodyBlock.Heading("The Catholic response"),
    BodyBlock.Paragraph("The Catholic Church's response is conventionally called the Counter-Reformation. The Council of Trent (1545–1563) clarified Catholic doctrine on Scripture, tradition, justification, and the sacraments — and rejected the major Protestant positions. New religious orders, especially the Jesuits, led missionary and educational efforts. Internal reforms tackled abuses Luther and others had criticized."),
    BodyBlock.Heading("Long-term outcomes"),
    BodyBlock.Paragraph("The Reformation permanently fragmented Western Christianity. Wars of religion devastated Central Europe through the Thirty Years' War (1618–1648), which ended with the Peace of Westphalia and the principle that each prince could determine the religion of his territory. Hundreds of Protestant denominations now exist worldwide. Catholics number about 1.3 billion; Protestants of all kinds, roughly 800–900 million.")
    ),
    pullQuotes = listOf(
        PullQuote(
            text = "Unless I am convinced by Scripture and plain reason — I do not accept the authority of popes and councils, for they have contradicted each other — my conscience is captive to the Word of God.",
            attribution = "Martin Luther",
            context = "before the Diet of Worms, 1521 (traditional wording)"
        )
    ),
    sources = listOf(
        HistorySource(title = "Reformation", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Reformation", note = null),
        HistorySource(title = "Martin Luther", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Martin_Luther", note = null),
        HistorySource(title = "Five solae", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Five_solae", note = null),
        HistorySource(title = "The Reformation: A History", author = "Diarmaid MacCulloch", kind = SourceKind.SCHOLARLY, url = null, note = "Penguin, 2003."),
        HistorySource(title = "Luther: Man Between God and the Devil", author = "Heiko A. Oberman", kind = SourceKind.SCHOLARLY, url = null, note = "Yale University Press, 1989.")
    ),
    related = listOf("splits-1054", "denominations-comparison", "denominations-restoration")
    )


    val splits = HistorySection(
        id = "splits",
        title = "The Great Splits",
        subtitle = "Three ruptures that shaped today's Christian map.",
        era = "451 — 1648 AD",
        emoji = "🔀",
        articles = listOf(splitsChalcedon, splits1054, splitsReformation)
    )
}
