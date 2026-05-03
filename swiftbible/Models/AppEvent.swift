//
//  AppEvent.swift
//  swiftbible
//
//  In-app event model. Surfaces a date-gated card in MoreView so users
//  can return to an active App Store In-App Event after dismissing it.
//  Add new entries to AppEventRegistry.allEvents — they auto-show during
//  their date window and disappear after.
//

import SwiftUI

struct AppEvent: Identifiable, Equatable {
    let id: String
    let name: String
    let subtitle: String
    let iconName: String   // SF Symbol
    let accent: AppEventAccent
    let startDate: Date
    let endDate: Date
    let action: AppEventAction
    /// Optional asset-catalog image name to render as a hero banner on the
    /// MoreView card. Same source as the App Store EVENT_CARD image.
    let bannerImageName: String?
    /// Optional day-by-day reading plan. When non-empty, the event opens an
    /// EventDetailView with day pagination. When empty, action is used.
    let readingPlan: [EventReadingDay]

    init(id: String, name: String, subtitle: String, iconName: String,
         accent: AppEventAccent, startDate: Date, endDate: Date,
         action: AppEventAction,
         bannerImageName: String? = nil,
         readingPlan: [EventReadingDay] = []) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.iconName = iconName
        self.accent = accent
        self.startDate = startDate
        self.endDate = endDate
        self.action = action
        self.bannerImageName = bannerImageName
        self.readingPlan = readingPlan
    }

    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }

    /// Returns the reading-plan day matching today, or the next upcoming day
    /// if today is before the event, or the last day if today is past it.
    var todayReadingIndex: Int {
        guard !readingPlan.isEmpty else { return 0 }
        let now = Date()
        let cal = Calendar.current
        if let idx = readingPlan.firstIndex(where: { cal.isDate($0.date, inSameDayAs: now) }) {
            return idx
        }
        if let idx = readingPlan.firstIndex(where: { $0.date >= now }) {
            return idx
        }
        return readingPlan.count - 1
    }
}

enum AppEventAccent: Equatable {
    case gold
    case red
    case accent

    var color: Color {
        switch self {
        case .gold: return .brandGold
        case .red: return .brandRedDark
        case .accent: return .brandAccent
        }
    }
}

enum AppEventAction: Equatable {
    /// Open a specific verse via AppViewModel.navigateToVerse.
    case openVerse(book: String, chapter: Int, verse: Int)
    /// Just switch tabs (e.g., to dailyDevotional).
    case openTab(Tabs)
    /// Open the curated EventDetailView for this event (uses readingPlan).
    case openEvent
}

struct EventReadingDay: Identifiable, Equatable {
    let id: String
    let date: Date
    let theme: String
    let passage: ScriptureRef
    let reflection: String

    var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: date)
    }
}

struct ScriptureRef: Equatable {
    let book: String
    let chapter: Int
    let startVerse: Int
    let endVerse: Int

    var displayLabel: String {
        if endVerse > startVerse {
            return "\(book) \(chapter):\(startVerse)-\(endVerse)"
        }
        return "\(book) \(chapter):\(startVerse)"
    }
}

/// Static registry of all events the app knows about. Edit `allEvents` to
/// add or remove. The MoreView shows only entries currently within their
/// date window.
enum AppEventRegistry {

    static let pentecost2026 = AppEvent(
        id: "pentecost-2026",
        name: "Pentecost Reading Plan",
        subtitle: "Acts 2 — through June 7",
        iconName: "flame.fill",
        accent: .gold,
        startDate: parseISO("2026-05-25T00:00:00Z"),
        endDate: parseISO("2026-06-07T23:59:59Z"),
        action: .openEvent,
        bannerImageName: "PentecostEventBanner",
        readingPlan: pentecostReadingPlan
    )

    /// All known events. Add new ones here.
    static let allEvents: [AppEvent] = [
        pentecost2026
    ]

    /// Events currently within their date window.
    static var activeEvents: [AppEvent] {
        allEvents.filter(\.isActive)
    }

    /// What MoreView actually shows. In DEBUG builds, the
    /// `debug_forceShowEvents` AppStorage flag overrides date-gating so all
    /// events appear regardless of window — useful for testing the card
    /// + EventDetailView flow before the real event window opens.
    static var visibleEvents: [AppEvent] {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "debug_forceShowEvents") {
            return allEvents
        }
        #endif
        return activeEvents
    }

    /// Look up an event by id. Used by URL scheme handler.
    static func event(forId id: String) -> AppEvent? {
        allEvents.first(where: { $0.id == id })
    }

    private static func parseISO(_ s: String) -> Date {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: s) ?? .distantFuture
    }

    // MARK: - Pentecost 8-day reading plan (KJV)

    private static let pentecostReadingPlan: [EventReadingDay] = [
        EventReadingDay(
            id: "pentecost-2026-day-1",
            date: parseISO("2026-05-25T00:00:00Z"),
            theme: "The Promise of the Spirit",
            passage: ScriptureRef(book: "Acts", chapter: 1, startVerse: 1, endVerse: 11),
            reflection: """
            Luke wrote Acts as a sequel to his Gospel for the same reader, Theophilus. Eleven verses cover Jesus's last forty days on earth — what he taught, what he commanded, and how he left.

            > "The former treatise have I made, O Theophilus, of all that Jesus began both to do and teach," (v.1)

            "Began." Acts is what Jesus continued doing — through the Spirit and the Church.

            > "Until the day in which he was taken up, after that he through the Holy Ghost had given commandments unto the apostles whom he had chosen:" (v.2)

            Even Jesus's commandments to the apostles came "through the Holy Ghost." The Spirit was already at work.

            > "To whom also he shewed himself alive after his passion by many infallible proofs, being seen of them forty days, and speaking of the things pertaining to the kingdom of God:" (v.3)

            Forty days. Many proofs. The resurrection was witnessed, eaten with, and discussed — not a vision or a feeling.

            > "And, being assembled together with them, commanded them that they should not depart from Jerusalem, but wait for the promise of the Father, which, saith he,"

            > [J] "ye have heard of me." (v.4)

            First instruction: don't leave. Wait. That is the only command on the table.

            > [J] "For John truly baptized with water; but ye shall be baptized with the Holy Ghost not many days hence." (v.5)

            John's baptism prepared. The Spirit's baptism fulfills. "Not many days" turns out to be ten.

            > "When they therefore were come together, they asked of him, saying, Lord, wilt thou at this time restore again the kingdom to Israel?" (v.6)

            Forty days of teaching and they are still hoping for political restoration. Old expectations die hard.

            > "And he said unto them,"

            > [J] "It is not for you to know the times or the seasons, which the Father hath put in his own power." (v.7)

            Jesus declines to answer. Some things are not yours to know — your job is faithfulness, not foresight.

            > [J] "But ye shall receive power, after that the Holy Ghost is come upon you: and ye shall be witnesses unto me both in Jerusalem, and in all Judaea, and in Samaria, and unto the uttermost part of the earth." (v.8)

            The mission, in one verse. Power for witness, expanding outward — Jerusalem, Judaea, Samaria, the world. Acts is structured around these geographic circles.

            > "And when he had spoken these things, while they beheld, he was taken up; and a cloud received him out of their sight." (v.9)

            He left mid-thought. They saw it happen.

            > "And while they looked stedfastly toward heaven as he went up, behold, two men stood by them in white apparel;" (v.10)

            They keep staring. Two angels appear.

            > "Which also said, Ye men of Galilee, why stand ye gazing up into heaven? this same Jesus, which is taken up from you into heaven, shall so come in like manner as ye have seen him go into heaven." (v.11)

            The angels redirect them. Don't sky-gaze. He will return the same way. Get on with the mission he just gave you.

            Acts begins in the gap. Jesus is gone. The Spirit has not come. The disciples have a command (wait), a mission (witness), and a promise (he returns). Pentecost makes everything else possible — but first, ten days in an upper room.
            """
        ),
        EventReadingDay(
            id: "pentecost-2026-day-2",
            date: parseISO("2026-05-26T00:00:00Z"),
            theme: "Waiting Together",
            passage: ScriptureRef(book: "Acts", chapter: 1, startVerse: 12, endVerse: 26),
            reflection: """
            The ten days between the ascension and Pentecost. Most of this passage is what nobody photographs — a hundred and twenty people praying in a room, plus the only piece of business they did during the wait: replacing Judas.

            > "Then returned they unto Jerusalem from the mount called Olivet, which is from Jerusalem a sabbath day's journey." (v.12)

            About two-thirds of a mile. Close enough to walk back the same morning Jesus left.

            > "And when they were come in, they went up into an upper room, where abode both Peter, and James, and John, and Andrew, Philip, and Thomas, Bartholomew, and Matthew, James the son of Alphaeus, and Simon Zelotes, and Judas the brother of James." (v.13)

            Probably the same upper room from the Last Supper. Eleven names; Judas Iscariot is conspicuously missing.

            > "These all continued with one accord in prayer and supplication, with the women, and Mary the mother of Jesus, and with his brethren." (v.14)

            Three groups: the eleven, the women who followed Jesus, Mary and Jesus's brothers. The brothers had not believed him before the resurrection (John 7:5). Something changed.

            > "And in those days Peter stood up in the midst of the disciples, and said, (the number of names together were about an hundred and twenty,)" (v.15)

            One hundred and twenty. Not just the eleven — a small congregation.

            > "Men and brethren, this scripture must needs have been fulfilled, which the Holy Ghost by the mouth of David spake before concerning Judas, which was guide to them that took Jesus." (v.16)

            Peter is already reading the Scriptures Christologically — David's words about a betrayer applied to Judas.

            > "For he was numbered with us, and had obtained part of this ministry." (v.17)

            A sober reminder. Judas was an apostle. Position alone does not save you.

            > "Now this man purchased a field with the reward of iniquity; and falling headlong, he burst asunder in the midst, and all his bowels gushed out." (v.18)

            A hard verse. Luke does not soften Judas's end.

            > "And it was known unto all the dwellers at Jerusalem; insomuch as that field is called in their proper tongue, Aceldama, that is to say, The field of blood." (v.19)

            Public knowledge. The field had a name.

            > "For it is written in the book of Psalms, Let his habitation be desolate, and let no man dwell therein: and his bishoprick let another take." (v.20)

            Two psalms (69 and 109) read as prophecy. The second clause justifies replacing Judas.

            > "Wherefore of these men which have companied with us all the time that the Lord Jesus went in and out among us," (v.21)

            > "Beginning from the baptism of John, unto that same day that he was taken up from us, must one be ordained to be a witness with us of his resurrection." (v.22)

            The qualification: someone who was there from John's baptism through the ascension. An eyewitness, not a recent convert.

            > "And they appointed two, Joseph called Barsabas, who was surnamed Justus, and Matthias." (v.23)

            Two qualified men. Either would do.

            > "And they prayed, and said, Thou, Lord, which knowest the hearts of all men, shew whether of these two thou hast chosen," (v.24)

            They do not vote. They ask God to choose.

            > "That he may take part of this ministry and apostleship, from which Judas by transgression fell, that he might go to his own place." (v.25)

            "His own place." A measured way of saying what they meant.

            > "And they gave forth their lots; and the lot fell upon Matthias; and he was numbered with the eleven apostles." (v.26)

            They cast lots — the last time the New Testament records this method. After Pentecost the Spirit guides decisions directly.

            They were not waiting alone. They were not waiting passively. One hundred and twenty people in a room, praying for ten days, doing the next small thing they could do. When God seems quiet, that is often the work — gather, ask, keep showing up.
            """
        ),
        EventReadingDay(
            id: "pentecost-2026-day-3",
            date: parseISO("2026-05-27T00:00:00Z"),
            theme: "Another Comforter",
            passage: ScriptureRef(book: "John", chapter: 14, startVerse: 15, endVerse: 31),
            reflection: """
            Back up in the timeline. Before the cross, before the resurrection, before the ascension — Jesus prepares his disciples for a world without his physical presence. The Spirit is not the consolation prize. He is the means by which Jesus's promises become possible.

            > [J] "If ye love me, keep my commandments." (v.15)

            Love and obedience are linked. The Spirit comes alongside the people who actually try to live like Jesus said.

            > [J] "And I will pray the Father, and he shall give you another Comforter, that he may abide with you for ever;" (v.16)

            The Greek word for "Comforter" is paraklētos — literally one called alongside. A helper, advocate, counselor. The same kind of helper Jesus has been, just not in a body.

            > [J] "Even the Spirit of truth; whom the world cannot receive, because it seeth him not, neither knoweth him: but ye know him; for he dwelleth with you, and shall be in you." (v.17)

            The world cannot receive him because the world is not looking. The disciples will know him intimately — "with you" becomes "in you."

            > [J] "I will not leave you comfortless: I will come to you." (v.18)

            "Comfortless" is literally "orphans." Jesus is leaving but he is not abandoning them.

            > [J] "Yet a little while, and the world seeth me no more; but ye see me: because I live, ye shall live also." (v.19)

            Resurrection life is about to be the new normal. Because he lives, they will too.

            > [J] "At that day ye shall know that I am in my Father, and ye in me, and I in you." (v.20)

            Mutual indwelling. A union deeper than physical proximity ever was.

            > [J] "He that hath my commandments, and keepeth them, he it is that loveth me: and he that loveth me shall be loved of my Father, and I will love him, and will manifest myself to him." (v.21)

            Three ways of saying the same thing: love proves itself in obedience.

            > "Judas saith unto him, not Iscariot, Lord, how is it that thou wilt manifest thyself unto us, and not unto the world?" (v.22)

            Judas (not Iscariot — likely Thaddaeus) asks what every Christian eventually asks: why isn't this more obvious to the world?

            > "Jesus answered and said unto him,"

            > [J] "If a man love me, he will keep my words: and my Father will love him, and we will come unto him, and make our abode with him." (v.23)

            The answer: love and obedience open the door. The Father and Son make their home with the obedient. Notice the plural "we."

            > [J] "He that loveth me not keepeth not my sayings: and the word which ye hear is not mine, but the Father's which sent me." (v.24)

            The reverse: refusing his words means refusing the Father, not just him.

            > [J] "These things have I spoken unto you, being yet present with you." (v.25)

            He is teaching them now what they will need later.

            > [J] "But the Comforter, which is the Holy Ghost, whom the Father will send in my name, he shall teach you all things, and bring all things to your remembrance, whatsoever I have said unto you." (v.26)

            Two roles for the Spirit: teach and remind. Much of the New Testament is the apostles being reminded of Jesus's words by the Spirit.

            > [J] "Peace I leave with you, my peace I give unto you: not as the world giveth, give I unto you. Let not your heart be troubled, neither let it be afraid." (v.27)

            Not the world's peace — the world's peace is fragile. His peace is given, not earned.

            > [J] "Ye have heard how I said unto you, I go away, and come again unto you. If ye loved me, ye would rejoice, because I said, I go unto the Father: for my Father is greater than I." (v.28)

            If they really loved him, they would rejoice that he is going home, not grieve that he is leaving.

            > [J] "And now I have told you before it come to pass, that, when it is come to pass, ye might believe." (v.29)

            He tells them in advance so they will believe later, not now.

            > [J] "Hereafter I will not talk much with you: for the prince of this world cometh, and hath nothing in me." (v.30)

            Time is short. The cross is hours away.

            > [J] "But that the world may know that I love the Father; and as the Father gave me commandment, even so I do. Arise, let us go hence." (v.31)

            The world must see his obedience to the Father — even unto death. Last sentence before the upper room emptied.

            Pentecost is not about a feeling. It is about being equipped to do what Jesus already commanded. The Comforter comes alongside obedience. Without obedience there is no doorway for him to enter; with it, the Father and the Son make their home in you.
            """
        ),
        EventReadingDay(
            id: "pentecost-2026-day-4",
            date: parseISO("2026-05-28T00:00:00Z"),
            theme: "Into All Truth",
            passage: ScriptureRef(book: "John", chapter: 16, startVerse: 5, endVerse: 15),
            reflection: """
            Two chapters later in the same upper-room conversation. Jesus describes what the Spirit will actually do — convict, guide, glorify. The Spirit is not vague spiritual energy. He has a job description.

            > [J] "But now I go my way to him that sent me; and none of you asketh me, Whither goest thou?" (v.5)

            They are sad about losing him but not curious about where he is going. Grief can blind us to what's coming next.

            > [J] "But because I have said these things unto you, sorrow hath filled your heart." (v.6)

            Honest. Their hearts are filled with sorrow. He does not scold them for it.

            > [J] "Nevertheless I tell you the truth; It is expedient for you that I go away: for if I go not away, the Comforter will not come unto you; but if I depart, I will send him unto you." (v.7)

            Stunning. It is to their advantage that he leaves. They cannot have what comes next without losing what they have now.

            > [J] "And when he is come, he will reprove the world of sin, and of righteousness, and of judgment:" (v.8)

            Three things the Spirit will reprove the world of. Not your truth — the world's wrong reading of sin, of righteousness, and of judgment.

            > [J] "Of sin, because they believe not on me;" (v.9)

            Sin's root: unbelief in Jesus. Other sins are symptoms.

            > [J] "Of righteousness, because I go to my Father, and ye see me no more;" (v.10)

            Righteousness is no longer measured against the law alone — it is measured against Christ, who is now glorified.

            > [J] "Of judgment, because the prince of this world is judged." (v.11)

            Judgment has already happened at the cross. "The prince of this world" — Satan — has been judged.

            > [J] "I have yet many things to say unto you, but ye cannot bear them now." (v.12)

            There is more to teach. They cannot bear it now. Jesus knows what to hold back.

            > [J] "Howbeit when he, the Spirit of truth, is come, he will guide you into all truth: for he shall not speak of himself; but whatsoever he shall hear, that shall he speak: and he will shew you things to come." (v.13)

            Three things again: the Spirit will guide into all truth, will not speak from himself, will report what he hears. He is sent, not autonomous.

            > [J] "He shall glorify me: for he shall receive of mine, and shall shew it unto you." (v.14)

            The point. Everything the Spirit does glorifies Christ. If a "spirituality" leads you somewhere else, it is not the Holy Spirit.

            > [J] "All things that the Father hath are mine: therefore said I, that he shall take of mine, and shall shew it unto you." (v.15)

            Trinity in three lines: what the Father has, the Son has; what the Son has, the Spirit gives.

            If your prayers feel different lately — if there is an uncomfortable awareness of something you have avoided — that may be the Spirit doing his work. He convicts. He guides. He glorifies Christ. Don't run from any of it. He is preparing you.
            """
        ),
        EventReadingDay(
            id: "pentecost-2026-day-5",
            date: parseISO("2026-05-29T00:00:00Z"),
            theme: "Poured Out on All Flesh",
            passage: ScriptureRef(book: "Joel", chapter: 2, startVerse: 28, endVerse: 32),
            reflection: """
            Eight hundred years before Pentecost, the prophet Joel saw it. On Pentecost morning Peter will quote this passage to explain what just happened. Joel said the Spirit was for everyone. Pentecost made him right.

            > "And it shall come to pass afterward, that I will pour out my spirit upon all flesh; and your sons and your daughters shall prophesy, your old men shall dream dreams, your young men shall see visions:" (v.28)

            Read the verse slowly. All flesh. Not the priests. Not the prophets. Sons, daughters, old men, young men.

            > "And also upon the servants and upon the handmaids in those days will I pour out my spirit." (v.29)

            "Servants" includes both genders, both classes. Even the lowest. The Spirit democratized.

            > "And I will shew wonders in the heavens and in the earth, blood, and fire, and pillars of smoke." (v.30)

            Cosmic signs. Joel does not separate Pentecost from the day of the Lord — both come together in his vision.

            > "The sun shall be turned into darkness, and the moon into blood, before the great and terrible day of the LORD come." (v.31)

            The same imagery Jesus uses in the Olivet Discourse. Joel sees the whole arc.

            > "And it shall come to pass, that whosoever shall call on the name of the LORD shall be delivered: for in mount Zion and in Jerusalem shall be deliverance, as the LORD hath said, and in the remnant whom the LORD shall call." (v.32)

            The promise inside the warning. Anyone who calls on the name of the Lord will be saved. Peter will land on this verse in his Pentecost sermon.

            If you have ever felt unqualified to be used by God — too young, too old, too uneducated, too late — this passage is your answer. The Spirit did not come on a few. He came on all who would call.
            """
        ),
        EventReadingDay(
            id: "pentecost-2026-day-6",
            date: parseISO("2026-05-30T00:00:00Z"),
            theme: "Tongues Like as of Fire",
            passage: ScriptureRef(book: "Acts", chapter: 2, startVerse: 1, endVerse: 13),
            reflection: """
            Pentecost morning. The waiting ends. Sound, sight, speech — every sense engaged at once. The promise lands.

            > "And when the day of Pentecost was fully come, they were all with one accord in one place." (v.1)

            "Pentecost" means fiftieth. Fifty days after Passover. They are still in the upper room, still together.

            > "And suddenly there came a sound from heaven as of a rushing mighty wind, and it filled all the house where they were sitting." (v.2)

            Sound first. A wind that is not a wind — the noise of one. The whole house fills.

            > "And there appeared unto them cloven tongues like as of fire, and it sat upon each of them." (v.3)

            Then sight. Tongues like fire — the Old Testament image of God's presence (the burning bush, Sinai, the pillar). One on each of them. Personal.

            > "And they were all filled with the Holy Ghost, and began to speak with other tongues, as the Spirit gave them utterance." (v.4)

            Then speech. They speak languages they have never learned. The Spirit gives the words.

            > "And there were dwelling at Jerusalem Jews, devout men, out of every nation under heaven." (v.5)

            Pentecost was a pilgrimage feast. Jews from the diaspora were in town for it.

            > "Now when this was noised abroad, the multitude came together, and were confounded, because that every man heard them speak in his own language." (v.6)

            The crowd hears the noise and gathers. Each one hears in his own language.

            > "And they were all amazed and marvelled, saying one to another, Behold, are not all these which speak Galilaeans?" (v.7)

            Galileans were known for their accent and considered uneducated. Suddenly they are speaking the dialects of fifteen nations fluently.

            > "And how hear we every man in our own tongue, wherein we were born?" (v.8)

            Each man hears, in his own native tongue, the wonderful works of God.

            > "Parthians, and Medes, and Elamites, and the dwellers in Mesopotamia, and in Judaea, and Cappadocia, in Pontus, and Asia," (v.9)

            > "Phrygia, and Pamphylia, in Egypt, and in the parts of Libya about Cyrene, and strangers of Rome, Jews and proselytes," (v.10)

            > "Cretes and Arabians, we do hear them speak in our tongues the wonderful works of God." (v.11)

            Fifteen regions named. The Mediterranean world is in Jerusalem this morning, and they are all hearing the gospel for the first time — in their mother tongue.

            > "And they were all amazed, and were in doubt, saying one to another, What meaneth this?" (v.12)

            Confused. Wondering. The crowd does not yet know what to make of it.

            > "Others mocking said, These men are full of new wine." (v.13)

            Some mock. "These men are full of new wine." Mockery and amazement have followed every real move of God since.

            If the Spirit is at work in your life and nobody finds it confusing or worth mocking, ask whether anything has actually changed. The flame leaves a mark. Pentecost reverses Babel — God scattered languages there to stop a project of pride; here he gives them back to gather a Church.
            """
        ),
        EventReadingDay(
            id: "pentecost-2026-day-7",
            date: parseISO("2026-05-31T00:00:00Z"),
            theme: "Peter Lifts Up His Voice",
            passage: ScriptureRef(book: "Acts", chapter: 2, startVerse: 14, endVerse: 41),
            reflection: """
            Twenty-eight verses. Peter's first sermon — and the longest single block of preaching in Acts. The same man who denied Jesus three times stands up, explains what just happened, and three thousand people are baptized before sundown. Walk through it.

            > "But Peter, standing up with the eleven, lifted up his voice, and said unto them, Ye men of Judaea, and all ye that dwell at Jerusalem, be this known unto you, and hearken to my words:" (v.14)

            He stands up with the eleven. Public, not hiding. The voice that denied is the voice that now preaches.

            > "For these are not drunken, as ye suppose, seeing it is but the third hour of the day." (v.15)

            He addresses the mockery first. "It's nine in the morning." Then he reframes.

            > "But this is that which was spoken by the prophet Joel;" (v.16)

            His next move is Scripture: this is what Joel was talking about.

            > "And it shall come to pass in the last days, saith God, I will pour out of my Spirit upon all flesh: and your sons and your daughters shall prophesy, and your young men shall see visions, and your old men shall dream dreams:" (v.17)

            Quoting Joel 2:28. The last days have begun. Pentecost is the inauguration.

            > "And on my servants and on my handmaidens I will pour out in those days of my Spirit; and they shall prophesy:" (v.18)

            All flesh — including servants, including women. Nothing is held back.

            > "And I will shew wonders in heaven above, and signs in the earth beneath; blood, and fire, and vapour of smoke:" (v.19)

            > "The sun shall be turned into darkness, and the moon into blood, before the great and notable day of the Lord come:" (v.20)

            > "And it shall come to pass, that whosoever shall call on the name of the Lord shall be saved." (v.21)

            The promise that anchors everything: whoever calls on the name of the Lord shall be saved.

            > "Ye men of Israel, hear these words; Jesus of Nazareth, a man approved of God among you by miracles and wonders and signs, which God did by him in the midst of you, as ye yourselves also know:" (v.22)

            Now to Jesus. "Approved of God" — Peter argues from what they themselves saw.

            > "Him, being delivered by the determinate counsel and foreknowledge of God, ye have taken, and by wicked hands have crucified and slain:" (v.23)

            God's plan and human responsibility, side by side. Foreknowledge does not erase guilt.

            > "Whom God hath raised up, having loosed the pains of death: because it was not possible that he should be holden of it." (v.24)

            Death could not hold him. The resurrection is the headline.

            > "For David speaketh concerning him, I foresaw the Lord always before my face, for he is on my right hand, that I should not be moved:" (v.25)

            > "Therefore did my heart rejoice, and my tongue was glad; moreover also my flesh shall rest in hope:" (v.26)

            > "Because thou wilt not leave my soul in hell, neither wilt thou suffer thine Holy One to see corruption." (v.27)

            > "Thou hast made known to me the ways of life; thou shalt make me full of joy with thy countenance." (v.28)

            Quoting Psalm 16. David spoke about resurrection — but David died and stayed dead. So who was the psalm really about?

            > "Men and brethren, let me freely speak unto you of the patriarch David, that he is both dead and buried, and his sepulchre is with us unto this day." (v.29)

            Peter's argument: David's tomb is right here. We can visit it.

            > "Therefore being a prophet, and knowing that God had sworn with an oath to him, that of the fruit of his loins, according to the flesh, he would raise up Christ to sit on his throne;" (v.30)

            But David was a prophet. He saw further than himself.

            > "He seeing this before spake of the resurrection of Christ, that his soul was not left in hell, neither his flesh did see corruption." (v.31)

            He saw Christ. The psalm is about the resurrection of Jesus.

            > "This Jesus hath God raised up, whereof we all are witnesses." (v.32)

            We are witnesses. Not arguing from theory — from experience.

            > "Therefore being by the right hand of God exalted, and having received of the Father the promise of the Holy Ghost, he hath shed forth this, which ye now see and hear." (v.33)

            Jesus is now exalted. What you see and hear today is his gift.

            > "For David is not ascended into the heavens: but he saith himself, The Lord said unto my Lord, Sit thou on my right hand," (v.34)

            Quoting Psalm 110. Even David did not ascend.

            > "Until I make thy foes thy footstool." (v.35)

            > "Therefore let all the house of Israel know assuredly, that God hath made the same Jesus, whom ye have crucified, both Lord and Christ." (v.36)

            The verdict. "All the house of Israel" — including those listening — must reckon with this: the Jesus they crucified is Lord and Christ.

            > "Now when they heard this, they were pricked in their heart, and said unto Peter and to the rest of the apostles, Men and brethren, what shall we do?" (v.37)

            Cut to the heart. The honest response of a convicted conscience.

            > "Then Peter said unto them, Repent, and be baptized every one of you in the name of Jesus Christ for the remission of sins, and ye shall receive the gift of the Holy Ghost." (v.38)

            The gospel in one verse: repent, be baptized, receive the Spirit.

            > "For the promise is unto you, and to your children, and to all that are afar off, even as many as the LORD our God shall call." (v.39)

            The promise extends — to your children, to those far off, to as many as the Lord calls.

            > "And with many other words did he testify and exhort, saying, Save yourselves from this untoward generation." (v.40)

            Many more words. Peter keeps going.

            > "Then they that gladly received his word were baptized: and the same day there were added unto them about three thousand souls." (v.41)

            Three thousand baptized that day. The Church is born.

            Pentecost is not just an experience — it is a sermon and a response. Peter preached. People were cut to the heart. They asked what to do. He told them. Three thousand obeyed. The pattern still works: speak Christ plainly, expect the Spirit to do the convicting, invite the response.
            """
        ),
        EventReadingDay(
            id: "pentecost-2026-day-8",
            date: parseISO("2026-06-01T00:00:00Z"),
            theme: "The New Community",
            passage: ScriptureRef(book: "Acts", chapter: 2, startVerse: 42, endVerse: 47),
            reflection: """
            Three thousand new converts, mostly visiting Jews from a dozen countries. What did they do next? Six verses describe the shape of the post-Pentecost Church. Not programs. Not strategies. The basics, done together.

            > "And they continued stedfastly in the apostles' doctrine and fellowship, and in breaking of bread, and in prayers." (v.42)

            Four things, every day. Apostles' doctrine, fellowship, breaking of bread, prayers. The first church syllabus.

            > "And fear came upon every soul: and many wonders and signs were done by the apostles." (v.43)

            Reverence and signs. The supernatural was normal.

            > "And all that believed were together, and had all things common;" (v.44)

            Together, with a shared life. Not just at services — in their houses.

            > "And sold their possessions and goods, and parted them to all men, as every man had need." (v.45)

            Voluntary radical generosity. The Spirit reorganized their relationship to property.

            > "And they, continuing daily with one accord in the temple, and breaking bread from house to house, did eat their meat with gladness and singleness of heart," (v.46)

            Daily, in the temple AND in homes. Public worship and private hospitality. Gladness.

            > "Praising God, and having favour with all the people. And the Lord added to the church daily such as should be saved." (v.47)

            Praising God. Favored by outsiders. The Lord adding new believers daily.

            If you have been through a powerful spiritual moment but it did not change how you live with the people in your life, the moment did not finish. Pentecost was not over when the wind stopped. It was just beginning. The same Spirit that filled the house also formed the Church. May this week land that way for you, too — not just feeling, but new community.
            """
        )
    ]
}
