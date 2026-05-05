package biz.am2.swiftbible.data.history

object FurtherReadingHistory {

    val sourcesPrimary = HistoryArticle(
        id = "sources-primary",
        title = "Primary Sources",
        subtitle = "Where to read the early Christian voices for yourself.",
        era = "Reference",
        estimatedMinutes = 4,
        body = listOf(
            BodyBlock.Paragraph("One of the best ways to think clearly about church history is to read the original voices, not just summaries of them. Most of the major early Christian writings are available in English translation online for free, often in nineteenth-century translations that are still standard. The list below is a starting point, organized by author and where to find the texts."),
            BodyBlock.Heading("Apostolic Fathers"),
            BodyBlock.Paragraph("The earliest non-canonical Christian writings, dated roughly 70–150 AD. Translations of all of them are collected at New Advent (newadvent.org/fathers) and at the Christian Classics Ethereal Library (ccel.org)."),
            BodyBlock.BulletList(listOf(
                    "1 Clement — letter from the church at Rome to Corinth, c. 96 AD.",
                    "Letters of Ignatius of Antioch — seven short letters, c. 107 AD.",
                    "Letter of Polycarp to the Philippians — c. 110 AD.",
                    "The Didache — early Christian church manual.",
                    "The Shepherd of Hermas — Roman apocalypse, c. 100–150 AD.",
                    "Martyrdom of Polycarp — earliest extra-biblical martyrdom account, c. 155 AD."
            )),
    BodyBlock.Heading("Apologists & Theologians (2nd–4th centuries)"),
    BodyBlock.BulletList(listOf(
            "Justin Martyr — First Apology, Second Apology, Dialogue with Trypho.",
            "Irenaeus of Lyons — Against Heresies (5 books).",
            "Tertullian — Apology, Against Marcion, On Baptism.",
            "Origen — On First Principles, Against Celsus.",
            "Eusebius of Caesarea — Ecclesiastical History, the indispensable early church history.",
            "Athanasius — On the Incarnation, Festal Letters.",
            "Augustine — Confessions, City of God, On Christian Doctrine.",
            "John Chrysostom — Homilies on the New Testament."
    )),
    BodyBlock.Heading("Councils & Creeds"),
    BodyBlock.BulletList(listOf(
            "The Apostles' Creed — earliest baptismal creed.",
            "The Nicene Creed (325 AD, expanded 381) — central confession of the great councils.",
            "Definition of Chalcedon (451 AD) — Christological formula.",
            "Acts of the seven Ecumenical Councils — Nicaea I (325), Constantinople I (381), Ephesus (431), Chalcedon (451), Constantinople II (553), Constantinople III (681), Nicaea II (787)."
    )),
    BodyBlock.Heading("Reformation primary texts"),
    BodyBlock.BulletList(listOf(
            "Martin Luther's 95 Theses (1517).",
            "Augsburg Confession (1530) — Lutheran.",
            "Calvin's Institutes of the Christian Religion.",
            "Westminster Confession of Faith (1646) — Reformed/Presbyterian.",
            "Heidelberg Catechism (1563) — Reformed.",
            "Council of Trent decrees (1545–1563) — Catholic response."
    )),
    BodyBlock.Heading("Restoration Movement primary texts"),
    BodyBlock.BulletList(listOf(
            "Thomas Campbell, Declaration and Address (1809) — founding document.",
            "Alexander Campbell, The Christian System (1839).",
            "The Last Will and Testament of the Springfield Presbytery (Stone, 1804)."
    ))
    ),
    pullQuotes = listOf(),
    sources = listOf(
        HistorySource(title = "New Advent: Church Fathers", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://www.newadvent.org/fathers/", note = "Comprehensive online library of patristic writings in English."),
        HistorySource(title = "Christian Classics Ethereal Library", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://ccel.org/", note = "Free public-domain Christian classics, primary and secondary."),
        HistorySource(title = "Early Christian Writings", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://www.earlychristianwritings.com/", note = "Texts and scholarly commentary on early Christian and non-canonical writings.")
    ),
    related = listOf("sources-scholarly")
    )



    val sourcesScholarly = HistoryArticle(
        id = "sources-scholarly",
        title = "Scholarly References",
        subtitle = "Modern historians and theologians worth reading on church history.",
        era = "Reference",
        estimatedMinutes = 4,
        body = listOf(
            BodyBlock.Paragraph("The list below is a curated set of widely respected modern works on the topics covered in this History section. It is intentionally ecumenical — including Catholic, Orthodox, Protestant, and secular scholars — to give readers multiple angles on the same questions."),
            BodyBlock.Heading("General church history"),
            BodyBlock.BulletList(listOf(
                    "Justo L. González, The Story of Christianity, 2 vols. (1984/1985, rev. 2010) — broad, readable, ecumenical narrative.",
                    "Diarmaid MacCulloch, Christianity: The First Three Thousand Years (2009) — sweeping, scholarly, sometimes provocative.",
                    "Henry Chadwick, The Early Church (rev. 1993) — concise classic on the first six centuries.",
                    "Mark A. Noll, Turning Points: Decisive Moments in the History of Christianity (3rd ed., 2012)."
            )),
    BodyBlock.Heading("New Testament canon"),
    BodyBlock.BulletList(listOf(
            "Bruce M. Metzger, The Canon of the New Testament: Its Origin, Development, and Significance (1987) — standard reference.",
            "F. F. Bruce, The Canon of Scripture (1988) — accessible Protestant treatment.",
            "Lee Martin McDonald, The Biblical Canon: Its Origin, Transmission, and Authority (3rd ed., 2007)."
    )),
    BodyBlock.Heading("Eastern Orthodoxy"),
    BodyBlock.BulletList(listOf(
            "Timothy (Kallistos) Ware, The Orthodox Church (1963; rev. 1993) — accessible introduction by an Orthodox bishop and scholar.",
            "John Meyendorff, Byzantine Theology (1974).",
            "Steven Runciman, The Eastern Schism (1955)."
    )),
    BodyBlock.Heading("The Reformation"),
    BodyBlock.BulletList(listOf(
            "Diarmaid MacCulloch, The Reformation: A History (2003) — definitive single-volume account.",
            "Heiko A. Oberman, Luther: Man Between God and the Devil (1989).",
            "Carlos M. N. Eire, Reformations: The Early Modern World, 1450–1650 (2016)."
    )),
    BodyBlock.Heading("The Restoration Movement"),
    BodyBlock.BulletList(listOf(
            "Douglas A. Foster, Paul M. Blowers, Anthony L. Dunnavant, D. Newell Williams (eds.), The Encyclopedia of the Stone-Campbell Movement (2004) — comprehensive reference.",
            "Richard T. Hughes, Reviving the Ancient Faith: The Story of Churches of Christ in America (1996).",
            "Leroy Garrett, The Stone-Campbell Movement (1981)."
    )),
    BodyBlock.Heading("Online encyclopedic sources"),
    BodyBlock.BulletList(listOf(
            "Wikipedia — surprisingly reliable on church history topics, with citations to primary and scholarly sources.",
            "Catholic Encyclopedia at New Advent (newadvent.org/cathen) — early twentieth-century Catholic perspective.",
            "Encyclopaedia Britannica — solid neutral reference.",
            "Stanford Encyclopedia of Philosophy — for theological and philosophical concepts."
    ))
    ),
    pullQuotes = listOf(),
    sources = listOf(
        HistorySource(title = "New Advent (Catholic Encyclopedia + Church Fathers)", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://www.newadvent.org/", note = null),
        HistorySource(title = "Christian Classics Ethereal Library", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://ccel.org/", note = null),
        HistorySource(title = "History of Christianity", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/History_of_Christianity", note = null)
    ),
    related = listOf("sources-primary")
    )


    val further = HistorySection(
        id = "further",
        title = "Sources & Further Reading",
        subtitle = "Where to read the early voices and modern historians for yourself.",
        era = "Reference",
        emoji = "📚",
        articles = listOf(sourcesPrimary, sourcesScholarly)
    )
}
