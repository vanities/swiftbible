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
            The first chapter of Acts opens with Jesus eating with his disciples for forty days after the resurrection. He has time. He could explain anything. Instead, he keeps coming back to one promise: wait.

            > [J] "Ye shall be baptized with the Holy Ghost not many days hence." (v.5)

            That's the whole charter. Don't go yet. Don't try yet. Wait.

            Then, mid-sentence, he leaves. Carried up. A cloud receives him. Two angels show up to pry the disciples' eyes back to earth: "Why stand ye gazing up into heaven?"

            Pentecost begins here, in the gap. A promise has been made. The deliverer has gone. What's next isn't visible. The disciples are left holding nothing but a word from Jesus and forty days of meals together.

            If you've ever had to wait for something you couldn't make happen — a healing, a relationship to mend, your own faith to deepen — you know this gap. The temptation is to fill it with your own effort, your own cleverness. Pentecost says: don't. The Spirit is coming. Make it ten days. Make it a year. Make it whatever it takes. Wait together.
            """
        ),
        EventReadingDay(
            id: "pentecost-2026-day-2",
            date: parseISO("2026-05-26T00:00:00Z"),
            theme: "Waiting Together",
            passage: ScriptureRef(book: "Acts", chapter: 1, startVerse: 12, endVerse: 26),
            reflection: """
            After the ascension, the disciples don't disperse. They go back to the upper room — the same room where they shared the Last Supper, the same room where they hid after the crucifixion. A hundred and twenty people, including Mary and Jesus's brothers (the same brothers who, just weeks earlier, didn't believe him). They pray.

            Peter does one piece of business: choosing a replacement for Judas. He quotes Psalms. He defines the requirement. They cast lots. Matthias is chosen. And then — nothing. They go back to praying.

            This is the part nobody photographs. There are no signs yet. No flames. No crowds. Just a hundred and twenty people, sitting in a room, asking for something they can't manufacture.

            It's tempting to skip past the ten days of waiting. The drama is on Pentecost morning. But what happened in that room shaped what came after. They weren't waiting alone. They weren't waiting passively. They were waiting together, in prayer, in ordinary obedience, doing the next small thing they could do.

            When God seems quiet, that's often the work — to gather, to ask, to keep showing up. The Spirit isn't held hostage by your cleverness. He honors faithful waiting.
            """
        ),
        EventReadingDay(
            id: "pentecost-2026-day-3",
            date: parseISO("2026-05-27T00:00:00Z"),
            theme: "Another Comforter",
            passage: ScriptureRef(book: "John", chapter: 14, startVerse: 15, endVerse: 31),
            reflection: """
            This isn't from Acts. Jesus said this on the night before he died. The disciples are confused, grieving in advance, and Jesus is trying to prepare them.

            > [J] "I will pray the Father, and he shall give you another Comforter, that he may abide with you for ever." (v.16)

            The word in Greek is paraklētos — literally, one called alongside. A helper, a counselor, an advocate. The word "another" matters: the same kind of helper Jesus has been, just not in a body. The Spirit is not a downgrade. The Spirit is what makes Jesus's promise possible — that he won't leave them as orphans.

            Read this passage and notice how often Jesus connects love and obedience. "If ye love me, keep my commandments." (v.15) "He that hath my commandments, and keepeth them, he it is that loveth me." (v.21) The Spirit isn't an emotional add-on. He comes alongside the people who actually try to live like Jesus said.

            Pentecost is not about a feeling. It's about being equipped to do what Jesus already commanded.
            """
        ),
        EventReadingDay(
            id: "pentecost-2026-day-4",
            date: parseISO("2026-05-28T00:00:00Z"),
            theme: "Into All Truth",
            passage: ScriptureRef(book: "John", chapter: 16, startVerse: 5, endVerse: 15),
            reflection: """
            Two days from Pentecost. This passage describes what the Spirit does after he comes. It's specific.

            > [J] "He will reprove the world of sin, and of righteousness, and of judgment." (v.8)
            > [J] "He will guide you into all truth." (v.13)
            > [J] "He shall glorify me." (v.14)

            Three things: convict, guide, glorify. Notice what's not on the list — the Spirit isn't here to make you feel good, give you opinions about politics, or confirm what you already think. The Spirit's work is harder than that and better than that.

            Convict. He shows you sin you didn't see. He shows you righteousness you didn't reach.

            Guide. He brings you into truth — not your truth, all truth. He doesn't speak from himself; he reports what he hears.

            Glorify. Everything he does points to Jesus. If you find a "spirituality" that doesn't lead you back to Christ, it isn't the Holy Spirit.

            If your prayers feel different lately — if there's an uncomfortable awareness of something you've avoided — that may be the Spirit doing his work. Don't run from it. He's preparing you.
            """
        ),
        EventReadingDay(
            id: "pentecost-2026-day-5",
            date: parseISO("2026-05-29T00:00:00Z"),
            theme: "Poured Out on All Flesh",
            passage: ScriptureRef(book: "Joel", chapter: 2, startVerse: 28, endVerse: 32),
            reflection: """
            Eight hundred years before Pentecost, the prophet Joel saw it.

            > "And it shall come to pass afterward, that I will pour out my spirit upon all flesh." (v.28)

            Read the verse slowly. All flesh. Not the priests. Not the prophets. Not the leaders. All flesh — sons, daughters, old men, young men, even servants. Both genders. Every age. Every class.

            This was radical. In the Old Testament, the Spirit came on specific people for specific tasks — Moses, the judges, certain prophets. Most Israelites would never expect to be filled. Joel said: that's about to change.

            Peter quotes this passage on Pentecost morning to explain what just happened (Acts 2:16-21). The Spirit being poured out on all flesh isn't an accident or a one-day event. It's the new normal. It's what God said he would do, and on Pentecost he did it.

            If you've ever felt unqualified to be used by God — too young, too old, too uneducated, too late — this passage is your answer. The Spirit didn't come on a few. He came on all who would call.
            """
        ),
        EventReadingDay(
            id: "pentecost-2026-day-6",
            date: parseISO("2026-05-30T00:00:00Z"),
            theme: "Tongues Like as of Fire",
            passage: ScriptureRef(book: "Acts", chapter: 2, startVerse: 1, endVerse: 13),
            reflection: """
            Pentecost morning. The day was fully come. They were all together in one place. And then, suddenly:

            > "And there came a sound from heaven as of a rushing mighty wind, and it filled all the house where they were sitting. And there appeared unto them cloven tongues like as of fire, and it sat upon each of them, and they were all filled with the Holy Ghost." (vv.2-4)

            Three things you can almost see: sound (wind), sight (fire), speech (other tongues). Every sense. Then they spilled out into the city, speaking in languages they had never learned, and the Jews who had come from every nation heard each one in their own native tongue.

            Some mocked. "These men are full of new wine."

            Some were amazed. "We do hear them speak in our tongues the wonderful works of God."

            That tension — mockery and amazement — has followed every real move of God since. If the Spirit is at work in your life and nobody finds it confusing or worth mocking, ask whether anything has actually changed. The flame leaves a mark.
            """
        ),
        EventReadingDay(
            id: "pentecost-2026-day-7",
            date: parseISO("2026-05-31T00:00:00Z"),
            theme: "Peter Lifts Up His Voice",
            passage: ScriptureRef(book: "Acts", chapter: 2, startVerse: 14, endVerse: 41),
            reflection: """
            The same Peter who denied Jesus three times stands up and preaches. He's not eloquent — he's a fisherman. But he's filled with the Spirit, and the words come.

            He quotes Joel. He quotes David. He preaches Jesus crucified and risen. He doesn't soften it: "Whom ye have crucified." (v.36)

            The crowd is cut to the heart. "What shall we do?"

            Peter's answer is the same one we still preach: > "Repent, and be baptized every one of you in the name of Jesus Christ for the remission of sins, and ye shall receive the gift of the Holy Ghost." (v.38)

            That day, three thousand were added.

            This is what the Spirit does. He takes ordinary people — even the ones who failed badly — and gives them a voice. Peter didn't wait until he felt confident. He didn't wait until he had a seminary degree. He stood up and preached what he knew. The Spirit did the rest.

            If God has put something on your heart to say, the question isn't whether you're ready. It's whether you're willing.
            """
        ),
        EventReadingDay(
            id: "pentecost-2026-day-8",
            date: parseISO("2026-06-01T00:00:00Z"),
            theme: "The New Community",
            passage: ScriptureRef(book: "Acts", chapter: 2, startVerse: 42, endVerse: 47),
            reflection: """
            Three thousand new converts, mostly visiting Jews from a dozen countries. What did they do next?

            > "And they continued steadfastly in the apostles' doctrine and fellowship, and in breaking of bread, and in prayers." (v.42)

            Four things, every day: teaching, fellowship, the Lord's Supper, prayer. Not programs. Not strategies. The basics, done together.

            They sold what they had so no one was in need. They worshipped in the temple AND broke bread house to house. They ate with gladness and singleness of heart. The Lord added to the church daily such as should be saved.

            This is the fruit of Pentecost. Not just a moment of fire — a community shaped by the Spirit into a new way of being together. Generous. Joyful. Steady.

            If you've been through a powerful spiritual moment but it didn't change how you live with the people in your life, the moment didn't finish. Pentecost wasn't over when the wind stopped. It was just beginning. The same Spirit that filled the house also formed the church.

            May this week land that way for you, too — not just feeling, but new community.
            """
        )
    ]
}
