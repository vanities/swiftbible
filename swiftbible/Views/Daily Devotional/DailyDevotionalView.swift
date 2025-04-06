//
//  DailyDevotionalView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/6/24.
//

import SwiftUI
import MarkdownUI

struct DailyDevotional: Decodable {
    let id: Int
    let message: String
    let for_date: String
}

struct DailyDevotionalView: View {
    @AppStorage("fontSize") private var fontSize: Int = 20
    @Environment(UserViewModel.self) private var userViewModel

    @State private var message: String = ""
    @State private var isLoading: Bool = false
    @State private var hasDevotional: Bool = false
    @State private var selectedDate: Date = Date()

    // Animations
    @State private var pulse = false
    @State private var showNoDevotional = false
    @State private var sparkleTwinkle = false

    var body: some View {
        VStack(spacing: 0) {
            DatePicker("Select a date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding()
                .onChange(of: selectedDate) { newDate in
                    Task { await fetchDailyDevotional(for: newDate) }
                }

            if isLoading {
                VStack(spacing: 12) {
                    Spacer()

                    Image(systemName: "book.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.accentColor)
                        .scaleEffect(pulse ? 1.1 : 0.9)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
                        .onAppear { pulse = true }
                        .onDisappear() { pulse = false }

                    Text("Fetching today's message...")
                        .font(.headline)
                        .transition(.opacity)

                    Spacer()
                }
                .padding(.top, 40)
            } else if hasDevotional {
                ScrollView {
                    Markdown(message)
                        .padding()
                        .markdownBlockStyle(\.heading1) { configuration in
                            configuration.label
                                .markdownMargin(top: .em(1), bottom: .em(1))
                                .markdownTextStyle {
                                    FontWeight(.bold)
                                    FontSize(.em(1))
                                }
                        }
                }
            } else {
                VStack(spacing: 12) {
                    Spacer()

                    Image(systemName: "sparkles")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(sparkleTwinkle ? -2 : 2))
                        .opacity(sparkleTwinkle ? 0.9 : 1.0)
                        .scaleEffect(showNoDevotional ? 1 : 0.8)
                        .foregroundColor(.accentColor)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: sparkleTwinkle)
                        .onAppear {
                            sparkleTwinkle = true
                            showNoDevotional = true
                        }
                        .onDisappear() {
                            sparkleTwinkle = false
                            showNoDevotional = false
                        }

                    Text("No devotional found for this day.")
                        .font(.headline)
                        .opacity(showNoDevotional ? 1 : 0)
                        .animation(.easeIn.delay(0.2), value: showNoDevotional)

                    Text(selectedDate > Date()
                          ? "Come back on \(formattedDate(selectedDate))!"
                          : "We may have missed this one.")
                        .foregroundColor(.secondary)
                        .opacity(showNoDevotional ? 1 : 0)
                        .animation(.easeIn.delay(0.3), value: showNoDevotional)

                    Spacer()
                }
                .padding(.top, 40)
                .onAppear {
                    showNoDevotional = true
                }
            }
        }
        .font(Font.system(size: CGFloat(fontSize)))
        .onAppear {
            Task { await fetchDailyDevotional(for: selectedDate) }
        }
        .onDisappear() {
            selectedDate = Date()
        }
        .accessibilityIdentifier("DailyDevotionalView")
    }

    private func fetchDailyDevotional(for date: Date) async {
        isLoading = true
        hasDevotional = false
        showNoDevotional = false
        message = ""

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        do {
            let devotional: DailyDevotional = try await SupabaseService.shared.client
                .from("Daily Devotional")
                .select()
                .eq("for_date", value: dateString)
                .single()
                .execute()
                .value

            message = devotional.message
            hasDevotional = true
        } catch {
            print("No devotional found for \(dateString): \(error)")
        }

        isLoading = false
    }

    private func formattedDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .long
        return df.string(from: date)
    }
}

#Preview {
    DailyDevotionalView()
        .environment(UserViewModel())
}
