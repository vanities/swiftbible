//
//  SettingsView.swift
//  swiftbible
//
//  Created on 9/4/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(AppViewModel.self) private var appViewModel
    @AppStorage("showJesusWordsInRed") var showJesusWordsInRed = true
    @AppStorage("hideNavAndTab") var hideNavAndTab = false
    @AppStorage("showApocrypha") var showApocrypha = false

    @AppStorage(DonationPreferences.promptOptOutKey) private var donationPromptOptOut = false
    @AppStorage(DonationPreferences.donationCompletedKey) private var hasCompletedDonation = false
    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @AppStorage("fontSize") private var fontSize: Int = 20
    @AppStorage(BookmarkPreferences.bookKey) private var bookmarkedBookName: String = ""
    @AppStorage(BookmarkPreferences.chapterKey) private var bookmarkedChapterNumber: Int = 0
    @AppStorage(BookmarkPreferences.verseKey) private var bookmarkedVerseNumber: Int = 0

    @Binding var selectedTab: Tabs
    @State private var donationCurrency: String = "USD"
    @State private var showDonationSheet = false
    @State private var cacheSize: String = "0 KB"
    @State private var showClearCacheAlert = false
    @State private var showCacheToast = false

    var body: some View {
        @Bindable var userViewModel = userViewModel
        @Bindable var appViewModel = appViewModel

        NavigationStack {
            List {
                Section(header: Text("Appearance")) {
                    NavigationLink(destination: FontOptionsView()) {
                        Label("Font Options", systemImage: "textformat.size")
                    }
                    NavigationLink(destination: ColorOptionsView()) {
                        Label("Color Options", systemImage: "paintpalette.fill")
                    }
                    Toggle("Show Jesus's Words in Red", isOn: $showJesusWordsInRed)
                    Toggle("Hide Navigation and Tab Bar while reading", isOn: $hideNavAndTab)
                    // Swipe to change chapters has been removed in favor of pull up/down
                }

                Section(header: Text("App")) {
                    NavigationLink(destination: SeeSavedNotesView(selectedTab: $selectedTab)) {
                        Label("See Saved Notes", systemImage: "note.text")
                    }
                    NavigationLink(destination: SeeHighlightsView(selectedTab: $selectedTab)) {
                        Label("See Highlights", systemImage: "highlighter")
                    }
                    NavigationLink(destination: SavedDevotionalsListView()) {
                        Label("Saved Devotionals", systemImage: "heart.circle")
                    }
                    Button {
                        let bookName = bookmarkedBookName
                        let chapterNumber = bookmarkedChapterNumber
                        let verseNumber = bookmarkedVerseNumber
                        selectedTab = .bible
                        DispatchQueue.main.async {
                            appViewModel.navigateToVerse(
                                bookName: bookName,
                                chapterNumber: chapterNumber,
                                verseNumber: verseNumber
                            )
                        }
                    } label: {
                        HStack {
                            Label("Go to Bookmark", systemImage: "bookmark.fill")
                            Spacer()
                            Text(bookmarkSummary)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!hasBookmark)
                    Toggle("Show Apocrypha", isOn: $showApocrypha)
                }

                Section(header: Text("Storage")) {
                    HStack {
                        Label("Cache Size", systemImage: "internaldrive")
                        Spacer()
                        Text(cacheSize)
                            .foregroundStyle(.secondary)
                    }

                    Button(role: .destructive) {
                        showClearCacheAlert = true
                    } label: {
                        Label("Clear All Cache", systemImage: "trash")
                    }
                }

                Section(header: Text("Support")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Keep swiftbible online")
                            .font(.headline)

                        Text("Donations help cover weekly server costs and the Apple developer fee. Thank you for considering a gift.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    if appViewModel.totalPaidCents > 0 || !appViewModel.donationHistory.isEmpty {
                        NavigationLink(destination: DonationHistoryView()) {
                            HStack {
                                Label("Donation History", systemImage: "clock.arrow.circlepath")
                                Spacer()
                                Text(appViewModel.formattedNetDonation)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Button {
                        showDonationSheet = true
                    } label: {
                        if appViewModel.totalPaidCents > 0 {
                            HStack {
                                AnimatedDonorHeart()
                                    .frame(width: 24, height: 24)
                                Text("Donate")
                                Spacer()
                                Text("Thank you!")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Label("Donate", systemImage: "heart.fill")
                                .tint(.accentColor)
                        }
                    }

                    Toggle(isOn: Binding(
                        get: { !donationPromptOptOut },
                        set: { donationPromptOptOut = !$0 }
                    )) {
                        Text("Show donation reminder pop up")
                    }
                }

                #if DEBUG
                Section(header: Text("Debug")) {
                    Button {
                        appViewModel.testConfetti()
                    } label: {
                        Label("Test Confetti 🎉", systemImage: "sparkles")
                    }
                }
                #endif

                Section(header: Text("About")) {
                    Button(action: {
                        openMail(subject: "swiftbible - Contact Us")
                    }) {
                        Label("Contact Us", systemImage: "envelope")
                    }

                    Button(action: {
                        openMail(subject: "swiftbible - Bug")
                    }) {
                        Label("Report a Bug", systemImage: "ladybug")
                    }

                    Button(action: {
                        if let url = URL(string: "https://github.com/vanities/swiftbible") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("Check out the code on GitHub", systemImage: "link")
                    }

                    Button(action: {
                        guard let url = URL(string: "itms-apps://itunes.apple.com/app/6670373108") else { return }
                         UIApplication.shared.open(url)
                    }) {
                        Label("View on App Store", systemImage: "apple.logo")
                    }

                    Button(action: {
                        if let url = URL(string: "https://am2.biz/swiftbible") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("View our Website", systemImage: "globe")
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                            .foregroundColor(.gray)
                            .font(Font.custom(fontName, size: CGFloat(fontSize - 4)))
                        Spacer()
                    }
                }

            }
            .navigationBarTitle("Settings")
            .navigationDestination(isPresented: $userViewModel.showSignInFlow) {
                AuthenticateView()
            }
            .accessibilityIdentifier("SettingsView")
        }
        .sheet(isPresented: $showDonationSheet) {
            DonationPromptView(
                isPresented: $showDonationSheet,
                currencyCode: donationCurrency
            ) { amount in
                appViewModel.requestDonationFlow(
                    amount: amount,
                    currency: donationCurrency,
                    source: "settings"
                )
            }
            .presentationDetents([.height(900), .large])
            .presentationDragIndicator(.visible)
        }
        .alert("Clear All Cache?", isPresented: $showClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("This will clear all cached devotionals and free up \(cacheSize) of storage. You can always re-download devotionals when you view them.")
        }
        .overlay(
            Group {
                if showCacheToast {
                    VStack {
                        Spacer()
                        Text("Cache cleared successfully")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .shadow(radius: 10)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 60)
                    }
                }
            }
        )
        .onAppear {
            if let localeCurrency = Locale.current.currency?.identifier {
                donationCurrency = localeCurrency.uppercased()
            }
            updateCacheSize()
        }
    }

    private var formattedDefaultDonationAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.currencyCode = donationCurrency
        let amount = NSDecimalNumber(decimal: DonationPreferences.defaultDonationDollars)
        return formatter.string(from: amount) ?? "$5"
    }

    private var hasBookmark: Bool {
        !bookmarkedBookName.isEmpty && bookmarkedChapterNumber > 0 && bookmarkedVerseNumber > 0
    }

    private var bookmarkSummary: String {
        guard hasBookmark else { return "Not set" }
        return "\(bookmarkedBookName) \(bookmarkedChapterNumber):\(bookmarkedVerseNumber)"
    }

    func openMail(
        _ emailTo: String="mischke@proton.me",
        subject: String = ""
    ) {
        if let url = URL(string: "mailto:\(emailTo)?subject=\(subject.fixToBrowserString())"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    private func updateCacheSize() {
        cacheSize = CacheService.shared.getCacheSizeFormatted()
    }

    private func clearCache() {
        CacheService.shared.clearAllCache()
        updateCacheSize()

        // Show toast notification
        withAnimation {
            showCacheToast = true
        }

        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCacheToast = false
            }
        }
    }
}

private struct AnimatedDonorHeart: View {
    @State private var isAnimating = false
    @State private var glowAmount: CGFloat = 0

    var body: some View {
        ZStack {
            // Glow effect
            Image(systemName: "heart.fill")
                .font(.system(size: 20))
                .foregroundStyle(.pink)
                .blur(radius: glowAmount)
                .opacity(0.6)
                .scaleEffect(isAnimating ? 1.3 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)

            // Main heart with gradient
            Image(systemName: "heart.fill")
                .font(.system(size: 20))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .red, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isAnimating ? 1.15 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)

            // Sparkle overlay that rotates
            Image(systemName: "sparkle")
                .font(.system(size: 8))
                .foregroundStyle(.yellow)
                .offset(x: -8, y: -8)
                .opacity(isAnimating ? 1 : 0)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: isAnimating)

            Image(systemName: "sparkle")
                .font(.system(size: 6))
                .foregroundStyle(.white)
                .offset(x: 7, y: -6)
                .opacity(isAnimating ? 0.8 : 0)
                .rotationEffect(.degrees(isAnimating ? -360 : 0))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)

            Image(systemName: "sparkle")
                .font(.system(size: 5))
                .foregroundStyle(.orange)
                .offset(x: -6, y: 7)
                .opacity(isAnimating ? 0.9 : 0)
                .scaleEffect(isAnimating ? 1.2 : 0.8)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                isAnimating = true
                glowAmount = 3
            }
        }
    }
}

#Preview {
    SettingsView(selectedTab: .constant(.bible))
        .environment(UserViewModel())
}
