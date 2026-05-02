//
//  HistoryEarlyChurch.swift
//  swiftbible
//
//  Section 2 — The Early Church (100–500 AD).
//

import Foundation

extension HistorySection {
    static let earlyChurch = HistorySection(
        id: "early-church",
        title: "The Early Church",
        subtitle: "Bishops, apologists, and a faith spreading under empire.",
        symbol: "building.columns",
        era: "100 — 500 AD",
        articles: [
            .earlyFathers,
            .earlyApologists,
            .earlyBishops,
            .earlyEucharist
        ]
    )
}

extension HistoryArticle {
    static let earlyFathers = HistoryArticle(
        id: "early-fathers",
        title: "The Apostolic Fathers",
        subtitle: "The first Christians who knew the apostles personally — and what they wrote.",
        era: "70 — 150 AD",
        estimatedMinutes: 5,
        body: [
            .paragraph("A small group of early Christian writers are conventionally called the 'Apostolic Fathers' because they are believed to have been taught by the apostles or by their immediate disciples. They are not Scripture, but their writings are the closest non-canonical windows into how the earliest church understood itself, worshipped, and organized in the decades immediately after the apostles died."),
            .heading("Who they were"),
            .list([
                "Clement of Rome (d. c. 99) — bishop of Rome whose letter to Corinth (1 Clement, c. 96) is the earliest non-NT Christian writing we have.",
                "Ignatius of Antioch (d. c. 107) — bishop of Antioch in Syria, who wrote seven letters to churches and to Polycarp on his way to martyrdom in Rome.",
                "Polycarp of Smyrna (d. c. 155) — disciple of John the Apostle, whose letter to the Philippians and the account of his martyrdom both survive.",
                "The Didache (c. 50–120) — anonymous early manual on baptism, Eucharist, fasting, and church order.",
                "The Shepherd of Hermas (c. 100–150) — apocalyptic Roman work read as Scripture in some churches.",
                "Papias of Hierapolis (c. 60–130) — wrote about the origins of the Gospels; only fragments survive in later writers."
            ]),
            .heading("What they show"),
            .paragraph("These writings give a picture of Christian life in the first half of the second century. They confirm that Christians were already organizing under bishops and elders, celebrating a weekly Eucharist, baptizing converts (the Didache prefers running water but allows pouring), suffering occasional persecution, and treating the writings of the apostles as authoritative."),
            .heading("What they don't settle"),
            .paragraph("They are not Scripture, and Christians have read them differently. Some traditions cite them as evidence that elements like episcopal hierarchy and a sacramental view of communion were universal apostolic practice. Others read them as showing how quickly distinctively Christian forms began to develop after the apostles died, and treat them as historical witnesses rather than as binding authorities.")
        ],
        pullQuotes: [
            PullQuote(
                text: "Wherever the bishop appears, there let the people be, just as wherever Jesus Christ is, there is the catholic Church.",
                attribution: "Ignatius of Antioch",
                context: "Letter to the Smyrnaeans 8, c. 107 AD"
            )
        ],
        sources: [
            HistorySource(title: "Apostolic Fathers", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Apostolic_Fathers", note: nil),
            HistorySource(title: "Letters of Ignatius of Antioch", author: "Ignatius of Antioch", kind: .primary, url: nil, note: "Available at newadvent.org/fathers and ccel.org."),
            HistorySource(title: "The Didache", author: nil, kind: .primary, url: nil, note: "Earliest known Christian church manual; English at earlychristianwritings.com."),
            HistorySource(title: "The Apostolic Fathers: Greek Texts and English Translations", author: "Michael W. Holmes (ed.)", kind: .scholarly, url: nil, note: "Baker Academic, 3rd ed., 2007.")
        ],
        related: ["early-apologists", "early-bishops", "origins-canon-process"]
    )

    static let earlyApologists = HistoryArticle(
        id: "early-apologists",
        title: "The Apologists",
        subtitle: "Justin Martyr, Irenaeus, and the defenders of Christian faith in a hostile world.",
        era: "120 — 250 AD",
        estimatedMinutes: 5,
        body: [
            .paragraph("As Christianity spread through the Roman Empire, it drew suspicion. Romans accused Christians of atheism (for refusing to honor the gods), incest (for calling each other 'brother' and 'sister'), and cannibalism (a malicious twisting of the Eucharist). In response, a generation of educated Christian writers stepped forward to explain the faith to outsiders and refute distortions. They are conventionally called the apologists, from the Greek apologia — a reasoned defense."),
            .heading("Justin Martyr"),
            .paragraph("Justin (c. 100–165) was a philosopher who converted to Christianity and continued to wear his philosopher's robe afterward. His First and Second Apologies, addressed to the Roman Emperor Antoninus Pius, defended Christian morality, explained Christian worship, and argued that Christ was the fulfillment of Greek philosophy's deepest insights. He was beheaded in Rome around 165, earning him the title 'Martyr.'"),
            .heading("Irenaeus of Lyons"),
            .paragraph("Irenaeus (c. 130–202) was a disciple of Polycarp, who had been a disciple of John the Apostle. His five-volume work Against Heresies (c. 180) is the most important surviving second-century Christian treatise. He confronted Gnostic teachers who claimed secret knowledge passed down through hidden lineages, and he countered them by listing the public, traceable succession of bishops in major churches — particularly Rome — going back to the apostles."),
            .heading("Other apologists"),
            .list([
                "Aristides of Athens (c. 125) — early defender of Christian morality.",
                "Tatian (c. 120–180) — student of Justin who composed the Diatessaron, a four-Gospel harmony used in Syriac churches.",
                "Athenagoras of Athens (c. 133–190) — addressed the Plea for the Christians to Marcus Aurelius.",
                "Theophilus of Antioch (d. c. 184) — first known writer to use the term 'Trinity' (Greek Trias).",
                "Tertullian (c. 155–220) — Latin-speaking North African writer who coined Latin theological vocabulary still used today."
            ]),
            .heading("Why they mattered"),
            .paragraph("The apologists shaped Christian self-understanding in important ways. They engaged seriously with Greek philosophy, argued for the rationality of Christian faith, and articulated foundational ideas about the Trinity, Christ's nature, and the church's continuity with the apostles — all before the great ecumenical councils began.")
        ],
        pullQuotes: [
            PullQuote(
                text: "Whatever things were rightly said among all men, are the property of us Christians.",
                attribution: "Justin Martyr",
                context: "Second Apology 13"
            )
        ],
        sources: [
            HistorySource(title: "First Apology", author: "Justin Martyr", kind: .primary, url: nil, note: "Available at newadvent.org/fathers."),
            HistorySource(title: "Against Heresies", author: "Irenaeus of Lyons", kind: .primary, url: nil, note: "Five books; available at newadvent.org/fathers."),
            HistorySource(title: "Apologetics", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Apologetics", note: nil),
            HistorySource(title: "The Early Church", author: "Henry Chadwick", kind: .scholarly, url: nil, note: "Penguin, rev. ed. 1993.")
        ],
        related: ["early-fathers", "early-bishops"]
    )

    static let earlyBishops = HistoryArticle(
        id: "early-bishops",
        title: "Bishops & Apostolic Succession",
        subtitle: "How a flat first-century church became hierarchical by 200 AD.",
        era: "60 — 250 AD",
        estimatedMinutes: 6,
        body: [
            .paragraph("The New Testament uses two Greek terms that later traditions distinguish but the apostolic writings sometimes appear to overlap: episkopos (overseer, bishop) and presbyteros (elder). In Acts 20, Paul addresses the Ephesian elders (presbyteroi) and refers to them as overseers (episkopoi) in the same speech. Titus 1 uses both terms within a few verses. This linguistic flexibility has been read very differently by later traditions."),
            .heading("What the NT says"),
            .paragraph("The earliest Christian communities had recognized leaders — apostles, prophets, teachers, elders, deacons. The exact relationship between elders and overseers is debated. Some passages suggest the two terms describe the same office; others suggest a distinction that may have varied by region. Deacons are clearly a separate office, distinguished by their service ministry (Acts 6, 1 Timothy 3)."),
            .heading("The threefold ministry by 110 AD"),
            .paragraph("Within a generation of John's death, the letters of Ignatius of Antioch (c. 107) describe a clearly threefold ministry: one bishop, multiple presbyters (elders), and deacons in each city. Ignatius assumes this structure as already universal and writes with intense emphasis on respecting the bishop. Whether his pattern was already universal or was being promoted by him is debated."),
            .heading("Apostolic succession"),
            .paragraph("By the late second century, writers like Irenaeus appealed to apostolic succession — an unbroken line of bishops traceable back to one of the apostles — as evidence of true Christian teaching against Gnostic claims of secret knowledge. The argument was: the apostles taught their successors openly; those successors taught the next generation; the chain is public and verifiable; therefore the public faith of the church is what the apostles actually taught."),
            .heading("How traditions read this differently"),
            .paragraph("Catholic and Orthodox traditions hold that apostolic succession is itself an apostolic institution — the bishops are the apostles' successors in office, with continuing authority to teach, ordain, and govern. Most Protestant traditions accept some form of historical succession but locate authority in the apostolic teaching (the New Testament) rather than in an unbroken chain of office-holders. Some traditions, including most Restoration Movement churches, reject the threefold ministry as a post-apostolic development and recognize only elders and deacons in autonomous local congregations.")
        ],
        pullQuotes: [
            PullQuote(
                text: "We can enumerate those who were instituted bishops by the apostles in the churches, and the succession of these men to our own times.",
                attribution: "Irenaeus of Lyons",
                context: "Against Heresies 3.3.1, c. 180 AD"
            )
        ],
        sources: [
            HistorySource(title: "Letters of Ignatius", author: "Ignatius of Antioch", kind: .primary, url: nil, note: "Especially Smyrnaeans, Ephesians, Magnesians, Trallians."),
            HistorySource(title: "Against Heresies, Books 3.1–3.5", author: "Irenaeus of Lyons", kind: .primary, url: nil, note: nil),
            HistorySource(title: "Apostolic succession", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Apostolic_succession", note: nil),
            HistorySource(title: "From Apostles to Bishops: The Development of the Episcopacy in the Early Church", author: "Francis A. Sullivan", kind: .scholarly, url: nil, note: "Newman Press, 2001.")
        ],
        related: ["early-fathers", "practices-government", "denominations-restoration"]
    )

    static let earlyEucharist = HistoryArticle(
        id: "early-eucharist",
        title: "Sacramental Eucharist in the Fathers",
        subtitle: "How early Christians described what happens at the Lord's Table.",
        era: "100 — 500 AD",
        estimatedMinutes: 6,
        body: [
            .paragraph("How Christians have understood the bread and wine of the Lord's Supper is one of the most consequential — and divisive — questions in Christian history. The New Testament passages everyone reads together (the institution narratives in the Synoptics and 1 Corinthians 11, Jesus' 'bread of life' discourse in John 6, Paul's warnings in 1 Corinthians 10–11) are read very differently by different traditions. The early Christian writings outside the New Testament show what meanings dominated in the centuries closest to the apostles."),
            .heading("Realistic language from the start"),
            .paragraph("The earliest extra-canonical Christian writings consistently use realistic language about the Eucharist. The Didache (c. 50–120) calls the rite a 'sacrifice.' Ignatius of Antioch (c. 107) calls the Eucharist 'the medicine of immortality' and condemns docetic teachers who 'abstain from the Eucharist… because they do not confess that the Eucharist is the flesh of our Savior Jesus Christ.' Justin Martyr (c. 150) writes that Christians do not receive the consecrated bread 'as common bread or common drink,' but as the flesh and blood of Christ."),
            .heading("Centuries of consensus"),
            .paragraph("From roughly 100 AD to at least the eleventh century, no surviving major Christian writer denies a real connection between the Eucharistic elements and the body and blood of Christ. The exact mechanism was discussed in many ways — as transformation, as participation, as mystery — but the basic claim was widely shared across Latin, Greek, Syriac, Coptic, Armenian, and Ethiopian traditions, even where those traditions otherwise disagreed sharply."),
            .heading("First major dissent"),
            .paragraph("The earliest significant published dissent from this consensus came from Berengar of Tours (c. 999–1088), a French theologian who argued for a more symbolic interpretation. He was repeatedly required to recant. His questions, however, helped trigger a wave of theological precision in the West, leading eventually to the formal Catholic doctrine of transubstantiation, defined at the Fourth Lateran Council in 1215."),
            .heading("Reformation divisions"),
            .paragraph("The Protestant Reformation in the sixteenth century produced multiple new positions:"),
            .list([
                "Lutherans affirmed Christ's real presence 'in, with, and under' the bread and wine, but rejected transubstantiation.",
                "Reformed/Calvinist churches taught a real spiritual presence — the believer feeds on Christ by faith, but Christ's body is in heaven.",
                "Zwinglian churches treated the Lord's Supper as a memorial — the bread and wine signify Christ's sacrifice without conveying his presence.",
                "Most Restoration Movement churches and many Baptist and free-church traditions adopted variations of the memorial view."
            ]),
            .heading("Where things stand"),
            .paragraph("Today, Catholic, Orthodox, and many Anglican and Lutheran churches retain a strong sacramental theology of the Eucharist. Reformed and many Methodist churches typically affirm a spiritual presence. Most Baptist, non-denominational, and Restoration churches teach a memorial view. The differences are real, but every tradition agrees that the Lord's Supper is central to Christian worship and is something Christ commanded his church to do.")
        ],
        pullQuotes: [
            PullQuote(
                text: "Take care, then, to use one Eucharist, so that whatever you do, you do according to God: for there is one flesh of our Lord Jesus Christ, and one cup to unite us with His blood, and one altar.",
                attribution: "Ignatius of Antioch",
                context: "Letter to the Philadelphians 4, c. 107 AD"
            )
        ],
        sources: [
            HistorySource(title: "Letters of Ignatius", author: "Ignatius of Antioch", kind: .primary, url: nil, note: nil),
            HistorySource(title: "First Apology, ch. 66", author: "Justin Martyr", kind: .primary, url: nil, note: nil),
            HistorySource(title: "The Didache, chs. 9–10, 14", author: nil, kind: .primary, url: nil, note: nil),
            HistorySource(title: "Eucharistic theology", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Eucharistic_theology", note: nil),
            HistorySource(title: "Berengar of Tours", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Berengar_of_Tours", note: nil)
        ],
        related: ["early-fathers", "practices-lords-supper"]
    )
}
