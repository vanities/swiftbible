//
//  HistoryIntertestamental.swift
//  swiftbible
//
//  Pre-NT Section — The Intertestamental Period.
//

import Foundation

extension HistorySection {
    static let intertestamental = HistorySection(
        id: "intertestamental",
        title: "The Intertestamental Period",
        subtitle: "Greek conquest, Maccabean revolt, Roman occupation — the world Jesus was born into.",
        symbol: "globe.europe.africa",
        era: "332 BC — 70 AD",
        articles: [
            .intertestMaccabees,
            .intertestRoman,
            .intertestSects
        ]
    )
}

extension HistoryArticle {
    static let intertestMaccabees = HistoryArticle(
        id: "intertest-maccabees",
        title: "Hellenization & the Maccabees",
        subtitle: "Greek culture, a desecrated temple, and the revolt that gave us Hanukkah.",
        era: "332 — 63 BC",
        estimatedMinutes: 6,
        body: [
            .paragraph("The four centuries between Malachi and the New Testament are often called 'intertestamental' by Christians, but they were anything but silent. Vast cultural and political shifts in the Greek and Roman worlds reshaped Judaism in ways that directly set the stage for the world of Jesus and the early church."),
            .heading("Alexander and Hellenization"),
            .paragraph("Alexander the Great's conquest of the Persian Empire in 332 BC began a process called Hellenization — the spread of Greek language, education, philosophy, art, and city-life across the eastern Mediterranean. Most Jews encountered Hellenism not as direct cultural assault but as the air they breathed. By the 200s BC, Greek had become the common language of the Jewish diaspora. The Septuagint — a Greek translation of the Hebrew Bible — was begun in Alexandria and became the Bible most commonly read by diaspora Jews and, later, by the early Christian church."),
            .heading("The crisis under Antiochus IV"),
            .paragraph("After Alexander, his empire was divided among his generals. Judea passed first to the Ptolemies of Egypt, then to the Seleucids of Syria. The Seleucid king Antiochus IV Epiphanes (175–164 BC) pushed Hellenization on the Jews aggressively. He intervened in the high priesthood, sold it to the highest bidder, and eventually banned Torah observance, circumcision, and Sabbath-keeping. In 167 BC he profaned the Jerusalem temple by setting up an altar to Olympian Zeus over the altar of burnt offering — an event later called the 'abomination of desolation' (a phrase that recurs in Daniel and the Gospels)."),
            .heading("The Maccabean Revolt"),
            .paragraph("A village priest named Mattathias and his five sons led a guerrilla revolt against Seleucid rule. After Mattathias's death, his son Judas Maccabeus ('the Hammer') rose as the principal leader. Against long odds, the rebels recaptured Jerusalem and rededicated the temple in December 164 BC — an event commemorated annually as Hanukkah. After Judas, his brothers Jonathan and Simon continued the struggle until full independence was achieved."),
            .heading("The Hasmonean kingdom"),
            .paragraph("The dynasty descended from Mattathias's family — called the Hasmoneans — ruled an independent Jewish state for roughly a century (c. 140–63 BC). They combined the offices of high priest and king, a fusion that some Jews found deeply problematic. Internal disputes, particularly between two rival claimants to the throne, eventually prompted both sides to appeal to Rome — a move that ended Jewish independence."),
            .heading("What survives in the canon"),
            .paragraph("The story of the Maccabean revolt is preserved in 1 and 2 Maccabees, books accepted as canonical by Catholic and Orthodox Christians but treated as deuterocanonical or apocryphal by Protestants and Jews. They are the most important historical sources we have for the period and were written close to the events they describe.")
        ],
        pullQuotes: [
            PullQuote(
                text: "Then the king wrote to his whole kingdom that all should be one people, and that each should give up his customs.",
                attribution: "1 Maccabees 1:41–42",
                context: "RSV"
            )
        ],
        sources: [
            HistorySource(title: "Hellenistic Judaism", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Hellenistic_Judaism", note: nil),
            HistorySource(title: "Maccabean Revolt", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Maccabean_Revolt", note: nil),
            HistorySource(title: "1 Maccabees and 2 Maccabees", author: nil, kind: .primary, url: nil, note: "Apocrypha / deuterocanonical."),
            HistorySource(title: "From the Maccabees to the Mishnah", author: "Shaye J. D. Cohen", kind: .scholarly, url: nil, note: "Westminster John Knox, 3rd ed., 2014."),
            HistorySource(title: "The Jews in the Greek Age", author: "Elias Bickerman", kind: .scholarly, url: nil, note: "Harvard University Press, 1988.")
        ],
        related: ["israel-return", "intertest-roman", "intertest-sects"]
    )

    static let intertestRoman = HistoryArticle(
        id: "intertest-roman",
        title: "Roman Era",
        subtitle: "Pompey, Herod, and the world Jesus was born into.",
        era: "63 BC — 70 AD",
        estimatedMinutes: 6,
        body: [
            .paragraph("Internal disputes within the Hasmonean dynasty led both sides to appeal to Rome for arbitration. The Roman general Pompey marched on Jerusalem in 63 BC and captured the city after a three-month siege. He famously entered the Holy of Holies — an act that horrified Jews — and confirmed Hyrcanus II as high priest while reducing Jewish territory and political power. Roman rule of Judea had begun."),
            .heading("Herod the Great"),
            .paragraph("A few decades later, an Idumean (a descendant of Edomites who had been forcibly converted to Judaism a generation earlier) named Herod rose through Roman patronage. With backing from Mark Antony and later Octavian, Herod became king of the Jews (37–4 BC). He was a brilliant administrator and builder, expanding the Second Temple into one of the wonders of the ancient world. He was also a paranoid tyrant who executed several of his own sons and his favorite wife. Matthew's account of Herod's slaughter of the male infants in Bethlehem fits the historical pattern of his cruelty."),
            .heading("Roman governance after Herod"),
            .paragraph("After Herod's death, his kingdom was divided among his sons. Judea proper came under direct Roman administration through procurators, of whom Pontius Pilate (26–36 AD) is the most famous to Christians. The Romans generally tolerated Jewish religious distinctiveness — exempting Jews from emperor worship and from military service — but this tolerance was strained by repeated insurgent movements and by Jewish revulsion at Roman taxation, idolatry, and political control."),
            .heading("Apocalyptic expectation"),
            .paragraph("First-century Judaism was saturated with apocalyptic expectation. Many Jews looked for a Messiah who would deliver them from Roman rule and restore the kingdom to Israel. Multiple would-be messiahs appeared during this period, attracting followers and being crushed by Rome. John the Baptist and Jesus of Nazareth were two figures within this larger ferment, though their movements ultimately took very different shapes."),
            .heading("The Jewish-Roman wars"),
            .paragraph("A major Jewish revolt broke out in 66 AD. After four years of bitter fighting, Roman legions under Titus besieged Jerusalem. The temple was burned and destroyed in August 70 AD. A holdout at Masada fell in 73 AD. A second revolt — the Bar Kokhba revolt of 132–136 AD — was also crushed, and Jews were banned from Jerusalem. The destruction of the temple ended sacrificial worship and forced Judaism to reorganize around Torah, synagogue, and rabbinic teaching.")
        ],
        pullQuotes: [
            PullQuote(
                text: "And it came to pass in those days, that there went out a decree from Caesar Augustus, that all the world should be taxed.",
                attribution: "Luke 2:1",
                context: "King James Version"
            )
        ],
        sources: [
            HistorySource(title: "Judaea (Roman province)", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Judaea_(Roman_province)", note: nil),
            HistorySource(title: "Herod the Great", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Herod_the_Great", note: nil),
            HistorySource(title: "First Jewish–Roman War", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/First_Jewish%E2%80%93Roman_War", note: nil),
            HistorySource(title: "The Jewish War and Antiquities of the Jews", author: "Flavius Josephus", kind: .primary, url: nil, note: "Eyewitness historian, late 1st century AD."),
            HistorySource(title: "Rome and Jerusalem: The Clash of Ancient Civilizations", author: "Martin Goodman", kind: .scholarly, url: nil, note: "Knopf, 2007.")
        ],
        related: ["intertest-maccabees", "intertest-sects", "israel-return"]
    )

    static let intertestSects = HistoryArticle(
        id: "intertest-sects",
        title: "Jewish Sects",
        subtitle: "Pharisees, Sadducees, Essenes, Zealots — the contested landscape of 1st-century Judaism.",
        era: "c. 150 BC — 70 AD",
        estimatedMinutes: 6,
        body: [
            .paragraph("The Judaism Jesus was born into was not monolithic. By the first century, several distinct movements competed for influence within the Jewish community. The Gospels and the historian Josephus (writing around 90 AD) both name the same major groups, though they describe them differently. Understanding these sects is essential for reading the New Testament well."),
            .heading("Pharisees"),
            .paragraph("The Pharisees were a lay movement focused on rigorous observance of Torah, including extensive oral traditions about how to apply biblical commands to daily life. They believed in the resurrection of the dead, in angels and spirits, and in providence working alongside human freedom. They were popular with ordinary people and held significant influence over synagogue worship. After the destruction of the temple in 70 AD, the Pharisaic tradition was the principal stream that survived and developed into rabbinic Judaism. The Gospels often portray Pharisees as Jesus' opponents, but Jesus' own teaching shares much with theirs."),
            .heading("Sadducees"),
            .paragraph("The Sadducees were associated with the priestly aristocracy and the temple. They accepted only the written Torah (the five books of Moses) as fully authoritative and rejected the oral traditions developed by the Pharisees. They denied the resurrection of the dead, the existence of angels, and elaborate doctrines of the afterlife. They cooperated with Roman authority and depended on the temple for their religious and social position. The destruction of the temple in 70 AD essentially ended their movement."),
            .heading("Essenes"),
            .paragraph("The Essenes were a smaller, withdrawn movement, with separatist communities in towns and at least one major desert settlement. They emphasized ritual purity, communal life, and apocalyptic expectation. Most modern scholars associate the Essenes with the community at Qumran near the Dead Sea — the community that produced or preserved the Dead Sea Scrolls. They are not mentioned by name in the New Testament, but some scholars have suggested links between Essene thought and John the Baptist or the early Christian community."),
            .heading("Zealots"),
            .paragraph("The Zealots were a militant nationalist movement committed to armed resistance against Roman rule and Jewish collaborators. They were less organized in Jesus' day than they became during the revolt of 66–73 AD. One of Jesus' twelve apostles, Simon the Zealot, may have come from this movement. Judas Iscariot's surname is sometimes interpreted as deriving from sicarii ('dagger-men'), a related radical group."),
            .heading("Other groups"),
            .paragraph("Beyond these four named by Josephus, first-century Judaism included Samaritans (a related but distinct community centered on Mount Gerizim), Therapeutae (a contemplative community in Egypt similar to the Essenes), various apocalyptic groups, would-be messianic movements, and the diaspora communities in Alexandria, Antioch, Rome, and beyond. The early Christian movement emerged within this complex landscape, was initially viewed as another Jewish sect, and only gradually became understood as something distinct.")
        ],
        pullQuotes: [
            PullQuote(
                text: "For the Sadducees say that there is no resurrection, neither angel, nor spirit: but the Pharisees confess both.",
                attribution: "Acts 23:8",
                context: "King James Version"
            )
        ],
        sources: [
            HistorySource(title: "Pharisees", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Pharisees", note: nil),
            HistorySource(title: "Sadducees", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Sadducees", note: nil),
            HistorySource(title: "Essenes", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Essenes", note: nil),
            HistorySource(title: "Zealots", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Zealots_(Judea)", note: nil),
            HistorySource(title: "Antiquities of the Jews, Book 18", author: "Flavius Josephus", kind: .primary, url: nil, note: "Describes the four major Jewish 'philosophies' of the period."),
            HistorySource(title: "Judaism: Practice and Belief, 63 BCE–66 CE", author: "E. P. Sanders", kind: .scholarly, url: nil, note: "Trinity Press, 1992.")
        ],
        related: ["intertest-roman", "hebrew-dead-sea", "early-fathers"]
    )
}
