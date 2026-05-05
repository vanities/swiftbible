package biz.am2.swiftbible.data.history

object PracticesHistory {

    val practicesBaptism = HistoryArticle(
        id = "practices-baptism",
        title = "Baptism — Infant or Believer?",
        subtitle = "How a single sacrament came to mean two very different things.",
        era = "30 AD — present",
        estimatedMinutes = 6,
        body = listOf(
            BodyBlock.Paragraph("Christian baptism originated with the practice of John the Baptist — a ritual immersion in the Jordan River expressing repentance and preparation for the coming Kingdom. Jesus was baptized by John, and after the resurrection his followers continued the practice in his name. The New Testament treats baptism as essential and transformative, but it does not explicitly settle the question that has divided later traditions: should infants be baptized, or only those old enough to profess faith for themselves?"),
            BodyBlock.Heading("What the New Testament says"),
            BodyBlock.Paragraph("The clearest New Testament passages describe baptism following faith and repentance: Peter's call at Pentecost ('Repent and be baptized,' Acts 2:38), the conversion of the Ethiopian eunuch (Acts 8), Paul's baptism (Acts 9), and the Philippian jailer's family (Acts 16). Several passages mention 'household' baptisms — Lydia's household (Acts 16:15), the Philippian jailer's household (Acts 16:33), Stephanas's household (1 Cor 1:16) — without specifying ages. Whether these households included infants is one of the central questions in the debate."),
            BodyBlock.Heading("Early church evidence"),
            BodyBlock.Paragraph("From the late second century onward, the historical record contains explicit references to infant baptism. Irenaeus (c. 180) speaks of Christ saving 'infants, and children, and boys, and youths, and old men' through baptism. Hippolytus's Apostolic Tradition (c. 215) gives liturgical directions: 'First baptize the small children. And each one who is able to speak for themselves, let them speak. But those not able to speak for themselves, let their parents or another one belonging to their family speak for them.' Origen (c. 240) attributes the practice to apostolic tradition."),
            BodyBlock.Heading("The Anabaptist objection"),
            BodyBlock.Paragraph("In the sixteenth century, the Anabaptist ('re-baptizer') movement of the Radical Reformation argued that infant baptism was not biblical and that only those who consciously profess faith should be baptized. They re-baptized adults who had been baptized as infants — an offense punishable by death under both Catholic and Protestant authorities of the time. Many Anabaptists were drowned in mockery of their convictions. Their descendants today include Mennonites, Hutterites, and Amish; their theological convictions on baptism shaped Baptists, Pentecostals, Restorationists, and most modern non-denominational evangelicals."),
            BodyBlock.Heading("The traditions today"),
            BodyBlock.BulletList(listOf(
                    "Infant baptism, by sprinkling or pouring: practiced by Catholic, Eastern Orthodox (by immersion), Oriental Orthodox, Anglican, Lutheran, Reformed/Presbyterian, and Methodist churches.",
                    "Believer's baptism, usually by immersion: practiced by Baptist, Pentecostal, Anabaptist (Mennonite, Amish), Restoration Movement (Churches of Christ), and most non-denominational evangelical churches."
            )),
    BodyBlock.Heading("Why it matters"),
    BodyBlock.Paragraph("The disagreement is not merely about timing. Behind it lie deeper questions: Is baptism the sign of God's covenant with believing families (parallel to Old Testament circumcision), or is it the personal seal of an individual's confessed faith? Is baptism itself an instrument of grace, or a public symbol of grace already received? Different answers shape how Christians understand the church, the family, and the relationship between faith and ritual. The disagreement remains, but most traditions now recognize each other's baptisms in some form, and ecumenical dialogue continues.")
    ),
    pullQuotes = listOf(
        PullQuote(
            text = "He came to save all by means of Himself — all, I say, who through Him are born again to God — infants, and children, and boys, and youths, and old men.",
            attribution = "Irenaeus of Lyons",
            context = "Against Heresies 2.22.4, c. 180 AD"
        )
    ),
    sources = listOf(
        HistorySource(title = "Infant baptism", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Infant_baptism", note = null),
        HistorySource(title = "Believer's baptism", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Believer%27s_baptism", note = null),
        HistorySource(title = "Anabaptism", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Anabaptism", note = null),
        HistorySource(title = "Apostolic Tradition", author = "Hippolytus of Rome", kind = SourceKind.PRIMARY, url = null, note = "c. 215 AD."),
        HistorySource(title = "Infant Baptism in the First Four Centuries", author = "Joachim Jeremias", kind = SourceKind.SCHOLARLY, url = null, note = "Westminster Press, 1962."),
        HistorySource(title = "Infant Baptism and the Covenant of Grace", author = "Paul K. Jewett", kind = SourceKind.SCHOLARLY, url = null, note = "Eerdmans, 1978.")
    ),
    related = listOf("denominations-restoration", "early-fathers")
    )



    val practicesLordsSupper = HistoryArticle(
        id = "practices-lords-supper",
        title = "The Lord's Supper — Symbol or Sacrament?",
        subtitle = "Memorial, real presence, and the long argument over what happens at the table.",
        era = "30 AD — present",
        estimatedMinutes = 6,
        body = listOf(
            BodyBlock.Paragraph("At the last supper before his crucifixion, Jesus took bread and wine, blessed them, and gave them to his disciples with the words, 'This is my body… this is my blood… do this in remembrance of me' (1 Cor 11:24–25). Christians have done this ever since. They have rarely agreed on exactly what is happening when they do."),
            BodyBlock.Heading("Earliest Christian language"),
            BodyBlock.Paragraph("The earliest extra-canonical references — the Didache (late first century), Ignatius (c. 107), Justin Martyr (c. 150), Irenaeus (c. 180) — speak of the bread and wine in vividly realistic terms. Ignatius calls the Eucharist 'the medicine of immortality.' Justin says the consecrated elements are 'the flesh and blood of that Jesus who was made flesh.' This realistic language remained dominant in Christian worship for over a thousand years across very different cultures."),
            BodyBlock.Heading("The Catholic doctrine of transubstantiation"),
            BodyBlock.Paragraph("Western theologians, drawing on Aristotle's distinction between substance and accidents, eventually formulated the doctrine of transubstantiation: at consecration, the underlying substance of the bread and wine becomes the body and blood of Christ, while the accidents (appearance, taste, texture) remain those of bread and wine. The doctrine was formally defined at the Fourth Lateran Council in 1215 and reaffirmed at the Council of Trent in 1551."),
            BodyBlock.Heading("The Reformation positions"),
            BodyBlock.BulletList(listOf(
                    "Lutheran — Christ's true body and blood are present 'in, with, and under' the bread and wine. Sometimes called the 'sacramental union' or popularly consubstantiation (a label Lutherans usually decline).",
                    "Reformed / Calvinist — Christ is truly but spiritually present to the believer in communion. The faithful receive Christ by faith through the Holy Spirit, even though Christ's body remains in heaven.",
                    "Zwinglian / Memorial — The Lord's Supper is a remembrance and proclamation of Christ's death. The bread and wine are signs and symbols, not channels of grace.",
                    "Anglican — Historically a broad church that has accommodated multiple views, with most congregations affirming a real spiritual presence."
            )),
    BodyBlock.Heading("Eastern Orthodox approach"),
    BodyBlock.Paragraph("Eastern Orthodox Christians affirm a real change of the bread and wine into Christ's body and blood, but they generally avoid the philosophical language of transubstantiation. Orthodox theology prefers to call the Eucharist a mystery: real, transformative, but not exhaustively explainable in human categories."),
    BodyBlock.Heading("Memorial in modern free churches"),
    BodyBlock.Paragraph("Most Baptist, Pentecostal, Restoration Movement, and non-denominational churches today teach a memorial view. The Lord's Supper is observed (weekly in Restoration churches, monthly or quarterly in many Baptist churches) as a remembrance of Christ's sacrifice and a proclamation of his death until he returns. Within this view, the bread and cup are not less important — they remain central to worship — but their power lies in what they represent and recall, not in any change to the elements themselves."),
    BodyBlock.Heading("Where the line falls"),
    BodyBlock.Paragraph("The deepest question is whether the Lord's Supper is something Christ does for the believer (the sacramental view) or something the believer does in remembrance of Christ (the memorial view). Most traditions blend the two emphases to some degree. The label 'real presence' is shared by most Catholic, Orthodox, Anglican, Lutheran, and Reformed Christians, even when the precise mechanism is described differently. The 'memorial' view is shared by most Baptist, Pentecostal, Restorationist, and non-denominational Christians. Both sides find their interpretation compatible with the New Testament texts.")
    ),
    pullQuotes = listOf(
        PullQuote(
            text = "Not as common bread or common drink do we receive these; but… the food which is blessed by the prayer of His word… is the flesh and blood of that Jesus who was made flesh.",
            attribution = "Justin Martyr",
            context = "First Apology 66, c. 150 AD"
        )
    ),
    sources = listOf(
        HistorySource(title = "Eucharistic theology", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Eucharistic_theology", note = null),
        HistorySource(title = "Transubstantiation", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Transubstantiation", note = null),
        HistorySource(title = "Memorialism", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Memorialism", note = null),
        HistorySource(title = "First Apology, ch. 66", author = "Justin Martyr", kind = SourceKind.PRIMARY, url = null, note = null),
        HistorySource(title = "Council of Trent, Session 13", author = null, kind = SourceKind.PRIMARY, url = null, note = "1551 — Catholic dogmatic statement on the Eucharist."),
        HistorySource(title = "This Is My Body: Luther's Contention for the Real Presence in the Sacrament of the Altar", author = "Hermann Sasse", kind = SourceKind.SCHOLARLY, url = null, note = "Augsburg, 1959.")
    ),
    related = listOf("early-eucharist", "denominations-comparison")
    )



    val practicesGovernment = HistoryArticle(
        id = "practices-government",
        title = "Church Government",
        subtitle = "Bishops, elders, congregations — three answers to who runs the church.",
        era = "30 AD — present",
        estimatedMinutes = 5,
        body = listOf(
            BodyBlock.Paragraph("From the earliest days, Christians have organized their churches in different ways. The New Testament uses several leadership terms — apostles, prophets, elders (presbyters), overseers (bishops), deacons, pastors, teachers — without leaving a single comprehensive blueprint for how a local church or a network of churches should be governed. Subsequent Christian history has produced three broad models."),
            BodyBlock.Heading("Episcopal — government by bishops"),
            BodyBlock.Paragraph("In an episcopal polity, the highest authority in the local region rests with bishops, who ordain priests (or presbyters) and deacons and oversee multiple congregations. Catholics, Orthodox, Anglicans/Episcopalians, Methodists in many regions, and most Lutherans (in Europe and Africa) operate episcopally. Bishops are typically understood as successors to the apostles in office. The Roman Catholic Church places the bishop of Rome (the pope) at the apex; the Eastern Orthodox have multiple patriarchs in communion without a single supreme head."),
            BodyBlock.Heading("Presbyterian — government by elders"),
            BodyBlock.Paragraph("A presbyterian polity vests authority in elected councils of elders (presbyters), who govern locally, regionally (presbyteries), and nationally (general assemblies). Each higher body is composed of representatives from the lower. Presbyterian and most Reformed churches use this model, drawing on Acts 15 and the New Testament references to councils of elders."),
            BodyBlock.Heading("Congregational — government by the local church"),
            BodyBlock.Paragraph("A congregational polity locates authority in the local congregation itself. Members select their own leaders (elders, deacons, pastors), set their own policies, and own their own property. Each congregation is autonomous; there is no denominational headquarters with binding authority. Baptists, Congregationalists, most non-denominational churches, and Restoration Movement Churches of Christ all use congregational government."),
            BodyBlock.Heading("Mixed and modified forms"),
            BodyBlock.Paragraph("Many churches blend elements of these models. The Methodist Church has bishops but also strong conferences. The Lutheran World Federation includes both episcopal and congregational expressions. Many large evangelical churches are nominally congregational but practically governed by a strong pastor. The lines between models are blurrier in practice than in theory."),
            BodyBlock.Heading("What the New Testament shows"),
            BodyBlock.Paragraph("All three traditions appeal to the New Testament. Episcopalians point to the apostles' authority and to early second-century evidence (Ignatius) for monarchical bishops. Presbyterians point to the council of elders in Acts 15 and to passages where overseer and elder appear interchangeable. Congregationalists point to the autonomy of local churches in the Pauline letters and to the priesthood of all believers. The strongest argument for each is the model's actual historical fruit: each has produced faithful, durable Christian communities.")
        ),
    pullQuotes = listOf(
        PullQuote(
            text = "From Miletus he sent to Ephesus and called for the elders of the church… Take heed therefore unto yourselves, and to all the flock, over the which the Holy Ghost hath made you overseers.",
            attribution = "Acts 20:17, 28",
            context = "King James Version"
        )
    ),
    sources = listOf(
        HistorySource(title = "Episcopal polity", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Episcopal_polity", note = null),
        HistorySource(title = "Presbyterian polity", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Presbyterian_polity", note = null),
        HistorySource(title = "Congregationalist polity", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Congregationalist_polity", note = null),
        HistorySource(title = "Perspectives on Church Government: Five Views of Church Polity", author = "Chad Owen Brand and R. Stanton Norman (eds.)", kind = SourceKind.SCHOLARLY, url = null, note = "B&H Academic, 2004.")
    ),
    related = listOf("early-bishops", "denominations-comparison", "denominations-restoration")
    )


    val practices = HistorySection(
        id = "practices",
        title = "Practices Through History",
        subtitle = "Baptism, the Lord's Supper, and how the church has been governed.",
        era = "30 AD — present",
        emoji = "🙏",
        articles = listOf(practicesBaptism, practicesLordsSupper, practicesGovernment)
    )
}
