//
//  HistoryAncientIsrael.swift
//  swiftbible
//
//  Pre-NT Section — Ancient Israel.
//

import Foundation

extension HistorySection {
    static let ancientIsrael = HistorySection(
        id: "ancient-israel",
        title: "Ancient Israel",
        subtitle: "Patriarchs, Exodus, kingdom, exile — the long arc before the Second Temple.",
        symbol: "mountain.2",
        era: "c. 2000 — 538 BC",
        articles: [
            .israelPatriarchs,
            .israelExodus,
            .israelKingdom,
            .israelReturn
        ]
    )
}

extension HistoryArticle {
    static let israelPatriarchs = HistoryArticle(
        id: "israel-patriarchs",
        title: "The Patriarchs",
        subtitle: "Abraham, Isaac, Jacob — and the question of how to read them.",
        era: "c. 2000 — 1500 BC",
        estimatedMinutes: 5,
        body: [
            .paragraph("Genesis traces the origin of the people of Israel to a single family — Abraham (originally Abram), his son Isaac, and his grandson Jacob (later renamed Israel). The patriarchal narratives in Genesis 12–50 cover roughly four generations, set in the second millennium BC, moving from Mesopotamia through Canaan into Egypt. They have shaped the self-understanding of three major world religions: Judaism, Christianity, and Islam."),
            .heading("The story Genesis tells"),
            .paragraph("Abraham is called by God out of Ur of the Chaldeans to a land God will show him, with the promise of descendants and blessing for all nations. He travels to Canaan, has Ishmael by Hagar and Isaac by Sarah, and is tested by the command to sacrifice Isaac. Isaac fathers Esau and Jacob; Jacob — through Leah, Rachel, and their handmaids — has twelve sons who become the twelve tribes of Israel. The narrative ends with Joseph rising to power in Egypt and the family settling there during a famine."),
            .heading("Dating and historical questions"),
            .paragraph("Traditional dating places Abraham around 2000 BC, with the patriarchal period extending into the 1500s. Mainstream biblical scholarship is divided on the historicity of these narratives. Some scholars see the patriarchal traditions as reflecting genuine memories of the Middle Bronze Age; others treat them as later compositions reflecting concerns of the writers' own time, perhaps as late as the exilic or post-exilic period. The texts themselves were likely written down centuries after the events they describe, drawing on long oral traditions."),
            .heading("Why they matter theologically"),
            .paragraph("For Jews, the patriarchs are the founding ancestors of the covenant people. For Christians, they are also the earliest recipients of God's promises that find fulfillment in Christ — Paul appeals repeatedly to Abraham's faith as the model of justification (Romans 4, Galatians 3). For Muslims, Ibrahim (Abraham) is a prophet honored in the Quran as a model of submission to God. The figure of Abraham crosses three of the world's major religions and is often called the ancestor of 'Abrahamic monotheism.'"),
            .heading("Key narratives"),
            .list([
                "Abraham's call from Ur (Genesis 12).",
                "The covenant of circumcision (Genesis 17).",
                "The destruction of Sodom and Gomorrah (Genesis 18–19).",
                "The binding of Isaac (Genesis 22) — pivotal in Jewish, Christian, and Islamic theology.",
                "Jacob wrestling with God at Peniel (Genesis 32).",
                "Joseph's rise to power in Egypt (Genesis 37–50)."
            ])
        ],
        pullQuotes: [
            PullQuote(
                text: "And he brought him forth abroad, and said, Look now toward heaven, and tell the stars, if thou be able to number them: and he said unto him, So shall thy seed be.",
                attribution: "Genesis 15:5",
                context: "King James Version"
            )
        ],
        sources: [
            HistorySource(title: "Patriarchal age", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Patriarchal_age", note: nil),
            HistorySource(title: "Abraham", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Abraham", note: nil),
            HistorySource(title: "A History of Israel", author: "John Bright", kind: .scholarly, url: nil, note: "Westminster John Knox, 4th ed., 2000."),
            HistorySource(title: "Who Were the Early Israelites and Where Did They Come From?", author: "William G. Dever", kind: .scholarly, url: nil, note: "Eerdmans, 2003.")
        ],
        related: ["israel-exodus", "israel-kingdom", "intertest-sects"]
    )

    static let israelExodus = HistoryArticle(
        id: "israel-exodus",
        title: "Exodus & Conquest",
        subtitle: "Moses, Sinai, Joshua — and a debate over what really happened.",
        era: "c. 1500 — 1200 BC",
        estimatedMinutes: 6,
        body: [
            .paragraph("The Exodus is the foundational story of Israel: a band of Hebrew slaves in Egypt led out by Moses through divine signs and wonders, formed into a covenant people at Mount Sinai through the giving of the Torah, and brought into the land of Canaan by Moses' successor Joshua. It is the central liberation narrative of the Hebrew Bible and has shaped Jewish identity, Christian theology, and movements for justice across history."),
            .heading("The biblical narrative"),
            .paragraph("Exodus through Joshua tells the story across roughly forty years. Moses, born to Hebrew parents, raised in Pharaoh's household, and exiled to Midian, is called by God at the burning bush. The ten plagues culminate in the Passover; the Hebrews escape through the parted sea; they receive the Ten Commandments and the rest of the Torah at Sinai; they wander in the wilderness for forty years; under Joshua they cross the Jordan and conquer the major Canaanite city-states."),
            .heading("Dating debates"),
            .paragraph("Two main dates have been proposed for the Exodus. The 'early' date (c. 1446 BC) takes 1 Kings 6:1 literally — placing the Exodus 480 years before Solomon's temple. The 'late' date (c. 1250 BC) places it under Pharaoh Ramesses II, citing Exodus 1:11's mention of the city of Raamses. Each has scholarly defenders. Some conservative scholars hold to one of these dates; many mainstream scholars are skeptical that any massive Exodus event in the form Genesis describes happened at all."),
            .heading("The conquest question"),
            .paragraph("Joshua's conquest is the most contested element historically. Joshua describes a relatively swift, comprehensive conquest of Canaan; Judges describes a slower, more partial settlement. Archaeology shows mixed evidence: some sites mentioned in Joshua were destroyed in the relevant period, others apparently were not. Several models try to account for the data: military conquest (the traditional reading), peaceful infiltration, peasant revolt, and various combinations. The historical questions remain open and actively debated."),
            .heading("Theological centrality"),
            .paragraph("Whatever the historical details, the Exodus is theologically formative. The Passover is celebrated annually in Jewish homes. The New Testament repeatedly interprets Christ's death and resurrection as a new Exodus — Jesus is 'our Passover' (1 Corinthians 5:7), the gospel as deliverance from slavery to sin. Liberation theologians of the twentieth century drew on the Exodus as a model of God's preferential concern for the oppressed. The story's reach extends well beyond questions of historicity.")
        ],
        pullQuotes: [
            PullQuote(
                text: "And the LORD said, I have surely seen the affliction of my people which are in Egypt, and have heard their cry by reason of their taskmasters; for I know their sorrows; And I am come down to deliver them.",
                attribution: "Exodus 3:7–8",
                context: "King James Version"
            )
        ],
        sources: [
            HistorySource(title: "The Exodus", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/The_Exodus", note: nil),
            HistorySource(title: "Conquest of Canaan", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Conquest_of_Canaan", note: nil),
            HistorySource(title: "The Bible Unearthed", author: "Israel Finkelstein and Neil Asher Silberman", kind: .scholarly, url: nil, note: "Free Press, 2001 — skeptical mainstream perspective."),
            HistorySource(title: "On the Reliability of the Old Testament", author: "Kenneth A. Kitchen", kind: .scholarly, url: nil, note: "Eerdmans, 2003 — more conservative perspective.")
        ],
        related: ["israel-patriarchs", "israel-kingdom", "hebrew-tanakh"]
    )

    static let israelKingdom = HistoryArticle(
        id: "israel-kingdom",
        title: "Kingdom & Exile",
        subtitle: "Saul, David, Solomon, and the catastrophe of 587 BC.",
        era: "c. 1050 — 538 BC",
        estimatedMinutes: 6,
        body: [
            .paragraph("The transition from a tribal confederation under judges to a centralized monarchy, and the eventual collapse of that monarchy, is one of the most consequential arcs in the Hebrew Bible. Across roughly five centuries, Israel rose from scattered tribes to a regional kingdom, split, declined, and was conquered — first the northern kingdom by Assyria (722 BC) and then the southern kingdom of Judah by Babylon (587 BC)."),
            .heading("Saul, David, Solomon"),
            .paragraph("Israel's first king, Saul, was anointed by the prophet Samuel around 1050 BC under pressure from the people who wanted 'a king like the other nations.' David — a shepherd and warrior whose victory over Goliath made him famous — succeeded Saul, captured Jerusalem, and made it the political and religious capital. His son Solomon built the First Temple in Jerusalem (c. 957 BC) and presided over a period of relative peace and prosperity. Solomon's heavy taxation and forced labor sowed the seeds of division."),
            .heading("The divided kingdom"),
            .paragraph("After Solomon's death in 931 BC, the kingdom split. Ten northern tribes formed the kingdom of Israel under Jeroboam, with its capital eventually at Samaria. The southern kingdom of Judah, with Jerusalem, kept the Davidic dynasty. The two kingdoms coexisted, sometimes at war and sometimes allied, for the next two centuries. The northern kingdom fell to the Assyrian Empire in 722 BC, and its inhabitants were largely deported and dispersed — the legendary 'ten lost tribes.'"),
            .heading("Judah and the Babylonian exile"),
            .paragraph("Judah survived the Assyrian threat, in part through dramatic diplomatic and military events under King Hezekiah (Isaiah's contemporary). But it eventually fell to the Neo-Babylonian Empire under Nebuchadnezzar. Jerusalem was captured in 597 BC, with the king and elite deported. After a failed revolt, the Babylonians returned in 587 BC, destroyed the temple, leveled Jerusalem, and deported a much larger population. The exile became a defining trauma — and a defining theological challenge: how could the God of Israel let his city and temple fall?"),
            .heading("Prophetic response"),
            .paragraph("The prophets — Isaiah, Jeremiah, Ezekiel, and others — interpreted the catastrophe theologically. The exile was not God's failure but his judgment for covenant unfaithfulness. Yet the prophets also held out hope: God would restore his people. Out of the exile came some of the most profound writing in the Hebrew Bible, including parts of Isaiah, all of Lamentations and Ezekiel, and much of the Psalms. The exile was not the end of Israel but its painful refining.")
        ],
        pullQuotes: [
            PullQuote(
                text: "By the rivers of Babylon, there we sat down, yea, we wept, when we remembered Zion.",
                attribution: "Psalm 137:1",
                context: "King James Version"
            )
        ],
        sources: [
            HistorySource(title: "History of ancient Israel and Judah", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/History_of_ancient_Israel_and_Judah", note: nil),
            HistorySource(title: "Babylonian captivity", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Babylonian_captivity", note: nil),
            HistorySource(title: "A History of Israel", author: "John Bright", kind: .scholarly, url: nil, note: "Westminster John Knox, 4th ed., 2000."),
            HistorySource(title: "Ancient Israel: What Do We Know and How Do We Know It?", author: "Lester L. Grabbe", kind: .scholarly, url: nil, note: "T&T Clark, 2007.")
        ],
        related: ["israel-exodus", "israel-return", "intertest-sects"]
    )

    static let israelReturn = HistoryArticle(
        id: "israel-return",
        title: "Return & Second Temple",
        subtitle: "From Cyrus's decree to Roman occupation — five centuries that shaped Jesus' world.",
        era: "538 BC — 70 AD",
        estimatedMinutes: 7,
        body: [
            .paragraph("In 539 BC, the Persian king Cyrus the Great conquered Babylon. Within a year he had issued a decree allowing the exiled Jewish community to return to Jerusalem and rebuild their temple. The period from this return until the Roman destruction of the rebuilt temple in 70 AD is conventionally called the 'Second Temple period' — a stretch of roughly 600 years that saw the formation of much of what is recognizable today as Judaism."),
            .heading("The return"),
            .paragraph("Not all exiles returned; many had built lives in Babylon. A substantial community made the journey in waves under leaders like Zerubbabel, Ezra, and Nehemiah. The Second Temple was completed around 516 BC, smaller and less grand than Solomon's. Under Persian rule, the Jewish community in Judea (now called Yehud) reorganized around the temple, the priesthood, and the Law of Moses. Ezra led a renewal of Torah observance."),
            .heading("Greek conquest"),
            .paragraph("Persian rule ended when Alexander the Great swept through the region in 332 BC. After Alexander's death, his empire was divided among his generals. Judea passed first to the Ptolemies (Alexandria, Egypt) and then to the Seleucids (Antioch, Syria). Greek language, philosophy, and culture spread throughout the eastern Mediterranean — a process called Hellenization. Greek (specifically Koine Greek) became the lingua franca, and Jewish scriptures began to be translated into Greek for the diaspora."),
            .heading("The Hasmonean kingdom"),
            .paragraph("When the Seleucid king Antiochus IV Epiphanes desecrated the temple and outlawed Jewish practice in the 160s BC, a priestly family — Mattathias and his sons, the Maccabees — led a successful revolt. The resulting Hasmonean dynasty ruled an independent Jewish state for roughly a century (c. 140–63 BC). Internal divisions invited Roman intervention; the Roman general Pompey captured Jerusalem in 63 BC, ending Jewish independence."),
            .heading("Roman rule and Herod"),
            .paragraph("Rome ruled Judea for the next century, sometimes through client kings (most notoriously Herod the Great), sometimes through procurators. Herod massively expanded the Second Temple, transforming it into one of the architectural wonders of the ancient world. Jewish religious life developed multiple competing forms — Pharisees, Sadducees, Essenes, Zealots — each with distinctive emphases. Apocalyptic expectation of a coming Messiah ran high. Into this world Jesus of Nazareth was born."),
            .heading("The end of the Second Temple"),
            .paragraph("A Jewish revolt against Rome (66–73 AD) ended in catastrophe. Roman legions under Titus besieged Jerusalem and destroyed the Second Temple in 70 AD. A second revolt under Bar Kokhba (132–136 AD) was also crushed. After 70 AD, sacrificial worship at the temple ended forever, and Judaism reorganized around Torah study and the synagogue — a reorientation that has shaped rabbinic Judaism ever since.")
        ],
        pullQuotes: [
            PullQuote(
                text: "Thus saith Cyrus king of Persia, The LORD God of heaven hath given me all the kingdoms of the earth; and he hath charged me to build him an house at Jerusalem, which is in Judah.",
                attribution: "Ezra 1:2",
                context: "King James Version"
            )
        ],
        sources: [
            HistorySource(title: "Second Temple period", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Second_Temple_period", note: nil),
            HistorySource(title: "Hasmonean dynasty", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Hasmonean_dynasty", note: nil),
            HistorySource(title: "Herod the Great", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Herod_the_Great", note: nil),
            HistorySource(title: "From the Maccabees to the Mishnah", author: "Shaye J. D. Cohen", kind: .scholarly, url: nil, note: "Westminster John Knox, 3rd ed., 2014.")
        ],
        related: ["israel-kingdom", "intertest-maccabees", "intertest-roman", "intertest-sects"]
    )
}
