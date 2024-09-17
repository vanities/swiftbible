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
}

struct DailyDevotionalView: View {
    @AppStorage("fontSize") private var fontSize: Int = 20
    @Environment(UserViewModel.self) private var userViewModel
    @State private var messsage: String = ""
    @State private var isLoading: Bool = false
    @Binding var selectedTab: Int

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading...")
            } else {
                ScrollView {
                    Markdown(messsage)
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
            }
        }
        .font(Font.system(size: CGFloat(fontSize)))
        .onAppear {
            Task {
                await fetchDailyDevotional()
            }
        }
    }

    private func fetchDailyDevotional() async {
        isLoading = true

        do {
            let devotional: DailyDevotional = try await SupabaseService.shared.client
                .from("Daily Devotional")
                .select()
                .order("id", ascending: false)
                .limit(1)
                .single()
                .execute()
                .value

            messsage = devotional.message
            print("Successfully got Daily Devotional: \(devotional)")
        } catch {
            print("Error fetching daily devotional: \(error)")
        }

        isLoading = false
    }
}
