//
//  TranslationInfoView.swift
//  swiftbible
//
//  Created on 2/4/26.
//

import SwiftUI

struct TranslationInfo: Identifiable {
    let id = UUID()
    let version: Version
    let year: String
    let history: String
    let translationMethod: String
    let sourceTexts: String
    let notableFeatures: [String]
    let whyWeUseIt: String
    let sources: [(title: String, url: String)]
}

struct TranslationInfoView: View {
    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @AppStorage("fontSize") private var fontSize: Int = 20

    private let translations: [TranslationInfo] = [
        TranslationInfo(
            version: .kjv,
            year: "1611",
            history: "Commissioned by King James I of England in 1604, the KJV was translated by 47 scholars organized into 6 companies at Westminster, Oxford, and Cambridge. These scholars included the finest biblical linguists of the era. The work took 7 years and was published in 1611. The text we use today is primarily the 1769 Oxford revision, which standardized spelling and corrected printing errors.",
            translationMethod: "Formal Equivalence (word-for-word). The translators aimed for literal accuracy while maintaining readable English prose. They consulted earlier English translations including the Tyndale Bible, Geneva Bible, and Bishops' Bible.",
            sourceTexts: "Old Testament: Masoretic Hebrew Text. New Testament: Textus Receptus (based on Byzantine manuscripts compiled by Erasmus). Apocrypha: Greek Septuagint and Latin Vulgate.",
            notableFeatures: [
                "Introduced over 250 phrases still used in English today",
                "Written in Early Modern English with \"thee\" and \"thou\"",
                "Poetic, rhythmic prose ideal for reading aloud",
                "Most printed book in history"
            ],
            whyWeUseIt: "The most influential English Bible translation with over 400 years of continuous use. Its majestic prose has shaped English literature, hymnody, and Christian thought. Many consider it the gold standard for liturgical reading. Public domain in the United States (Crown copyright applies only in the UK).",
            sources: [
                ("Wikipedia", "https://en.wikipedia.org/wiki/King_James_Version"),
                ("Britannica", "https://www.britannica.com/topic/King-James-Version"),
                ("KJV History", "https://www.kingjamesbibleonline.org/1611-Bible/")
            ]
        ),
        TranslationInfo(
            version: .asv,
            year: "1901",
            history: "A revision of the 1881 English Revised Version, led by American scholar Philip Schaff. Work began in 1872 with 30 American and British scholars collaborating for nearly 30 years. The American committee continued refining the text after the British published in 1885, finally releasing the ASV in 1901.",
            translationMethod: "Formal Equivalence (word-for-word). Extremely literal translation prioritizing accuracy over readability. The translators sought to convey the precise meaning of the original languages, even when it resulted in awkward English phrasing.",
            sourceTexts: "Old Testament: Masoretic Hebrew Text with critical apparatus. New Testament: Westcott-Hort Greek Text (1881), which favored Alexandrian manuscripts over the Byzantine tradition used by the KJV.",
            notableFeatures: [
                "Uses \"Jehovah\" 6,823 times instead of \"LORD\"",
                "More consistent translation of Hebrew/Greek words",
                "Basis for NASB, RSV, and other modern translations",
                "Preferred by Jehovah's Witnesses for its use of the divine name"
            ],
            whyWeUseIt: "Called \"The Rock of Biblical Honesty\" for its extreme accuracy. Highly respected in scholarly circles and Church of Christ congregations. Its literal approach makes it excellent for detailed Bible study where precision matters. Entered public domain January 1, 1957.",
            sources: [
                ("Wikipedia", "https://en.wikipedia.org/wiki/American_Standard_Version"),
                ("GotQuestions", "https://www.gotquestions.org/American-Standard-Version-ASV.html"),
                ("Bible Researcher", "https://www.bible-researcher.com/asv.html")
            ]
        ),
        TranslationInfo(
            version: .web,
            year: "1994-2020",
            history: "In 1994, Michael Paul Johnson began updating the ASV to create a modern English translation that would be free forever. He studied Greek and Hebrew, collaborated with volunteers worldwide via the early internet, and released drafts for community feedback. The translation was deemed complete in 2020 after 26 years of refinement.",
            translationMethod: "Formal Equivalence (word-for-word) with modern English. Maintains the ASV's literal accuracy while updating archaic vocabulary and grammar. Aims for a 10th-grade reading level.",
            sourceTexts: "Old Testament: Biblia Hebraica Stuttgartensia (Masoretic Text). New Testament: Greek Majority Text (similar to Byzantine tradition) combined with Textus Receptus readings. Deuterocanon available separately.",
            notableFeatures: [
                "Intentionally public domain - no copyright restrictions ever",
                "Uses \"Yahweh\" for the divine name (British edition uses \"LORD\")",
                "Available in multiple editions (American, British, Catholic)",
                "Continuously maintained and freely distributed online"
            ],
            whyWeUseIt: "The only major modern English translation dedicated entirely to the public domain. You can freely quote, share, print, and distribute it without permission or royalties. Combines ASV's scholarly accuracy with readable contemporary English - the best of both worlds.",
            sources: [
                ("Official Site", "https://worldenglish.bible/"),
                ("Wikipedia", "https://en.wikipedia.org/wiki/World_English_Bible"),
                ("WEB History", "https://ebible.org/webhistory.htm"),
                ("WEB FAQ", "https://ebible.org/web/webfaq.htm")
            ]
        )
    ]

    var body: some View {
        List {
            // Introduction Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("The Bible was originally written in Hebrew (Old Testament), Aramaic (portions of Daniel and Ezra), and Greek (New Testament). Since most people don't read these ancient languages, translations make Scripture accessible to everyone.")
                        .font(Font.custom(fontName, size: CGFloat(fontSize - 4)))

                    Text("Why Translations Differ")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("**Source Texts**: Translators use different ancient manuscripts. Older doesn't always mean better—scholars weigh manuscript quality, not just age.")
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("**Translation Philosophy**: Some prioritize word-for-word accuracy (formal equivalence), others thought-for-thought clarity (dynamic equivalence).")
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("**Language Evolution**: English changes over time. \"Suffer the little children\" (KJV) means \"let\" not \"cause pain.\"")
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("**Textual Discoveries**: Since 1611, thousands of earlier manuscripts have been found, improving our understanding of the original text.")
                        }
                    }
                    .font(Font.custom(fontName, size: CGFloat(fontSize - 4)))

                    Text("Why Multiple Translations Matter")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                    Text("No single translation captures every nuance of the original languages. Comparing translations reveals depth and meaning that any one version alone might miss. A literal translation shows the structure of the original; a readable translation conveys the flow of thought. Together, they illuminate Scripture more fully.")
                        .font(Font.custom(fontName, size: CGFloat(fontSize - 4)))
                }
                .padding(.vertical, 4)
            } header: {
                Text("Understanding Bible Translations")
            }

            ForEach(translations) { translation in
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        // Year badge
                        HStack {
                            Text(translation.year)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.2))
                                .cornerRadius(6)
                            Spacer()
                        }

                        // History
                        VStack(alignment: .leading, spacing: 4) {
                            Text("History")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Text(translation.history)
                                .font(Font.custom(fontName, size: CGFloat(fontSize - 4)))
                        }

                        // Translation Method
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Translation Method")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Text(translation.translationMethod)
                                .font(Font.custom(fontName, size: CGFloat(fontSize - 4)))
                        }

                        // Source Texts
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Source Texts")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Text(translation.sourceTexts)
                                .font(Font.custom(fontName, size: CGFloat(fontSize - 4)))
                        }

                        // Notable Features
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notable Features")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            ForEach(translation.notableFeatures, id: \.self) { feature in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(Font.custom(fontName, size: CGFloat(fontSize - 4)))
                                    Text(feature)
                                        .font(Font.custom(fontName, size: CGFloat(fontSize - 4)))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }

                        // Why We Use It
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Why We Use It")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Text(translation.whyWeUseIt)
                                .font(Font.custom(fontName, size: CGFloat(fontSize - 4)))
                        }

                        // Sources
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Learn More")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            ForEach(translation.sources, id: \.url) { source in
                                Button {
                                    if let url = URL(string: source.url) {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "link")
                                            .font(.caption)
                                        Text(source.title)
                                            .font(Font.custom(fontName, size: CGFloat(fontSize - 4)))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(translation.version.displayName)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("All translations in SwiftBible are in the public domain, meaning they can be freely used, shared, and distributed without copyright restrictions.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("About Public Domain")
            }
        }
        .navigationBarTitle("About Translations")
    }
}

#Preview {
    NavigationStack {
        TranslationInfoView()
    }
}
