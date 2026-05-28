//
//  HistoryOrigins.swift
//  swiftbible
//
//  Section 1 — Origins of the New Testament.
//

import Foundation

extension HistorySection {
    static let origins = HistorySection(
        id: "origins",
        title: "Origins of the New Testament",
        subtitle: "How 27 documents written across 50 years became Scripture.",
        symbol: "scroll",
        era: "50 — 397 AD",
        articles: [
            .originsTimeline,
            .originsCanonProcess,
            .originsDisputedBooks,
            .originsMarcion
        ]
    )
}

extension HistoryArticle {
    static let originsTimeline = HistoryArticle(
        id: "origins-timeline",
        title: "From Letters to Canon",
        subtitle: "Three centuries between the apostles and the official 27-book list.",
        era: "50 — 397 AD",
        estimatedMinutes: 5,
        body: [
            .paragraph("The New Testament was not handed down as a finished book. Its 27 documents were written across roughly the second half of the first century, then circulated, copied, debated, and gradually recognized as Scripture by churches across the Roman Empire and beyond. The process of formal recognition stretched over three centuries."),
            .heading("What was written, and when"),
            .paragraph("The earliest New Testament writings are most likely some of Paul's letters, with 1 Thessalonians often dated to around 50 AD. The four Gospels followed: most scholars place Mark in the late 60s, Matthew and Luke in the 70s or 80s, and John near the end of the first century. Acts, Hebrews, the General Epistles, and Revelation fill out the corpus by roughly 95 AD."),
            .heading("How they spread"),
            .paragraph("Each text was written for a specific audience — a church, a person, a network of communities — but copies travelled. By the early 100s, churches in Rome, Antioch, and Asia Minor were trading manuscripts. Bishops cited multiple Gospels and Pauline letters as authoritative without yet defining a fixed list."),
            .heading("Pressure to define a list"),
            .paragraph("The catalyst for a formal canon came partly from heretical teachers. Around 140 AD, Marcion of Sinope published his own narrow canon — a single edited Gospel and ten Pauline letters — rejecting the Old Testament entirely. The wider church now had to articulate which writings it considered Scripture and why."),
            .timeline([
                TimelineEntry(year: "c. 50 AD", event: "1 Thessalonians, earliest dated NT letter."),
                TimelineEntry(year: "c. 70 AD", event: "Mark, the first Gospel composed."),
                TimelineEntry(year: "c. 95 AD", event: "Revelation; NT corpus essentially complete."),
                TimelineEntry(year: "c. 140 AD", event: "Marcion's heretical canon forces a response."),
                TimelineEntry(year: "c. 170 AD", event: "Muratorian Fragment lists most NT books."),
                TimelineEntry(year: "c. 200 AD", event: "Tertullian uses 'New Testament' as a title."),
                TimelineEntry(year: "367 AD", event: "Athanasius's 39th Festal Letter — first list of the modern 27."),
                TimelineEntry(year: "382, 393, 397 AD", event: "Synods of Rome, Hippo, and Carthage ratify the canon.")
            ]),
            .heading("The 27 books recognized"),
            .paragraph("By the late fourth century, both Greek-speaking and Latin-speaking churches had converged on the 27 books that all major branches of Christianity still hold today. Disagreements over a few 'disputed books' — Hebrews, James, 2 Peter, 2–3 John, Jude, and Revelation — were resolved during this period. A handful of writings highly valued by some early Christians, such as the Shepherd of Hermas and 1 Clement, were ultimately not included.")
        ],
        pullQuotes: [
            PullQuote(
                text: "Among them are received the four Gospels of Matthew, Mark, Luke, and John… fourteen Epistles of Paul… seven Catholic Epistles… and the Apocalypse of John.",
                attribution: "Athanasius",
                context: "Festal Letter 39, 367 AD"
            )
        ],
        sources: [
            HistorySource(title: "Development of the New Testament canon", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Development_of_the_New_Testament_canon", note: nil),
            HistorySource(title: "Festal Letter 39", author: "Athanasius", kind: .primary, url: nil, note: "Available in English at newadvent.org/fathers and ccel.org."),
            HistorySource(title: "The Canon of the New Testament: Its Origin, Development, and Significance", author: "Bruce M. Metzger", kind: .scholarly, url: nil, note: "Oxford, 1987 — standard scholarly reference."),
            HistorySource(title: "The Canon of Scripture", author: "F. F. Bruce", kind: .scholarly, url: nil, note: "InterVarsity, 1988 — accessible Protestant treatment.")
        ],
        related: ["origins-canon-process", "origins-disputed-books", "origins-marcion"]
    )

    static let originsCanonProcess = HistoryArticle(
        id: "origins-canon-process",
        title: "How the 27 Books Were Chosen",
        subtitle: "Apostolic origin, widespread use, and orthodox content.",
        era: "100 — 400 AD",
        estimatedMinutes: 5,
        body: [
            .paragraph("When ancient Christians evaluated whether a writing belonged in Scripture, they generally applied three overlapping tests: apostolic origin, widespread use, and consistency with the rule of faith. None of these criteria appears as a formal checklist in any single early document, but they show up consistently across the writings of figures like Eusebius, Origen, Athanasius, and Augustine."),
            .heading("Apostolic origin"),
            .paragraph("A book's connection to an apostle or apostolic associate weighed heavily. The four Gospels were attributed to Matthew (an apostle), Mark (an associate of Peter), Luke (an associate of Paul), and John (an apostle). Pauline authorship was claimed for the thirteen letters bearing his name. Hebrews was disputed in part because its author was unnamed."),
            .heading("Widespread use"),
            .paragraph("Writings already read in worship across multiple regions had a strong claim. A book accepted only in one corner of the empire could be a local treasure, not Scripture. The four Gospels and the major Pauline letters met this test almost universally by the second century. Other writings, however valuable, did not circulate as broadly."),
            .heading("Rule of faith"),
            .paragraph("Texts also had to align with what the church already taught. Documents that contradicted the apostolic preaching or promoted theological systems considered heretical were rejected. This is why Gnostic writings such as the Gospel of Thomas and the Gospel of Judas — though sometimes attributed to apostles — never made the canon. Their underlying theology was incompatible with mainstream Christian belief."),
            .heading("Recognition, not invention"),
            .paragraph("It is important to distinguish between recognition and invention. Most historians agree that fourth-century church councils did not create a canon out of thin air; they ratified a consensus that had already taken shape over the previous two centuries. Lists like the Muratorian Fragment (c. 170 AD) and the canon described by Origen (c. 240 AD) show that the broad outlines were settled long before any formal council."),
            .heading("Different traditions, different deliberations"),
            .paragraph("Recognition was not perfectly synchronized everywhere. The Syriac-speaking church, for example, used a four-Gospel harmony called the Diatessaron well into the fifth century before adopting the four separate Gospels. The Ethiopian Orthodox tradition kept a slightly larger canon. The basic 27-book core, however, came to be shared by every major Christian tradition.")
        ],
        pullQuotes: [
            PullQuote(
                text: "We must not consider it a small matter that they were once esteemed as Scripture by the ancients.",
                attribution: "Eusebius of Caesarea",
                context: "Ecclesiastical History 3.25"
            )
        ],
        sources: [
            HistorySource(title: "Ecclesiastical History, Book 3, Chapter 25", author: "Eusebius of Caesarea", kind: .primary, url: nil, note: "Available in English at newadvent.org/fathers and ccel.org."),
            HistorySource(title: "Biblical canon", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Biblical_canon", note: nil),
            HistorySource(title: "The Biblical Canon: Its Origin, Transmission, and Authority", author: "Lee Martin McDonald", kind: .scholarly, url: nil, note: "Hendrickson, 3rd ed., 2007."),
            HistorySource(title: "Muratorian Fragment", author: nil, kind: .primary, url: "https://en.wikipedia.org/wiki/Muratorian_fragment", note: "c. 170 AD canon list.")
        ],
        related: ["origins-timeline", "origins-disputed-books"]
    )

    static let originsDisputedBooks = HistoryArticle(
        id: "origins-disputed-books",
        title: "The Disputed Books",
        subtitle: "Hebrews, James, 2 Peter, Jude, and Revelation almost didn't make it.",
        era: "150 — 400 AD",
        estimatedMinutes: 6,
        body: [
            .paragraph("A common assumption is that the New Testament's 27 books were obvious from the beginning. The historical record is more textured. Several books were widely accepted from the second century onward, while others — sometimes called the antilegomena, 'the disputed' — faced serious questions about their authorship, content, or fit with the rest of the canon."),
            .heading("Hebrews"),
            .paragraph("The author of Hebrews never identifies himself, and ancient Christians could not agree on whether Paul wrote it. The Eastern church generally accepted Pauline authorship and included Hebrews early; Western churches were more skeptical. By the late fourth century, both East and West had received it as Scripture, though debate over the actual author has continued into modern scholarship."),
            .heading("James"),
            .paragraph("The Epistle of James was read in some churches from early on, but its emphasis on works alongside faith led to occasional doubts about its message. Eusebius classed it among the disputed books in the early 300s. Martin Luther later expressed reservations about James in the 1500s, calling it an 'epistle of straw,' though he kept it in his Bible."),
            .heading("2 Peter, 2 John, 3 John, Jude"),
            .paragraph("These short letters circulated less widely than the major epistles. Doubts about 2 Peter's authorship were raised even in the early church because its style differs noticeably from 1 Peter. The brevity and limited circulation of 2 and 3 John raised similar questions. Jude's heavy use of non-canonical texts — including 1 Enoch, which it appears to quote directly — also troubled some readers. All four were eventually accepted by both East and West."),
            .heading("Revelation"),
            .paragraph("Revelation had perhaps the most uneven reception. Several Eastern fathers, including Eusebius, were uncertain about it, partly because of its difficult symbolism and partly because some early Christians used it to argue for a literal earthly millennial kingdom that was later considered theologically problematic. The Greek-speaking church accepted it slowly; even after Athanasius's list in 367 AD, some Eastern writers continued to express reservations. The Syriac Peshitta omitted it for centuries."),
            .heading("Books that almost made it"),
            .paragraph("Some early Christian writings were read in worship and quoted as Scripture in particular regions but ultimately did not become part of the canon. The Shepherd of Hermas appears in Codex Sinaiticus, one of the earliest surviving full Bibles. 1 Clement was treated as Scripture in some Egyptian churches. The Didache was used as a teaching manual. None of these were ever as widely received as the 27 books, and all were eventually classified as edifying but not canonical.")
        ],
        pullQuotes: [
            PullQuote(
                text: "Among the disputed writings, which are nevertheless recognized by many, are the so-called Epistle of James and that of Jude, also the second Epistle of Peter, and those that are called the second and third of John.",
                attribution: "Eusebius of Caesarea",
                context: "Ecclesiastical History 3.25"
            )
        ],
        sources: [
            HistorySource(title: "Ecclesiastical History 3.25", author: "Eusebius of Caesarea", kind: .primary, url: nil, note: nil),
            HistorySource(title: "Antilegomena", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Antilegomena", note: nil),
            HistorySource(title: "Book of Revelation", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Book_of_Revelation", note: nil),
            HistorySource(title: "The Canon of the New Testament", author: "Bruce M. Metzger", kind: .scholarly, url: nil, note: "Oxford, 1987.")
        ],
        related: ["origins-canon-process", "origins-timeline"]
    )

    static let originsMarcion = HistoryArticle(
        id: "origins-marcion",
        title: "Marcion's Heretical Canon",
        subtitle: "The 2nd-century preacher whose rejection sharpened the church's list.",
        era: "c. 140 AD",
        estimatedMinutes: 5,
        body: [
            .paragraph("In the first half of the second century, a wealthy ship-owner from the Black Sea region named Marcion travelled to Rome with a radical proposal. The God of the Old Testament, he argued, was a different deity from the loving Father revealed by Jesus. The Hebrew Scriptures were therefore the record of an inferior god and had no place in Christian Scripture. To replace them, Marcion proposed his own canon — a single Gospel based on Luke (heavily edited to remove Jewish elements) and ten letters of Paul (also abridged)."),
            .heading("Why it mattered"),
            .paragraph("Marcion's proposal forced a question the wider church had not yet had to answer in a formal way: which writings actually belonged to Christian Scripture, and on what grounds? Until then, the boundaries had been informal — drawn in practice by which texts were read in worship and by whom. Marcion presented a complete, internally consistent alternative, and that alternative had to be answered."),
            .heading("How the church responded"),
            .paragraph("Marcion was excommunicated from the Roman church around 144 AD. Critics — most prominently Tertullian, whose Against Marcion survives as a five-volume rebuttal — defended the unity of Scripture and the continuity between Israel's God and the God of Jesus. They affirmed not only the four Gospels but also a wider Pauline corpus, the General Epistles, and Acts, all of which Marcion had rejected."),
            .heading("Outcomes"),
            .paragraph("Marcionism survived as a parallel movement for several centuries before fading. Its most lasting effect on Christian history was indirect: it accelerated the development of explicit canon lists, sharpened theological reflection on the relationship between the Old and New Testaments, and contributed to a more articulate doctrine of God's covenantal continuity from Genesis to Revelation."),
            .heading("Modern echoes"),
            .paragraph("Historians sometimes describe certain modern movements that downplay or marginalize the Old Testament as 'neo-Marcionite' in tendency. The label is contested, but it points to a recurring impulse — to treat the God of Israel as somehow disconnected from the God of Christ — that mainstream Christianity, then and now, has consistently rejected.")
        ],
        pullQuotes: [
            PullQuote(
                text: "Marcion's special and principal work is the separation of the law and the gospel.",
                attribution: "Tertullian",
                context: "Against Marcion 1.19, c. 207 AD"
            )
        ],
        sources: [
            HistorySource(title: "Against Marcion", author: "Tertullian", kind: .primary, url: nil, note: "Five books; available at newadvent.org/fathers."),
            HistorySource(title: "Marcion of Sinope", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Marcion_of_Sinope", note: nil),
            HistorySource(title: "Marcionism", author: nil, kind: .encyclopedia, url: "https://en.wikipedia.org/wiki/Marcionism", note: nil),
            HistorySource(title: "Marcion: The Gospel of the Alien God", author: "Adolf von Harnack", kind: .scholarly, url: nil, note: "1921; English trans. Labyrinth Press, 1990.")
        ],
        related: ["origins-timeline", "origins-canon-process"]
    )
}
