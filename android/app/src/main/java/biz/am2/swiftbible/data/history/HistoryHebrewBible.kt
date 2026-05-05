package biz.am2.swiftbible.data.history

object HebrewBibleHistory {

    val hebrewTanakh = HistoryArticle(
        id = "hebrew-tanakh",
        title = "Tanakh & Septuagint",
        subtitle = "How the Hebrew Bible was organized — and translated into Greek.",
        era = "c. 500 BC — 100 AD",
        estimatedMinutes = 5,
        body = listOf(
            BodyBlock.Paragraph("The Hebrew Bible — what Jews call the Tanakh and Christians call the Old Testament — is not arranged the same way in every tradition. Its 24 books in the Hebrew arrangement become 39 in the Christian Protestant arrangement (counting the same content differently) and somewhat more in Catholic and Orthodox arrangements. Behind these differences lies a long process of canonization and translation."),
            BodyBlock.Heading("The threefold Tanakh"),
            BodyBlock.Paragraph("The word 'Tanakh' is an acronym for the three sections of the Hebrew Bible:"),
            BodyBlock.BulletList(listOf(
                    "Torah (Law) — the five books of Moses: Genesis, Exodus, Leviticus, Numbers, Deuteronomy. The most authoritative section.",
                    "Nevi'im (Prophets) — divided into Former Prophets (Joshua, Judges, Samuel, Kings) and Latter Prophets (Isaiah, Jeremiah, Ezekiel, and the twelve minor prophets).",
                    "Ketuvim (Writings) — Psalms, Proverbs, Job, the five Megillot (Song of Songs, Ruth, Lamentations, Ecclesiastes, Esther), Daniel, Ezra-Nehemiah, and Chronicles."
            )),
    BodyBlock.Heading("How it was canonized"),
    BodyBlock.Paragraph("The canonization of the Hebrew Bible was gradual, not a single event. The Torah achieved canonical status earliest, perhaps by the time of Ezra (c. 450 BC). The Prophets followed, settled by the second century BC. The Writings were the last and most contested section; debates about books like Ecclesiastes and Song of Songs continued into the rabbinic period. The Council of Jamnia (often cited as setting the canon around 90 AD) is now thought by most scholars to have ratified rather than created the canon."),
    BodyBlock.Heading("The Septuagint"),
    BodyBlock.Paragraph("As Greek became the common language of the Jewish diaspora, a translation of the Hebrew scriptures into Greek was needed. The Septuagint (often abbreviated LXX, 'seventy') was begun in Alexandria in the 200s BC and completed in stages over the next two centuries. According to legend recorded in the Letter of Aristeas, seventy-two Jewish scholars translated the Torah into Greek for the library of Ptolemy II — hence the name. The translation eventually included not only the books of the Hebrew Bible but also some additional writings — the Apocrypha or deuterocanonicals."),
    BodyBlock.Heading("Why it matters"),
    BodyBlock.Paragraph("The Septuagint was the Bible of most diaspora Jews and of the early Christian church. The vast majority of Old Testament quotations in the New Testament follow the Septuagint rather than the Hebrew text. Where the Septuagint differs from the Hebrew (and it sometimes does, significantly), the New Testament writers usually follow the Greek. This has practical consequences — for example, Isaiah 7:14 reads 'a virgin shall conceive' in the Septuagint and 'a young woman shall conceive' in the Hebrew. Matthew 1:23 quotes the Septuagint version when applying the verse to Jesus.")
    ),
    pullQuotes = listOf(
        PullQuote(
            text = "These three things characterize the canon: stability of contents, stability of arrangement, and stability of authority.",
            attribution = "Common scholarly observation",
            context = null
        )
    ),
    sources = listOf(
        HistorySource(title = "Hebrew Bible", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Hebrew_Bible", note = null),
        HistorySource(title = "Septuagint", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Septuagint", note = null),
        HistorySource(title = "Development of the Hebrew Bible canon", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Development_of_the_Hebrew_Bible_canon", note = null),
        HistorySource(title = "Invitation to the Septuagint", author = "Karen H. Jobes and Moisés Silva", kind = SourceKind.SCHOLARLY, url = null, note = "Baker Academic, 2nd ed., 2015."),
        HistorySource(title = "The Biblical Canon: Its Origin, Transmission, and Authority", author = "Lee Martin McDonald", kind = SourceKind.SCHOLARLY, url = null, note = "Hendrickson, 3rd ed., 2007.")
    ),
    related = listOf("hebrew-masoretic", "hebrew-dead-sea", "origins-canon-process")
    )



    val hebrewMasoretic = HistoryArticle(
        id = "hebrew-masoretic",
        title = "Masoretic Text",
        subtitle = "How rabbinic scribes preserved the Hebrew Bible across a thousand years.",
        era = "600 — 1000 AD",
        estimatedMinutes = 5,
        body = listOf(
            BodyBlock.Paragraph("The Hebrew text of the Old Testament that lies behind almost every modern translation is called the Masoretic Text. It is the work of generations of Jewish scribes called the Masoretes, working primarily in the towns of Tiberias in Galilee and Sura in Babylon during the second half of the first millennium AD."),
            BodyBlock.Heading("Why it was needed"),
            BodyBlock.Paragraph("Hebrew was originally written without vowels and with no spaces between words. By the early Middle Ages, Hebrew had ceased to be the everyday spoken language of most Jews. The risk of mispronouncing or misreading the sacred text was real. The Masoretes developed an elaborate system of vowel pointing, accents, and marginal notes designed to preserve the exact pronunciation, division, and reading of the text as it had been received."),
            BodyBlock.Heading("What they did"),
            BodyBlock.Paragraph("The Masoretic system included:"),
            BodyBlock.BulletList(listOf(
                    "Vowel signs added above, below, or within consonants to indicate pronunciation.",
                    "Cantillation marks indicating how each word should be sung in synagogue worship.",
                    "Detailed marginal notes (the Masorah) recording how often unusual words appear, when scribes thought letters should be erased or read differently, and other textual observations.",
                    "Counts of letters, words, and verses for every book — a built-in checksum that would catch most copying errors."
            )),
    BodyBlock.Heading("Different traditions"),
    BodyBlock.Paragraph("Two principal Masoretic traditions developed: the Tiberian (in Galilee, with Aaron ben Asher's family the most influential) and the Babylonian. The Tiberian tradition won out, and almost all printed Hebrew Bibles today use the ben Asher text. The two surviving most complete Tiberian manuscripts are the Aleppo Codex (c. 925, partially damaged) and the Leningrad Codex (1008, the oldest complete Hebrew Bible)."),
    BodyBlock.Heading("Comparing with older texts"),
    BodyBlock.Paragraph("Until the discovery of the Dead Sea Scrolls in 1947, the oldest substantial Hebrew biblical manuscripts were Masoretic, dating to around 1000 AD. The Dead Sea Scrolls — many of which date to a thousand years earlier — confirmed that the Masoretic text had been transmitted with remarkable fidelity. There are differences, sometimes significant, but the broad agreement is striking. Scholars now have a much fuller picture of textual history before the Masoretes, and modern critical Hebrew Bibles often note variants from the scrolls and other early witnesses.")
    ),
    pullQuotes = listOf(
        PullQuote(
            text = "The grass withereth, the flower fadeth: but the word of our God shall stand for ever.",
            attribution = "Isaiah 40:8",
            context = "King James Version"
        )
    ),
    sources = listOf(
        HistorySource(title = "Masoretic Text", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Masoretic_Text", note = null),
        HistorySource(title = "Aleppo Codex", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Aleppo_Codex", note = null),
        HistorySource(title = "Leningrad Codex", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Leningrad_Codex", note = null),
        HistorySource(title = "Textual Criticism of the Hebrew Bible", author = "Emanuel Tov", kind = SourceKind.SCHOLARLY, url = null, note = "Fortress Press, 3rd ed., 2012.")
    ),
    related = listOf("hebrew-tanakh", "hebrew-dead-sea")
    )



    val hebrewDeadSea = HistoryArticle(
        id = "hebrew-dead-sea",
        title = "Dead Sea Scrolls & Apocrypha",
        subtitle = "Hidden manuscripts, contested books, and a fuller picture of ancient Judaism.",
        era = "300 BC — 70 AD",
        estimatedMinutes = 6,
        body = listOf(
            BodyBlock.Paragraph("In late 1946 or early 1947, a Bedouin shepherd named Muhammed edh-Dhib threw a stone into a cave in the cliffs above the Dead Sea, near a ruin called Khirbet Qumran. He heard pottery break. Inside the cave were jars containing ancient scrolls. Over the next decade, eleven caves in the area yielded fragments of approximately 900 different manuscripts dating from roughly 300 BC to 70 AD — the most important manuscript discovery of the twentieth century for biblical studies."),
            BodyBlock.Heading("What was found"),
            BodyBlock.Paragraph("The Dead Sea Scrolls fall into three rough categories. About a quarter are biblical manuscripts — copies of every book of the Hebrew Bible except Esther. About a quarter are non-biblical Jewish religious writings known from elsewhere (Tobit, Jubilees, 1 Enoch, and others). The remaining half are works previously unknown — community rules, biblical commentaries, hymns, apocalyptic visions, and sectarian writings believed to come from the community that lived at Qumran."),
            BodyBlock.Heading("Why they matter"),
            BodyBlock.Paragraph("Before the scrolls, the oldest substantial Hebrew biblical manuscripts dated to around 1000 AD. The scrolls pushed that back by a thousand years, allowing scholars to test the reliability of the Masoretic transmission. The result was reassuring: the broad textual tradition is remarkably stable. The scrolls also revealed a more diverse first-century Judaism than had previously been understood, including apocalyptic strains and messianic expectations that illuminate the context of John the Baptist, Jesus, and the early church."),
            BodyBlock.Heading("Apocrypha and pseudepigrapha"),
            BodyBlock.Paragraph("The discovery brought renewed attention to a body of Jewish writings produced between roughly 200 BC and 100 AD that were not included in the Hebrew Bible. These fall into two categories:"),
            BodyBlock.BulletList(listOf(
                    "Apocrypha (or 'deuterocanonical'): books included in the Septuagint but not in the Hebrew Bible. Catholic and Orthodox Christians accept these as Scripture; Protestants and Jews do not. Examples: Tobit, Judith, 1 and 2 Maccabees, Wisdom of Solomon, Sirach, Baruch, additions to Esther and Daniel.",
                    "Pseudepigrapha: books written under the names of biblical figures (Enoch, Moses, Ezra, the patriarchs) but accepted as canonical by neither Jews nor most Christians. Examples: 1 Enoch, Jubilees, the Testaments of the Twelve Patriarchs, 4 Ezra. Important for understanding Second Temple Judaism even when not treated as Scripture."
            )),
    BodyBlock.Heading("Where they stand today"),
    BodyBlock.Paragraph("The Apocrypha appears in Catholic Bibles, in many Anglican Bibles (placed between the Testaments), and in the original 1611 King James Version (though typically omitted from modern KJV printings). Protestants generally treat them as historically valuable but not Scripture. The Dead Sea Scrolls are now nearly all published and translated, accessible to anyone willing to read them. They represent perhaps the single most important window into the Judaism of Jesus' world that the modern world possesses.")
    ),
    pullQuotes = listOf(
        PullQuote(
            text = "Truth springeth out of the earth; and righteousness hath looked down from heaven.",
            attribution = "Psalm 85:11",
            context = "King James Version"
        )
    ),
    sources = listOf(
        HistorySource(title = "Dead Sea Scrolls", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Dead_Sea_Scrolls", note = null),
        HistorySource(title = "Biblical apocrypha", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Biblical_apocrypha", note = null),
        HistorySource(title = "Pseudepigrapha", author = null, kind = SourceKind.ENCYCLOPEDIA, url = "https://en.wikipedia.org/wiki/Pseudepigrapha", note = null),
        HistorySource(title = "The Meaning of the Dead Sea Scrolls", author = "James VanderKam and Peter Flint", kind = SourceKind.SCHOLARLY, url = null, note = "HarperOne, 2002."),
        HistorySource(title = "The Old Testament Pseudepigrapha", author = "James H. Charlesworth (ed.)", kind = SourceKind.SCHOLARLY, url = null, note = "Doubleday, 2 vols., 1983/1985.")
    ),
    related = listOf("hebrew-tanakh", "hebrew-masoretic", "intertest-sects", "origins-disputed-books")
    )


    val hebrewBible = HistorySection(
        id = "hebrew-bible",
        title = "The Hebrew Bible & Texts",
        subtitle = "Tanakh, Septuagint, Masoretic Text, Dead Sea Scrolls, and the Apocrypha.",
        era = "c. 500 BC — 1000 AD",
        emoji = "📖",
        articles = listOf(hebrewTanakh, hebrewMasoretic, hebrewDeadSea)
    )
}
