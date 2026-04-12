import SwiftUI

struct DevotionalView: View {
    @EnvironmentObject var store: DevotionalStore
    @State private var showReminderSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "sun.horizon.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(store.dateLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                if store.isLoading && store.markdown.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 24)
                } else if let error = store.errorMessage, store.markdown.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await store.load(force: true) }
                        }
                        .font(.footnote)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                } else {
                    renderedDevotional
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 12)
        }
        .navigationTitle("Devotional")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showReminderSheet = true
                } label: {
                    Image(systemName: "bell")
                }
            }
        }
        .sheet(isPresented: $showReminderSheet) {
            ReminderSettingsView()
        }
        .refreshable {
            await store.load(force: true)
        }
    }

    /// Parses the devotional markdown into a heading + body paragraphs.
    /// Swift's `AttributedString(markdown:)` handles inline emphasis well;
    /// we split by blank lines so paragraphs get proper spacing on watchOS.
    @ViewBuilder
    private var renderedDevotional: some View {
        let paragraphs = store.markdown
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let first = paragraphs.first {
            Text(stripMarkdownHeading(first))
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .padding(.top, 2)
        }

        ForEach(Array(paragraphs.dropFirst().enumerated()), id: \.offset) { _, para in
            Text(attributed(para))
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func attributed(_ text: String) -> AttributedString {
        if let attr = try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) {
            return attr
        }
        return AttributedString(text)
    }

    private func stripMarkdownHeading(_ text: String) -> String {
        var s = text
        while s.hasPrefix("#") { s.removeFirst() }
        return s.trimmingCharacters(in: .whitespaces)
    }
}

#Preview {
    let store = DevotionalStore()
    store.markdown = """
    April 11, 2026 — Psalm 23: The Lord Is My Shepherd

    In Psalm 23, David paints a picture of God as a shepherd who provides, protects, and guides.

    Even in the darkest valleys, we need not fear, for God's rod and staff bring comfort.
    """
    store.dateLabel = "Saturday, Apr 11"
    return NavigationStack {
        DevotionalView().environmentObject(store)
    }
}
