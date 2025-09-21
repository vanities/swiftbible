//
//  VerseExplanationRequest.swift
//  swiftbible
//
//  Created by OpenAI.
//

import Foundation

struct VerseExplanationRequest: Identifiable, Equatable {
    let id = UUID()
    let bookName: String
    let chapter: Int
    let startingVerse: Int
    let translation: String
    let paragraphText: String

    var reference: String {
        "\(bookName) \(chapter):\(startingVerse)"
    }

    var cleanedVerseText: String {
        let withoutTags = paragraphText
            .replacingOccurrences(of: "<JESUS>", with: "")
            .replacingOccurrences(of: "</JESUS>", with: "")
        let withoutNumbers = withoutTags.replacingOccurrences(
            of: #"\b\d+:\d+\b"#,
            with: "",
            options: .regularExpression
        )
        return withoutNumbers
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var userPrompt: String {
        """
        You are writing a pastoral commentary for the Bible passage \(reference) from the \(translation.uppercased()) translation. PLEASE ADD A TON OF DETAIL.

        Context: This passage is from the \(sourceDescriptor).

        Guidance:
        - Begin with a sentence that cites the passage in parentheses (for example, "John 3:16") and captures its central idea.
        - Continue with a few paragraphs (at least three) that weave together historical or literary background, theological insight, and a gentle invitation toward present-day application.
        - Separate each paragraph with a blank line so they appear as distinct blocks of text.
        - Write warmly, clearly, and concisely—avoid epistolary greetings or direct address like "dear friend".
        - Keep everything theologically orthodox and acknowledge the \(sourceDescriptor) setting when it shapes interpretation.

        Follow the style demonstrated below (note the level of detail and the blank line spacing):

        Example (New Testament):
        (John 3:16) This verse reveals the heart of God's redemptive love, showing that eternal life is secured through believing in the Son.

        Early Christian tradition places the Gospel's composition in the late first century among communities around Ephesus who wrestled with synagogue expulsion and imperial suspicion. John situates Jesus' midnight conversation with Nicodemus immediately after references to the bronze serpent (Numbers 21) to show how the Son will be "lifted up" for healing. By naming "the world," he signals that God's covenant mercy now embraces Jew and Gentile without severing Israel's story.

        Theologically, the verse insists that love initiates salvation: the Father gives, the Son offers Himself, and those who believe receive life that begins now and stretches into eternity. It keeps divine justice and mercy together by tying the world's rescue to the Son's sacrificial self-offering. The verse therefore guards against both transactional religion and effortless universalism, locating salvation in trusting the crucified and risen Christ.

        For modern readers, John 3:16 reshapes how we view ourselves and our neighbors. When shame whispers that we are unwanted, the Father's giving refutes it; when evangelism feels intimidating, the verse supplies a simple, beautiful announcement. Let this promise guide times of prayer, prompt generous hospitality, and embolden you to speak of Christ's love in daily conversations.

        Example (Old Testament):
        (Psalm 23:4) David testifies that even in the darkest valleys, the Lord's nearness steadies His people with comfort and courage.

        Within Israel's worship life, Psalm 23 equipped pilgrims traversing Judea's wadis—narrow ravines where predators and thieves lurked—with words of confidence. Shepherds in that terrain carried a sturdy rod to drive off threats and a curved staff to lift sheep from crevices; David appropriates those tools to portray Yahweh's active guardianship. The psalm notably shifts from third person ("He") to second person ("You") right in the valley, highlighting God's intimate presence.

        Theologically, Psalm 23:4 maintains that suffering doesn't void covenant promises but becomes the arena where the Shepherd's companionship is proven. Prophets and apostles would echo this pattern, culminating in Jesus who called Himself the Good Shepherd and willingly entered death's valley for His flock (John 10). The verse therefore anchors hope in the character of God rather than in the absence of danger.

        Today, believers can let this imagery shape concrete practices during their own valleys—praying the psalm aloud in hospital rooms, inviting trusted friends to carry burdens, or incorporating Sabbath rest as a sign of trust. Naming fears before the Shepherd and recalling His past faithfulness grows courage. His rod and staff still steady those who walk through shadows, reminding us that the path may be dark but never deserted.

        Passage Text:
        \(cleanedVerseText)
        """
    }

    private var normalizedBookName: String {
        bookName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var sourceDescriptor: String {
        let normalizedName = normalizedBookName
        if Testament.apocryphaNames.contains(normalizedName) {
            return "Apocrypha (deuterocanonical writings)"
        }
        if Testament.enochNames.contains(normalizedName) {
            return "Book of Enoch"
        }
        if Testament.oldNames.contains(normalizedName) {
            return "Old Testament"
        }
        if Testament.newNames.contains(normalizedName) {
            return "New Testament"
        }
        return "Bible"
    }

    var shouldDisplayTranslationBadge: Bool {
        let normalizedName = normalizedBookName
        return !Testament.apocryphaNames.contains(normalizedName) && !Testament.enochNames.contains(normalizedName)
    }
}
