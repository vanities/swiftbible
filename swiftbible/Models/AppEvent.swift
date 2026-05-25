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
        if let idx = readingPlan.firstIndex(where: { $0.isToday }) {
            return idx
        }
        if let idx = readingPlan.firstIndex(where: { !$0.hasArrived }) {
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

    // Reading-plan dates are authored as civil dates at UTC midnight
    // (2026-05-25T00:00:00Z means "May 25"). Reading that instant in the
    // device's local zone shifts it to the previous evening for anyone west
    // of UTC, which unlocked days early and labeled them a day behind. So the
    // UTC calendar day is the canonical date, gated against the user's own
    // local calendar day.
    private static let utcCalendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        if let utc = TimeZone(identifier: "UTC") { c.timeZone = utc }
        return c
    }()

    /// Local midnight on this reading's civil (UTC-authored) date.
    private var localStart: Date {
        let ymd = Self.utcCalendar.dateComponents([.year, .month, .day], from: date)
        return Calendar.current.date(from: ymd) ?? date
    }

    /// True once the user's local day has reached this reading's date.
    var hasArrived: Bool {
        Calendar.current.startOfDay(for: Date()) >= localStart
    }

    /// True when this reading's date is the user's current local day.
    var isToday: Bool {
        Calendar.current.isDate(localStart, inSameDayAs: Date())
    }

    /// Whole days from today (local) until this reading unlocks.
    var daysUntil: Int {
        Calendar.current.dateComponents([.day],
                                        from: Calendar.current.startOfDay(for: Date()),
                                        to: localStart).day ?? 0
    }

    var dateLabel: String {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: "UTC")
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
        // Card lingers ~a week past the App Store event_end (Jun 7) so the
        // finished plan stays reachable for stragglers, then drops off More.
        endDate: parseISO("2026-06-14T23:59:59Z"),
        action: .openEvent,
        bannerImageName: "PentecostEventBanner",
        readingPlan: pentecostReadingPlan
    )

    static let summerPsalms2026 = AppEvent(
        id: "summer-psalms-2026",
        name: "Summer in the Psalms",
        subtitle: "A psalm a day — through July",
        iconName: "sun.max.fill",
        accent: .accent,
        startDate: parseISO("2026-07-01T00:00:00Z"),
        // Card lingers ~a week past the App Store event_end (Jul 30).
        endDate: parseISO("2026-08-06T23:59:59Z"),
        action: .openEvent,
        bannerImageName: "SummerPsalmsEventBanner",
        readingPlan: summerPsalmsReadingPlan
    )

    /// All known events. Add new ones here.
    static let allEvents: [AppEvent] = [
        pentecost2026,
        summerPsalms2026
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

    // SUMMER-PSALMS-PLAN START (generated from appstore/events/summer-psalms/days.py — do not edit by hand)
    private static let summerPsalmsReadingPlan: [EventReadingDay] = [
        EventReadingDay(
            id: "summer-psalms-2026-day-1",
            date: parseISO("2026-07-01T00:00:00Z"),
            theme: "The Two Ways",
            passage: ScriptureRef(book: "Psalms", chapter: 1, startVerse: 1, endVerse: 6),
            reflection: "The Psalter opens with a fork in the road, not a prayer.\n\n> \"Blessed is the man that walketh not in the counsel of the ungodly, nor standeth in the way of sinners, nor sitteth in the seat of the scornful.\" (1:1)\n\nWatch the verbs — walk, stand, sit. Nobody sits down in the scorner's seat on day one; you drift there a degree at a time.\n\n> \"And he shall be like a tree planted by the rivers of water, that bringeth forth his fruit in his season; his leaf also shall not wither; and whatsoever he doeth shall prosper.\" (1:3)\n\nThe blessed life isn't gritted willpower. It's being planted by water — rooted, fed, fruitful in its season.\n\n> \"For the LORD knoweth the way of the righteous: but the way of the ungodly shall perish.\" (1:6)\n\nTwo ways, two endings. One path the LORD knows; the other blows off like chaff.\n\nThirty days in the Psalms is thirty days of sinking roots. Start here."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-2",
            date: parseISO("2026-07-02T00:00:00Z"),
            theme: "The Shepherd",
            passage: ScriptureRef(book: "Psalms", chapter: 23, startVerse: 1, endVerse: 6),
            reflection: "Six verses you think you already know. Read them slow anyway.\n\n> \"The LORD is my shepherd; I shall not want.\" (23:1)\n\nIf the LORD is the shepherd, \"shall not want\" follows. The restless wanting quiets when he's the one leading.\n\n> \"Yea, though I walk through the valley of the shadow of death, I will fear no evil: for thou art with me; thy rod and thy staff they comfort me.\" (23:4)\n\nHe never promises a way around the valley — only company through it. The rod and staff don't pave the road; they walk it with you.\n\n> \"Surely goodness and mercy shall follow me all the days of my life: and I will dwell in the house of the LORD for ever.\" (23:6)\n\nGoodness and mercy don't just meet you. They follow you, all the way home.\n\nThe promise was never an easy way. It was Someone on the way with you."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-3",
            date: parseISO("2026-07-03T00:00:00Z"),
            theme: "I Lift My Eyes",
            passage: ScriptureRef(book: "Psalms", chapter: 121, startVerse: 1, endVerse: 8),
            reflection: "A pilgrim song, sung on the climb up to Jerusalem — eyeing the hills where the road turned dangerous.\n\n> \"I will lift up mine eyes unto the hills, from whence cometh my help.\" (121:1)\n\nEyes go up to the hills, where bandits hid and help felt far off.\n\n> \"Behold, he that keepeth Israel shall neither slumber nor sleep.\" (121:4)\n\nThe God who built those hills doesn't doze off halfway up yours.\n\n> \"The LORD shall preserve thy going out and thy coming in from this time forth, and even for evermore.\" (121:8)\n\nYour going out and your coming in — the whole trip, both directions, kept.\n\nWhatever you're climbing toward this summer, you are kept. Keep climbing."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-4",
            date: parseISO("2026-07-04T00:00:00Z"),
            theme: "The Shelter",
            passage: ScriptureRef(book: "Psalms", chapter: 91, startVerse: 1, endVerse: 16),
            reflection: "Dwell, not visit. This psalm is for the one who lives in God, not the one who drops by when the weather turns.\n\n> \"He that dwelleth in the secret place of the most High shall abide under the shadow of the Almighty.\" (91:1)\n\nThe secret place isn't a hideout you find in a panic. It's an address you already live at.\n\n> \"He shall cover thee with his feathers, and under his wings shalt thou trust: his truth shall be thy shield and buckler.\" (91:4)\n\nHe doesn't promise no arrows — he promises cover in the middle of them. A wing isn't armor; it's nearness.\n\n> \"For he shall give his angels charge over thee, to keep thee in all thy ways.\" (91:11)\n\nAngels under orders, charged to keep you. You are not walking unguarded.\n\nDwelling is a daily address, not an emergency exit. Move in."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-5",
            date: parseISO("2026-07-05T00:00:00Z"),
            theme: "Light and Salvation",
            passage: ScriptureRef(book: "Psalms", chapter: 27, startVerse: 1, endVerse: 14),
            reflection: "Fear asks \"what if.\" David asks back: whom?\n\n> \"The LORD is my light and my salvation; whom shall I fear? the LORD is the strength of my life; of whom shall I be afraid?\" (27:1)\n\nIf the LORD is your light, the dark loses its vote. If he's your salvation, the threat loses its teeth.\n\n> \"One thing have I desired of the LORD, that will I seek after; that I may dwell in the house of the LORD all the days of my life, to behold the beauty of the LORD, and to enquire in his temple.\" (27:4)\n\nOut of everything he could ask, he asks one thing — to be where God is, and to look at him.\n\n> \"Wait on the LORD: be of good courage, and he shall strengthen thine heart: wait, I say, on the LORD.\" (27:14)\n\nThe hardest command in the psalm: wait. And when you're done waiting, wait again.\n\nCourage here isn't the absence of enemies. It's knowing whose house you're headed to."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-6",
            date: parseISO("2026-07-06T00:00:00Z"),
            theme: "Be Still",
            passage: ScriptureRef(book: "Psalms", chapter: 46, startVerse: 1, endVerse: 11),
            reflection: "Not a distant help — a present one, already in the room before the trouble started.\n\n> \"God is our refuge and strength, a very present help in trouble.\" (46:1)\n\nRefuge and strength: a place to hide and the power to stand. He is both.\n\n> \"Therefore will not we fear, though the earth be removed, and though the mountains be carried into the midst of the sea;\" (46:2)\n\nLet the worst happen — earth gone, mountains in the sea — and the psalm still won't panic.\n\n> \"Be still, and know that I am God: I will be exalted among the heathen, I will be exalted in the earth.\" (46:10)\n\n\"Be still\" isn't a mood; it's a command. Stop scrambling long enough to remember who outranks the storm.\n\nStillness isn't the absence of the storm. It's knowing God is God in the middle of it."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-7",
            date: parseISO("2026-07-07T00:00:00Z"),
            theme: "Wait in Silence",
            passage: ScriptureRef(book: "Psalms", chapter: 62, startVerse: 1, endVerse: 12),
            reflection: "Twice David says it: God only. Not God-plus-a-backup-plan.\n\n> \"Truly my soul waiteth upon God: from him cometh my salvation.\" (62:1)\n\nThe soul that waits in silence isn't passive. It's done auditioning other saviors.\n\n> \"My soul, wait thou only upon God; for my expectation is from him.\" (62:5)\n\nHe has to tell his own soul to wait — because the soul keeps drifting back to lesser hopes.\n\n> \"Trust in him at all times; ye people, pour out your heart before him: God is a refuge for us. Selah.\" (62:8)\n\nPour it all out, every hour, in front of him. He can take the whole weight; he is the refuge.\n\nWait in silence. And mean the \"only.\""
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-8",
            date: parseISO("2026-07-08T00:00:00Z"),
            theme: "You Will Not Abandon",
            passage: ScriptureRef(book: "Psalms", chapter: 16, startVerse: 1, endVerse: 11),
            reflection: "A simple discipline runs under this whole psalm: keep the LORD in front of you.\n\n> \"I have set the LORD always before me: because he is at my right hand, I shall not be moved.\" (16:8)\n\nNot behind, for emergencies — in front, always. Set there on purpose, you will not be moved.\n\n> \"For thou wilt not leave my soul in hell; neither wilt thou suffer thine Holy One to see corruption.\" (16:10)\n\nDavid's hope outruns the grave. Peter preached this very line over the empty tomb.\n\n> \"Thou wilt shew me the path of life: in thy presence is fulness of joy; at thy right hand there are pleasures for evermore.\" (16:11)\n\nThe path of life leads somewhere specific: his presence, where joy is full and the pleasures don't run out.\n\nSet him before you, and start the day there."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-9",
            date: parseISO("2026-07-09T00:00:00Z"),
            theme: "How Majestic",
            passage: ScriptureRef(book: "Psalms", chapter: 8, startVerse: 1, endVerse: 9),
            reflection: "Stand under a real night sky and this psalm writes itself.\n\n> \"O LORD, our Lord, how excellent is thy name in all the earth! who hast set thy glory above the heavens.\" (8:1)\n\nHis name fills the earth and the heavens at once — bigness you can't get under or around.\n\n> \"What is man, that thou art mindful of him? and the son of man, that thou visitest him?\" (8:4)\n\nAll of that, and he bothers with us. The wonder isn't that we're small; it's that he's mindful.\n\n> \"For thou hast made him a little lower than the angels, and hast crowned him with glory and honour.\" (8:5)\n\nNot crushed by the cosmos but crowned. Hebrews reads this as the Son of Man who took the low place to lift ours.\n\nLook up tonight. Let it be worship."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-10",
            date: parseISO("2026-07-10T00:00:00Z"),
            theme: "The Heavens Declare",
            passage: ScriptureRef(book: "Psalms", chapter: 19, startVerse: 1, endVerse: 14),
            reflection: "Two sermons in one psalm, and neither needs translating.\n\n> \"The heavens declare the glory of God; and the firmament sheweth his handywork.\" (19:1)\n\nThe sky preaches without a word — and there's no language where its voice isn't heard.\n\n> \"The law of the LORD is perfect, converting the soul: the testimony of the LORD is sure, making wise the simple.\" (19:7)\n\nThen the second sermon: the law of the LORD, perfect, actually able to convert a soul.\n\n> \"Let the words of my mouth, and the meditation of my heart, be acceptable in thy sight, O LORD, my strength, and my redeemer.\" (19:14)\n\nSo the prayer turns inward — let even my words and my thoughts be acceptable to him.\n\nCreation tells you there's a God. The Word tells you his name. Let the last verse be your prayer."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-11",
            date: parseISO("2026-07-11T00:00:00Z"),
            theme: "Bless the LORD (Creation)",
            passage: ScriptureRef(book: "Psalms", chapter: 104, startVerse: 1, endVerse: 35),
            reflection: "A tour of creation with the Maker named on every page.\n\n> \"Bless the LORD, O my soul. O LORD my God, thou art very great; thou art clothed with honour and majesty.\" (104:1)\n\nHe wears light like a robe. Majesty isn't decoration on God; it's what he's clothed in.\n\n> \"O LORD, how manifold are thy works! in wisdom hast thou made them all: the earth is full of thy riches.\" (104:24)\n\nLook closely and the count overwhelms you — every wild and ordinary thing made in wisdom.\n\n> \"I will sing unto the LORD as long as I live: I will sing praise to my God while I have my being.\" (104:33)\n\nNothing here runs itself; it's all held. The only fitting response is to sing while you've got breath.\n\nWorship isn't analysis. It's the song creation has been singing all along."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-12",
            date: parseISO("2026-07-12T00:00:00Z"),
            theme: "Bless the LORD, O My Soul",
            passage: ScriptureRef(book: "Psalms", chapter: 103, startVerse: 1, endVerse: 22),
            reflection: "David preaches to himself here. Sometimes the soul needs telling, not asking.\n\n> \"Bless the LORD, O my soul, and forget not all his benefits:\" (103:2)\n\n\"Forget not\" — because we do. The benefits stack up and we stop counting them.\n\n> \"As far as the east is from the west, so far hath he removed our transgressions from us.\" (103:12)\n\nEast and west never meet; the distance has no middle. That's how far he's carried your sin.\n\n> \"For he knoweth our frame; he remembereth that we are dust.\" (103:14)\n\nHe isn't surprised by your weakness. He remembers the dust you're made of, and loves you anyway.\n\nForget not all his benefits. Bless the LORD, O my soul."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-13",
            date: parseISO("2026-07-13T00:00:00Z"),
            theme: "Make a Joyful Noise",
            passage: ScriptureRef(book: "Psalms", chapter: 100, startVerse: 1, endVerse: 5),
            reflection: "Five verses, almost all command. Praise isn't a feeling you wait for; it's a thing you do until the feeling catches up.\n\n> \"Make a joyful noise unto the LORD, all ye lands.\" (100:1)\n\nA joyful noise — not necessarily a tuneful one. He's after gladness, not performance.\n\n> \"Know ye that the LORD he is God: it is he that hath made us, and not we ourselves; we are his people, and the sheep of his pasture.\" (100:3)\n\nKnow it: he made us, not the other way around. We're the sheep, not the shepherd.\n\n> \"For the LORD is good; his mercy is everlasting; and his truth endureth to all generations.\" (100:5)\n\nAnd the ground under all the noise — his goodness, his mercy, his truth, with no expiration date.\n\nEnter his gates with thanksgiving. Make some noise."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-14",
            date: parseISO("2026-07-14T00:00:00Z"),
            theme: "I Will Extol Thee",
            passage: ScriptureRef(book: "Psalms", chapter: 145, startVerse: 1, endVerse: 21),
            reflection: "David walks the alphabet to praise God — like he's using every letter he has and still coming up short.\n\n> \"Every day will I bless thee; and I will praise thy name for ever and ever.\" (145:2)\n\nEvery day, not the good ones only. Praise as a daily habit, not a mood that visits.\n\n> \"The LORD is gracious, and full of compassion; slow to anger, and of great mercy.\" (145:8)\n\nHere's the God he's praising: gracious, full of compassion, slow to anger, great in mercy.\n\n> \"The LORD is nigh unto all them that call upon him, to all that call upon him in truth.\" (145:18)\n\nAnd near — near to everyone who calls. Not far off for the worthy; near for the asking.\n\nGreat is the LORD, and greatly to be praised. Every day. Start with this one."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-15",
            date: parseISO("2026-07-15T00:00:00Z"),
            theme: "Sing a New Song",
            passage: ScriptureRef(book: "Psalms", chapter: 96, startVerse: 1, endVerse: 13),
            reflection: "A new song, because the mercies aren't yesterday's. Old gratitude goes stale.\n\n> \"O sing unto the LORD a new song: sing unto the LORD, all the earth.\" (96:1)\n\nSing something new — and not just you. \"All the earth\" is invited into the chorus.\n\n> \"Declare his glory among the heathen, his wonders among all people.\" (96:3)\n\nPraise that's real wants witnesses; it declares his glory instead of keeping it private.\n\n> \"O worship the LORD in the beauty of holiness: fear before him, all the earth.\" (96:9)\n\nWorship him in the beauty of holiness. Awe, not just enthusiasm.\n\nFind a fresh song today. Then sing it where someone can hear."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-16",
            date: parseISO("2026-07-16T00:00:00Z"),
            theme: "How Long?",
            passage: ScriptureRef(book: "Psalms", chapter: 13, startVerse: 1, endVerse: 6),
            reflection: "Four \"how longs\" in two verses. The Bible lets you talk to God like this.\n\n> \"How long wilt thou forget me, O LORD? for ever? how long wilt thou hide thy face from me?\" (13:1)\n\nHonesty isn't the opposite of faith — it's faith refusing to leave the room.\n\n> \"But I have trusted in thy mercy; my heart shall rejoice in thy salvation.\" (13:5)\n\nThen the hinge the whole psalm turns on: but. He trusted in mercy before the feelings changed.\n\n> \"I will sing unto the LORD, because he hath dealt bountifully with me.\" (13:6)\n\nFrom \"how long\" to \"I will sing\" in six verses. The complaint didn't get the last word.\n\nLament is allowed. So is the turn. Don't stop before verse 5."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-17",
            date: parseISO("2026-07-17T00:00:00Z"),
            theme: "As the Hart Panteth",
            passage: ScriptureRef(book: "Psalms", chapter: 42, startVerse: 1, endVerse: 11),
            reflection: "A thirst, not a preference. The deer isn't browsing; it's desperate.\n\n> \"As the hart panteth after the water brooks, so panteth my soul after thee, O God.\" (42:1)\n\nSome seasons that's exactly how God feels — necessary and absent at once.\n\n> \"My tears have been my meat day and night, while they continually say unto me, Where is thy God?\" (42:3)\n\nTears for food, day and night, while people ask where your God is. The psalm doesn't pretend otherwise.\n\n> \"Why art thou cast down, O my soul? and why art thou disquieted in me? hope thou in God: for I shall yet praise him for the help of his countenance.\" (42:5)\n\nSo he turns and talks to himself — names the despair, then preaches hope back at it.\n\nPreach to the soul that won't sing yet. Tell it where to put its hope."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-18",
            date: parseISO("2026-07-18T00:00:00Z"),
            theme: "My Soul Thirsteth",
            passage: ScriptureRef(book: "Psalms", chapter: 63, startVerse: 1, endVerse: 11),
            reflection: "David wrote this in a wilderness — \"a dry and thirsty land, where no water is.\"\n\n> \"O God, thou art my God; early will I seek thee: my soul thirsteth for thee, my flesh longeth for thee in a dry and thirsty land, where no water is;\" (63:1)\n\nThe driest place became the clearest prayer. He seeks God early, before anything else gets in.\n\n> \"Because thy lovingkindness is better than life, my lips shall praise thee.\" (63:3)\n\nHe doesn't ask to leave the desert. He says what the desert taught him: God's love beats life itself.\n\n> \"Because thou hast been my help, therefore in the shadow of thy wings will I rejoice.\" (63:7)\n\nEven there, in the dark, he finds the shadow of God's wings — and sings.\n\nThirst isn't your enemy. It's the thing pointing you home. Seek him early."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-19",
            date: parseISO("2026-07-19T00:00:00Z"),
            theme: "Have Mercy",
            passage: ScriptureRef(book: "Psalms", chapter: 51, startVerse: 1, endVerse: 19),
            reflection: "David after Bathsheba. No spin, no blaming the circumstances.\n\n> \"Have mercy upon me, O God, according to thy lovingkindness: according unto the multitude of thy tender mercies blot out my transgressions.\" (51:1)\n\nHe throws himself entirely on mercy — according to God's lovingkindness, not his own record.\n\n> \"Create in me a clean heart, O God; and renew a right spirit within me.\" (51:10)\n\nHe doesn't ask for a touch-up. He asks to be remade. Create — only God does that verb.\n\n> \"The sacrifices of God are a broken spirit: a broken and a contrite heart, O God, thou wilt not despise.\" (51:17)\n\nAnd here's what God won't turn away: not performance, but a broken and a contrite heart.\n\nReal repentance stops managing the story and tells the truth. Bring him the broken heart."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-20",
            date: parseISO("2026-07-20T00:00:00Z"),
            theme: "Out of the Depths",
            passage: ScriptureRef(book: "Psalms", chapter: 130, startVerse: 1, endVerse: 8),
            reflection: "The depths — not the shallows. This prayer comes from the bottom, and still expects to be heard.\n\n> \"Out of the depths have I cried unto thee, O LORD.\" (130:1)\n\nHe doesn't clean himself up before crying out. He cries out from where he actually is.\n\n> \"But there is forgiveness with thee, that thou mayest be feared.\" (130:4)\n\nWhy expect mercy? Because there is forgiveness with him. If he marked every sin, who could stand?\n\n> \"Let Israel hope in the LORD: for with the LORD there is mercy, and with him is plenteous redemption.\" (130:7)\n\nSo he waits like a watchman waits for morning — and morning, with him, is plenteous redemption.\n\nOut of the depths is a fine place to start praying. He's listening there too."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-21",
            date: parseISO("2026-07-21T00:00:00Z"),
            theme: "Blessed Is Forgiven",
            passage: ScriptureRef(book: "Psalms", chapter: 32, startVerse: 1, endVerse: 11),
            reflection: "Two days ago was the confession. This is the morning after — the plain relief of a clean conscience.\n\n> \"Blessed is he whose transgression is forgiven, whose sin is covered.\" (32:1)\n\nNot erased from history; covered by God, and counted gone. That's the blessing.\n\n> \"When I kept silence, my bones waxed old through my roaring all the day long.\" (32:3)\n\nDavid remembers the cost of hiding: silence aged his bones. Buried sin doesn't go quiet; it goes inward.\n\n> \"I acknowledge my sin unto thee, and mine iniquity have I not hid. I said, I will confess my transgressions unto the LORD; and thou forgavest the iniquity of my sin. Selah.\" (32:5)\n\nThen he came clean — and forgiveness was already waiting on the other side of honesty.\n\nDon't be dragged like a stubborn horse. Come freely. Be glad."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-22",
            date: parseISO("2026-07-22T00:00:00Z"),
            theme: "My God, Why?",
            passage: ScriptureRef(book: "Psalms", chapter: 22, startVerse: 1, endVerse: 31),
            reflection: "Jesus said the first line of this psalm from the cross. He reached for the loudest complaint in the Psalter.\n\n> \"My God, my God, why hast thou forsaken me? why art thou so far from helping me, and from the words of my roaring?\" (22:1)\n\nForsaken — and he prayed it out loud. Even that cry was addressed to \"my God.\"\n\n> \"For dogs have compassed me: the assembly of the wicked have inclosed me: they pierced my hands and my feet.\" (22:16)\n\nThen it turns eerie: pierced hands and feet, written a thousand years before a Roman nail.\n\n> \"I will declare thy name unto my brethren: in the midst of the congregation will I praise thee.\" (22:22)\n\nAnd it turns again — from forsaken to declaring God's name among his brethren. The song doesn't end at the cross.\n\nThe most abandoned-sounding psalm is the most exactly fulfilled. Read it to the end."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-23",
            date: parseISO("2026-07-23T00:00:00Z"),
            theme: "He Brought Me Up",
            passage: ScriptureRef(book: "Psalms", chapter: 40, startVerse: 1, endVerse: 17),
            reflection: "First, the waiting. \"Patiently\" — the rescue was real, and it wasn't instant.\n\n> \"I waited patiently for the LORD; and he inclined unto me, and heard my cry.\" (40:1)\n\nHe waited, and he was heard. Both halves are true; one just takes longer.\n\n> \"He brought me up also out of an horrible pit, out of the miry clay, and set my feet upon a rock, and established my goings.\" (40:2)\n\nUp out of the pit and the miry clay, feet set on a rock. Stable ground after a long sink.\n\n> \"And he hath put a new song in my mouth, even praise unto our God: many shall see it, and fear, and shall trust in the LORD.\" (40:3)\n\nAnd a new song in his mouth — deliverance hands you something to sing you didn't have before.\n\nWait. Then, when he's set your feet down, don't keep the song to yourself."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-24",
            date: parseISO("2026-07-24T00:00:00Z"),
            theme: "Mourning into Dancing",
            passage: ScriptureRef(book: "Psalms", chapter: 30, startVerse: 1, endVerse: 12),
            reflection: "David had been low. He isn't theorizing about pain; he'd been in it.\n\n> \"O LORD, thou hast brought up my soul from the grave: thou hast kept me alive, that I should not go down to the pit.\" (30:3)\n\nBrought up from the grave itself. He's writing as someone who got a morning he didn't expect.\n\n> \"For his anger endureth but a moment; in his favour is life: weeping may endure for a night, but joy cometh in the morning.\" (30:5)\n\nWeeping may last a night — but a night, not forever. His anger is a moment; his favour is a lifetime.\n\n> \"Thou hast turned for me my mourning into dancing: thou hast put off my sackcloth, and girded me with gladness;\" (30:11)\n\nMourning turned to dancing. He doesn't explain the turn so much as testify to it.\n\nNight is real, and it has an end. Hold on till morning."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-25",
            date: parseISO("2026-07-25T00:00:00Z"),
            theme: "Taste and See",
            passage: ScriptureRef(book: "Psalms", chapter: 34, startVerse: 1, endVerse: 22),
            reflection: "Taste — not read about, not hear secondhand. Some things about God you only learn by trying him.\n\n> \"I sought the LORD, and he heard me, and delivered me from all my fears.\" (34:4)\n\nDavid's testimony is specific: he sought, God heard, the fears went. Not theory — experience.\n\n> \"O taste and see that the LORD is good: blessed is the man that trusteth in him.\" (34:8)\n\nSo he hands you the dare: taste and see. Find out for yourself that he's good.\n\n> \"The LORD is nigh unto them that are of a broken heart; and saveth such as be of a contrite spirit.\" (34:18)\n\nAnd for the days that don't feel good — he's near the broken-hearted, close to the crushed.\n\nHe's near the crushed, not the impressive. Taste and see."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-26",
            date: parseISO("2026-07-26T00:00:00Z"),
            theme: "How Amiable",
            passage: ScriptureRef(book: "Psalms", chapter: 84, startVerse: 1, endVerse: 12),
            reflection: "Homesick for the house of God. The psalmist even envies the sparrow that gets to nest by the altar.\n\n> \"How amiable are thy tabernacles, O LORD of hosts!\" (84:1)\n\nHow lovely, how worth-longing-for, are the places where God meets his people.\n\n> \"My soul longeth, yea, even fainteth for the courts of the LORD: my heart and my flesh crieth out for the living God.\" (84:2)\n\nNot polite interest. His soul faints with longing for the courts of the LORD.\n\n> \"For a day in thy courts is better than a thousand. I had rather be a doorkeeper in the house of my God, than to dwell in the tents of wickedness.\" (84:10)\n\nA single day there beats a thousand anywhere else. He'd rather hold the door than live easy elsewhere.\n\nAnd the road counts too — passing through the dry valley, they make it a place of springs."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-27",
            date: parseISO("2026-07-27T00:00:00Z"),
            theme: "Searched and Known",
            passage: ScriptureRef(book: "Psalms", chapter: 139, startVerse: 1, endVerse: 24),
            reflection: "Fully known — which is more terrifying and more comforting than being half-known and liked.\n\n> \"O lord, thou hast searched me, and known me.\" (139:1)\n\nHe knows your sitting down and your rising up, your words before you say them. All of it.\n\n> \"Whither shall I go from thy spirit? or whither shall I flee from thy presence?\" (139:7)\n\nAnd there's nowhere his presence isn't — not heaven, not the grave, not the far side of the sea.\n\n> \"Search me, O God, and know my heart: try me, and know my thoughts:\" (139:23)\n\nSo the brave prayer: ask the One who already sees to show you what he sees.\n\nYou are completely known and not turned away. Let him search you."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-28",
            date: parseISO("2026-07-28T00:00:00Z"),
            theme: "Number Our Days",
            passage: ScriptureRef(book: "Psalms", chapter: 90, startVerse: 1, endVerse: 17),
            reflection: "Moses wrote this one. He isn't being morbid about our short years — he's being accurate.\n\n> \"Lord, thou hast been our dwelling place in all generations.\" (90:1)\n\nGenerations come and go; God has been the dwelling place through every one of them.\n\n> \"So teach us to number our days, that we may apply our hearts unto wisdom.\" (90:12)\n\nThe prayer isn't for more days. It's to count the ones we have, and spend them on what lasts.\n\n> \"And let the beauty of the LORD our God be upon us: and establish thou the work of our hands upon us; yea, the work of our hands establish thou it.\" (90:17)\n\nAnd then the ask that redeems a short life: establish the work of our hands. Make it count.\n\nA brief life, made to matter by an eternal God. Number your days."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-29",
            date: parseISO("2026-07-29T00:00:00Z"),
            theme: "I Love the LORD",
            passage: ScriptureRef(book: "Psalms", chapter: 116, startVerse: 1, endVerse: 19),
            reflection: "Love with a reason attached. He prayed in real trouble, and God heard — so now he loves.\n\n> \"I love the LORD, because he hath heard my voice and my supplications.\" (116:1)\n\nNot abstract devotion. He loves the LORD because the LORD bent down and listened.\n\n> \"What shall I render unto the LORD for all his benefits toward me?\" (116:12)\n\nThe honest question of the rescued: what do you give back for grace like that?\n\n> \"Precious in the sight of the LORD is the death of his saints.\" (116:15)\n\nAnd a line for the grieving: the death of his saints isn't cheap to him. It's precious in his sight.\n\nYou can't repay grace. You can receive it and say so. He has heard you too."
        ),
        EventReadingDay(
            id: "summer-psalms-2026-day-30",
            date: parseISO("2026-07-30T00:00:00Z"),
            theme: "Let Everything Praise",
            passage: ScriptureRef(book: "Psalms", chapter: 150, startVerse: 1, endVerse: 6),
            reflection: "The Psalter ends with no request left. After all the lament and waiting, it lands on pure praise.\n\n> \"Praise ye the LORD. Praise God in his sanctuary: praise him in the firmament of his power.\" (150:1)\n\nPraise him where he is — in his sanctuary, in the heights. Start with the place he's promised to be.\n\n> \"Praise him for his mighty acts: praise him according to his excellent greatness.\" (150:2)\n\nPraise him for what he's done — his mighty acts — and for who he is — his excellent greatness.\n\n> \"Let every thing that hath breath praise the LORD. Praise ye the LORD.\" (150:6)\n\nAnd the last instrument is you. If you have breath, you're in the orchestra.\n\nThirty days, from \"blessed is the man\" to \"praise ye the LORD.\" Take a breath. Use it."
        )
    ]
    // SUMMER-PSALMS-PLAN END

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
