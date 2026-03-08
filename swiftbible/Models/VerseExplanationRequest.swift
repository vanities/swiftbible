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
        - After that opening sentence, write **exactly three paragraphs** and nothing less. Each paragraph must start on a new line and be separated from the next by a blank line.
        - After finishing the first paragraph, continue immediately to the second and third; the response is incomplete (and should not stop) until all three paragraphs are written.
        - If you ever output fewer than three paragraphs, continue generating text until this requirement is satisfied.
        - Paragraph 1: Offer historical or literary context for the passage, citing relevant background.
        - Paragraph 2: Explore the theological meaning drawn from the passage, noting how the \(sourceDescriptor) setting shapes interpretation.
        - Paragraph 3: Provide a gentle, pastoral application that invites the reader to respond today.
        - Write warmly, clearly, and concisely—avoid epistolary greetings or direct forms of address like "dear friend".

        Follow the style demonstrated below (each property corresponds to the structured fields you must populate):

        Example (New Testament):
        summary: (John 3:16) This verse reveals the heart of God's redemptive love, showing that eternal life is secured through believing in the Son.
        context: Early Christian tradition places the Gospel's composition in the late first century among communities around Ephesus who wrestled with synagogue expulsion and imperial suspicion. John situates Jesus' midnight conversation with Nicodemus alongside the bronze serpent episode (Numbers 21) to show continuity in God's saving plan.
        theology: The verse insists that love initiates salvation—the Father gives, the Son is lifted up, and those who believe receive life that begins now and stretches into eternity. It holds together divine justice and mercy while guarding against transactional religion or effortless universalism.
        application: When shame whispers that we are unwanted, the Father's giving refutes it. Let this promise guide prayer, generous hospitality, and courageous witness as you announce Christ's love to neighbors.
        literary: John uses "agapaō" to emphasize active, covenant love and repeats "world" to signal the widening embrace of God's mercy. The "lifted up" language mirrors the Septuagint phrasing of Numbers 21.
        history: Authored by the apostle John (c. AD 90) for a Jewish and Gentile audience in Asia Minor, the passage sits firmly in the New Testament canon and addresses communities under religious and imperial pressure.

        Example (Old Testament):
        summary: (Psalm 23:4) David testifies that even in the darkest valleys, the Lord's nearness steadies His people with comfort and courage.
        context: As part of Israel's worship life, Psalm 23 armed pilgrims traversing Judea's ravines with words of trust. Shepherds carried a rod for defense and a staff for guidance—imagery David repurposes to portray Yahweh's active guardianship.
        theology: Suffering does not nullify covenant promises; it becomes the arena where the Shepherd's companionship is proven. Prophets and apostles echo this pattern, culminating in Jesus the Good Shepherd who enters the valley of death for His flock.
        application: Pray this psalm aloud in hospital rooms, entrust your anxieties to the Shepherd, and lean on community when shadows fall. His rod and staff still steady those who walk through darkness.
        literary: The psalm shifts from third person ("He") to second person ("You") at the valley, heightening intimacy. The Hebrew "tsalmavet" ("deep darkness") captures both literal gloom and metaphorical threat.
        history: Traditionally attributed to King David (c. 1000 BC) within the Hebrew Psalter, Psalm 23 belongs to the Old Testament canon and addressed Israelites seeking assurance of Yahweh's presence amid danger.

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
            return "Book of Enoch (pseudepigraphic)"
        }
        if Testament.jubileesNames.contains(normalizedName) {
            return "Book of Jubilees (pseudepigraphic)"
        }
        if Testament.testamentsNames.contains(normalizedName) {
            return "Testaments of the Twelve Patriarchs (pseudepigraphic)"
        }
        if Testament.secondEnochNames.contains(normalizedName) {
            return "2 Enoch / Secrets of Enoch (pseudepigraphic)"
        }
        if Testament.didacheNames.contains(normalizedName) {
            return "Didache (early Christian writing)"
        }
        if Testament.firstClementNames.contains(normalizedName) {
            return "1 Clement (early Christian writing)"
        }
        if Testament.oldNames.contains(normalizedName) {
            return "Old Testament"
        }
        if Testament.newNames.contains(normalizedName) {
            return "New Testament"
        }
        return "Bible"
    }

    private static let nonTranslationNames: Set<String> = {
        var names = Set<String>()
        names.formUnion(Testament.apocryphaNames)
        names.formUnion(Testament.enochNames)
        names.formUnion(Testament.jubileesNames)
        names.formUnion(Testament.testamentsNames)
        names.formUnion(Testament.secondEnochNames)
        names.formUnion(Testament.didacheNames)
        names.formUnion(Testament.firstClementNames)
        return names
    }()

    var shouldDisplayTranslationBadge: Bool {
        !Self.nonTranslationNames.contains(normalizedBookName)
    }
}
