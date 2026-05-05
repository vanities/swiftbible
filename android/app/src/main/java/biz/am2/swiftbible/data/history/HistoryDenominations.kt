package biz.am2.swiftbible.data.history

object DenominationsHistory {

    val denominationsComparison = HistoryArticle(
        id = "denominations-comparison",
        title = "Comparison Matrix",
        subtitle = "Catholics, Orthodox, Protestants, and Restorationists at a glance.",
        era = "Modern",
        estimatedMinutes = 5,
        body = listOf(
            BodyBlock.Paragraph("The world's roughly 2.4 billion Christians belong to thousands of distinct churches and denominations. They share a common confession of Jesus Christ as Lord and the same New Testament Scripture. They differ on questions of authority, sacraments, church government, worship style, and historical lineage. The list below summarizes the major branches."),
            BodyBlock.Heading("Quick reference"),
            BodyBlock.Paragraph("This is a simplification — every category has internal variety, and individual congregations may not match every detail of their tradition. It is meant to orient, not to define."),
            BodyBlock.BulletList(listOf(
                    "Roman Catholic. ~1.3 billion. Pope, hierarchical bishops. Seven sacraments. Authority: Scripture + Sacred Tradition + Magisterium. Real presence (transubstantiation). Infant baptism.",
                    "Eastern Orthodox. ~220 million. No pope; communion of self-governing patriarchates. Seven mysteries (sacraments). Authority: Scripture + Tradition + Ecumenical Councils. Real presence (mystery, not transubstantiation). Infant baptism by immersion.",
                    "Oriental Orthodox. ~60 million. Coptic, Armenian, Ethiopian, Syriac, Indian Malankara. Rejected Chalcedon (451). Otherwise similar to Eastern Orthodox in liturgy and sacraments.",
                    "Anglican / Episcopal. ~85 million. Bishops, Book of Common Prayer. Two-to-seven sacraments depending on stream. Real presence affirmed in many forms. Infant baptism.",
                    "Lutheran. ~75 million. Bishops or congregational governance depending on region. Two sacraments. Real presence ('in, with, and under'). Infant baptism. Book of Concord (1580) confessional.",
                    "Reformed / Presbyterian. ~75 million. Elder-led (presbyteries). Two sacraments. Spiritual real presence. Infant baptism. Westminster Confession.",
                    "Methodist. ~80 million. Bishops or conferences. Two sacraments. Spiritual real presence. Infant baptism. Wesleyan emphasis on sanctification.",
                    "Baptist. ~100 million. Congregational. Two ordinances. Memorial Lord's Supper. Believer's baptism by immersion only.",
                    "Pentecostal / Charismatic. ~280 million (the fastest-growing branch). Varies. Two ordinances. Memorial. Believer's baptism. Emphasis on gifts of the Spirit.",
                    "Restoration Movement (a cappella Churches of Christ). ~2 million. Autonomous congregations, elders/deacons. Two ordinances. Memorial. Believer's baptism by immersion (often understood as for remission of sins). No instrumental music. 'No creed but Christ.'",
                    "Non-denominational. Several hundred million globally. Independent congregations, often Baptist or charismatic in practice."
            )),
    BodyBlock.Heading("Where the lines are drawn"),
    BodyBlock.Paragraph("Several axes recur in these comparisons. Authority — Scripture alone, or Scripture plus Tradition? Sacraments — channels of grace, or symbolic ordinances? Government — bishops, elders, or congregational autonomy? Baptism — infants or believers? Lord's Supper — real presence (in some sense) or memorial only? Worship — liturgical or free-form? Each tradition takes a position on most of these questions, and the positions tend to cluster historically and geographically.")
    ),
    pullQuotes = listOf(),
    sources = listOf(
        HistorySource(title = "List of Christian denominations", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/List_of_Christian_denominations", note = null),
        HistorySource(title = "Christian denomination", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Christian_denomination", note = null),
        HistorySource(title = "Global Christianity: A Report on the Size and Distribution of the World's Christian Population", author = "Pew Research Center", kind = SourceKind.SCHOLARLY, url = null, note = "Pew Research, 2011."),
        HistorySource(title = "World Christian Encyclopedia", author = "Todd M. Johnson and Gina A. Zurlo (eds.)", kind = SourceKind.SCHOLARLY, url = null, note = "Edinburgh University Press, 3rd ed., 2020.")
    ),
    related = listOf("denominations-overview", "denominations-restoration", "splits-reformation", "splits-1054")
    )



    val denominationsOverview = HistoryArticle(
        id = "denominations-overview",
        title = "Catholic, Orthodox, Protestant",
        subtitle = "How the three great branches differ in authority, worship, and outlook.",
        era = "Modern",
        estimatedMinutes = 5,
        body = listOf(
            BodyBlock.Paragraph("Most of the world's Christians belong to one of three great branches: Catholic, Orthodox (Eastern or Oriental), or Protestant. The three differ in important ways, but they also share more than is sometimes recognized — the same Scripture, the same creeds (with the contested Filioque clause), the same Lord, and the same basic moral teaching."),
            BodyBlock.Heading("Roman Catholic"),
            BodyBlock.Paragraph("The Catholic Church is the largest body of Christians in the world. It traces unbroken episcopal succession to the apostles and recognizes the bishop of Rome (the pope) as the visible head of the church on earth. Its theology is articulated through Scripture, Sacred Tradition, and the teaching authority (Magisterium) of the bishops in communion with the pope. Catholic worship is liturgical, sacramental, and centered on the Mass. The Catholic moral and intellectual tradition has shaped Western civilization profoundly through universities, hospitals, art, and philosophy."),
            BodyBlock.Heading("Eastern Orthodox"),
            BodyBlock.Paragraph("Eastern Orthodoxy regards itself as the original church preserved unchanged from the apostles. It is structured as a communion of self-governing patriarchates and national churches that share the same faith, sacraments, and liturgy without a single central authority. The Divine Liturgy of St. John Chrysostom — sung, incensed, surrounded by icons — has been celebrated in essentially the same form for over a thousand years. Orthodox theology emphasizes mystery, deification (theosis), and the unity of body and spirit in worship."),
            BodyBlock.Heading("Protestant"),
            BodyBlock.Paragraph("Protestant Christianity is not a single church but a family of traditions stemming from the Reformation. Its unifying convictions are sola scriptura (Scripture alone as final authority), sola fide (justification by faith alone), and the priesthood of all believers. Within that frame, Protestants vary enormously: from highly liturgical Anglicans and Lutherans to spontaneous Pentecostal worship; from infant-baptizing Reformed churches to immersionist Baptists; from connectional Methodists to autonomous congregational churches. The label covers thousands of distinct denominations."),
            BodyBlock.Heading("Where they overlap"),
            BodyBlock.Paragraph("All three branches confess the Trinity, the divinity and humanity of Christ, the bodily resurrection of Jesus, the inspiration of Scripture, and the future return of Christ. All three baptize and celebrate the Lord's Supper in some form. All three teach the necessity of faith and grace for salvation, even when they describe the relationship differently."),
            BodyBlock.Heading("Where they differ"),
            BodyBlock.Paragraph("They differ on the role of tradition alongside Scripture, the structure of church authority, the number and nature of the sacraments, the practice of infant versus believer's baptism, the use of images and icons in worship, the veneration of saints (especially Mary), and the precise theology of the Eucharist. These differences are real and deeply held, and they have shaped distinct cultures of prayer, art, and life.")
        ),
    pullQuotes = listOf(
        PullQuote(
            text = "What unites us is greater than what divides us.",
            attribution = "Pope John XXIII",
            context = "phrase widely used in 20th-century ecumenical dialogue"
        )
    ),
    sources = listOf(
        HistorySource(title = "Catholic Church", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Catholic_Church", note = null),
        HistorySource(title = "Eastern Orthodox Church", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Eastern_Orthodox_Church", note = null),
        HistorySource(title = "Protestantism", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Protestantism", note = null),
        HistorySource(title = "The Orthodox Church", author = "Timothy (Kallistos) Ware", kind = SourceKind.SCHOLARLY, url = null, note = "Penguin, 1963; rev. 1993."),
        HistorySource(title = "The New Shape of World Christianity", author = "Mark A. Noll", kind = SourceKind.SCHOLARLY, url = null, note = "InterVarsity, 2009.")
    ),
    related = listOf("denominations-comparison", "denominations-restoration", "splits-1054", "splits-reformation")
    )



    val denominationsRestoration = HistoryArticle(
        id = "denominations-restoration",
        title = "The Restoration Movement",
        subtitle = "A 19th-century American attempt to recover the New Testament church.",
        era = "1800 — present",
        estimatedMinutes = 6,
        body = listOf(
            BodyBlock.Paragraph("In the early nineteenth century, several American Christian leaders independently came to a similar conclusion: the divisions of Protestantism could be healed only by setting aside denominational creeds and human traditions and returning to the Bible alone, especially the New Testament pattern of the church. The convergence of these movements is conventionally called the Restoration Movement or the Stone-Campbell Movement, after two of its central figures."),
            BodyBlock.Heading("Origins"),
            BodyBlock.Paragraph("Barton W. Stone, a Presbyterian minister in Kentucky, led the famous Cane Ridge Revival of 1801 and afterward dissolved his presbytery, declaring that he and those with him would simply be 'Christians' — no other label. Independently, Thomas Campbell and his son Alexander Campbell, in Pennsylvania and West Virginia, articulated similar ideas, calling for unity on the basis of Scripture and forming churches that practiced believer's baptism by immersion. The Stone and Campbell movements merged in the 1830s."),
            BodyBlock.Heading("Core convictions"),
            BodyBlock.BulletList(listOf(
                    "Scripture alone, especially the New Testament, as the rule for church faith and practice.",
                    "No creed but Christ — rejection of binding human creeds and confessions.",
                    "Christian unity — believers should not divide over secondary matters.",
                    "Restoration of the New Testament church — recovering practice as well as doctrine.",
                    "Believer's baptism by immersion for the remission of sins.",
                    "Weekly Lord's Supper as a memorial.",
                    "Autonomous local congregations — no denominational hierarchy."
            )),
    BodyBlock.Heading("Internal divisions"),
    BodyBlock.Paragraph("The movement's commitment to unity has been complicated by its internal history of division. By 1906, the United States census recognized two distinct Restoration bodies: Churches of Christ (a cappella, generally more conservative) and Disciples of Christ / Christian Churches (instrumental, more open). In the twentieth century, the instrumental wing further divided into the more liberal Disciples of Christ and the more conservative independent Christian Churches. Within the a cappella Churches of Christ, further divisions arose over questions of institutional support (orphanages, colleges supported by the church treasury), the use of multiple cups in communion, premillennialism, Bible classes, and other matters."),
    BodyBlock.Heading("Today"),
    BodyBlock.Paragraph("The three main Restoration streams in the United States together include several million members. Globally, Churches of Christ are present in many countries through missionary efforts. The movement has produced a number of universities (Pepperdine, Abilene Christian, Lipscomb, Harding, and others) and a substantial body of biblical scholarship. Like all traditions, it continues to wrestle internally with questions of identity, growth, and how to relate to the wider Christian world."),
    BodyBlock.Heading("Where it fits"),
    BodyBlock.Paragraph("Sociologically, the Restoration Movement is usually grouped with American Protestantism, though many of its members reject denominational labels — including the label 'Protestant' — preferring to be called simply 'Christians' or 'members of the church of Christ.' Theologically it shares much with Baptist and other free-church traditions, while differing on points such as the role of baptism in salvation, weekly communion, and a cappella worship.")
    ),
    pullQuotes = listOf(
        PullQuote(
            text = "Where the Scriptures speak, we speak; and where the Scriptures are silent, we are silent.",
            attribution = "Thomas Campbell",
            context = "Declaration and Address, 1809"
        )
    ),
    sources = listOf(
        HistorySource(title = "Restoration Movement", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Restoration_Movement", note = null),
        HistorySource(title = "Churches of Christ", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Churches_of_Christ", note = null),
        HistorySource(title = "Declaration and Address", author = "Thomas Campbell", kind = SourceKind.PRIMARY, url = null, note = "1809; reprinted in many anthologies of the movement."),
        HistorySource(title = "The Encyclopedia of the Stone-Campbell Movement", author = "Douglas A. Foster et al. (eds.)", kind = SourceKind.SCHOLARLY, url = null, note = "Eerdmans, 2004."),
        HistorySource(title = "Reviving the Ancient Faith: The Story of Churches of Christ in America", author = "Richard T. Hughes", kind = SourceKind.SCHOLARLY, url = null, note = "Eerdmans, 1996.")
    ),
    related = listOf("denominations-comparison", "denominations-overview", "practices-baptism", "practices-government")
    )


    val denominations = HistorySection(
        id = "denominations",
        title = "Denominations Today",
        subtitle = "Catholic, Orthodox, Protestant, and the Restoration Movement.",
        era = "Modern",
        emoji = "👥",
        articles = listOf(denominationsComparison, denominationsOverview, denominationsRestoration)
    )
}
