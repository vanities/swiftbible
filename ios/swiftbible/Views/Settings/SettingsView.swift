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
    @Environment(AppUpdateService.self) private var updateService
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("showJesusWordsInRed") var showJesusWordsInRed = true
    @AppStorage("hideNavAndTab") var hideNavAndTab = false
    @AppStorage(ToastService.achievementToastsKey) var showAchievementToasts = true
    @AppStorage("readingTheme") private var readingThemeRaw: String = ReadingTheme.system.rawValue
    @AppStorage("showApocrypha") var showApocrypha = false
    @AppStorage("showJewishPseudepigraphaEnoch") var showJewishPseudepigraphaEnoch = false
    @AppStorage("showJubilees") var showJubilees = false
    @AppStorage("showTestaments") var showTestaments = false
    @AppStorage("showSecondEnoch") var showSecondEnoch = false
    @AppStorage("showDidache") var showDidache = false
    @AppStorage("showFirstClement") var showFirstClement = false
    @AppStorage("showThematicGrouping") var showThematicGrouping = false
    @AppStorage("summarySource") private var summarySourceRaw: String = defaultSummarySource.rawValue

    @AppStorage(DonationPreferences.promptOptOutKey) private var donationPromptOptOut = false
    @AppStorage(DonationPreferences.donationCompletedKey) private var hasCompletedDonation = false
    @AppStorage("devotionalReminderEnabled") private var reminderEnabled = false
    @AppStorage("devotionalReminderHour") private var reminderHour: Int = 21
    @AppStorage("devotionalReminderMinute") private var reminderMinute: Int = 0
    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @AppStorage("fontSize") private var fontSize: Int = 20
    @AppStorage(BookmarkPreferences.bookKey) private var bookmarkedBookName: String = ""
    @AppStorage(BookmarkPreferences.chapterKey) private var bookmarkedChapterNumber: Int = 0
    @AppStorage(BookmarkPreferences.verseKey) private var bookmarkedVerseNumber: Int = 0

    @Binding var selectedTab: Tabs
    @State private var donationCurrency: String = "USD"
    @State private var showDonationSheet = false
    @AppStorage("customAccentColor") private var customAccentHex: String = ""
    @AppStorage("debug_forceShowEvents") private var debugForceShowEvents: Bool = false
    @State private var cacheSize: String = "0 KB"
    @State private var showClearCacheAlert = false
    @State private var showCacheToast = false
    @State private var showOnboardingResetToast = false
    @State private var versionTapCount = 0
    @State private var showCopiedToast = false

    private var readingTheme: ReadingTheme {
        ReadingTheme(rawValue: readingThemeRaw) ?? .system
    }

    @ViewBuilder
    private var debugAndVersionSections: some View {
                if showDebugSection {
                    Section {
                        Toggle(isOn: $debugForceShowEvents) {
                            accentLabel(
                                "Force-Show Events (ignore date)",
                                systemImage: "flame.fill",
                                tint: .brandGold
                            )
                        }
                        Button {
                            // Open the Pentecost EventDetailView immediately for testing.
                            if let event = AppEventRegistry.event(forId: "pentecost-2026") {
                                appViewModel.presentedEvent = event
                            }
                        } label: {
                            accentLabel("Open Pentecost Event View", systemImage: "calendar.badge.clock", tint: .brandGold)
                        }
                        Button {
                            appViewModel.testConfetti()
                        } label: {
                            accentLabel("Test Confetti 🎉", systemImage: "sparkles", tint: .brandGold)
                        }
                        Button {
                            // Wipe both onboarding flags so the next cold
                            // launch behaves exactly like a brand-new install.
                            // We deliberately do NOT present the tour now —
                            // the goal is to test the actual launch path.
                            OnboardingPreferences.resetCompletely()
                            withAnimation { showOnboardingResetToast = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation { showOnboardingResetToast = false }
                            }
                        } label: {
                            accentLabel("Reset Onboarding (restart to see)", systemImage: "arrow.counterclockwise.circle.fill")
                        }
                        ForEach(DonationPromptVariant.allCases, id: \.rawValue) { variant in
                            Button {
                                appViewModel.donationVariant = variant
                                showDonationSheet = true
                            } label: {
                                accentLabel("Donation: \(variant.rawValue)", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        }
                    } header: {
                        sectionHeader("Debug", systemImage: "hammer.fill")
                    }
                    .readingThemeCardRow(readingTheme, colorScheme: colorScheme)
                }
                Section {
                    VStack(spacing: 4) {
                        Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                            .foregroundColor(.gray)
                            .font(Font.custom(fontName, size: CGFloat(fontSize - 4), relativeTo: .footnote))

                        switch updateService.updateStatus {
                        case .upToDate:
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Up to date")
                                    .foregroundColor(.secondary)
                            }
                            .font(.caption)
                        case .updateAvailable(let version):
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.orange)
                                Text("v\(version) available")
                                    .foregroundColor(.orange)
                            }
                            .font(.caption)
                        case .unknown:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        versionTapCount += 1
                        if versionTapCount >= 5 {
                            versionTapCount = 0
                            let idString: String
                            if let userId = userViewModel.user?.id {
                                idString = userId.uuidString
                            } else {
                                idString = UserDefaults.standard.string(forKey: "donationAnonymousIdentifier") ?? "no-id"
                            }
                            UIPasteboard.general.string = idString
                            withAnimation {
                                showCopiedToast = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showCopiedToast = false
                                }
                            }
                        }
                    }
                }
                .readingThemeCardRow(readingTheme, colorScheme: colorScheme)
    }

    var body: some View {
        @Bindable var userViewModel = userViewModel
        @Bindable var appViewModel = appViewModel

        NavigationStack {
            List {
                Section {
                    introCard
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section {
                    NavigationLink(destination: FontOptionsView()) {
                        accentLabel("Font Options", systemImage: "textformat.size")
                    }
                    NavigationLink(destination: ColorOptionsView()) {
                        accentLabel("Color Options", systemImage: "paintpalette.fill")
                    }
                    Toggle(isOn: $showJesusWordsInRed) {
                        accentLabel("Jesus's Words in Red", systemImage: "quote.opening", tint: .brandRed)
                    }
                    .onChange(of: showJesusWordsInRed) { _, newValue in
                        AnalyticsService.shared.capture(.jesusWordsToggled, properties: ["enabled": newValue])
                    }
                    Toggle(isOn: $hideNavAndTab) {
                        accentLabel("Hide Bars While Reading", systemImage: "eye.slash")
                    }
                    Picker(
                        selection: Binding(
                            get: { SummarySource(rawValue: summarySourceRaw) ?? defaultSummarySource },
                            set: { newValue in
                                summarySourceRaw = newValue.rawValue
                                AnalyticsService.shared.capture(
                                    .summarySourceChanged,
                                    properties: ["source": newValue.rawValue]
                                )
                            }
                        )
                    ) {
                        ForEach(SummarySource.allCases) { source in
                            Text(source.displayName).tag(source)
                        }
                    } label: {
                        accentLabel("Study Notes", systemImage: "book.closed.fill")
                    }
                } header: {
                    sectionHeader("Reading", systemImage: "book.fill")
                }
                .readingThemeCardRow(readingTheme, colorScheme: colorScheme)
                Section {
                    Picker(selection: $appViewModel.selectedVersion) {
                        ForEach(Version.allCases, id: \.rawValue) { version in
                            Text(version.displayName).tag(version)
                        }
                    } label: {
                        accentLabel("Translation", systemImage: "character.book.closed.fill")
                    }
                    .onChange(of: appViewModel.selectedVersion) { _, newVersion in
                        AnalyticsService.shared.capture(.versionChanged, properties: [
                            "version": newVersion.rawValue
                        ])
                    }
                    Toggle(isOn: $showThematicGrouping) {
                        accentLabel("Group Books by Theme", systemImage: "rectangle.3.group")
                    }
                    .onChange(of: showThematicGrouping) { _, newValue in
                        AnalyticsService.shared.capture(.thematicGroupingToggled, properties: ["enabled": newValue])
                    }
                    NavigationLink(destination: TranslationInfoView()) {
                        accentLabel("About Translations", systemImage: "info.circle.fill")
                    }
                } header: {
                    sectionHeader("Bible Translation", systemImage: "globe.americas.fill")
                }
                .readingThemeCardRow(readingTheme, colorScheme: colorScheme)
                Section {
                    DisclosureGroup {
                        Toggle("Apocrypha", isOn: $showApocrypha)
                            .onChange(of: showApocrypha) { _, newValue in
                                AnalyticsService.shared.capture(.apocryphaToggled, properties: ["enabled": newValue])
                            }
                        Toggle("Book of Enoch", isOn: $showJewishPseudepigraphaEnoch)
                            .onChange(of: showJewishPseudepigraphaEnoch) { _, newValue in
                                AnalyticsService.shared.capture(.enochToggled, properties: ["enabled": newValue])
                            }
                        Toggle("2 Enoch (Secrets of Enoch)", isOn: $showSecondEnoch)
                            .onChange(of: showSecondEnoch) { _, newValue in
                                AnalyticsService.shared.capture(.secondEnochToggled, properties: ["enabled": newValue])
                            }
                        Toggle("Book of Jubilees", isOn: $showJubilees)
                            .onChange(of: showJubilees) { _, newValue in
                                AnalyticsService.shared.capture(.jubileesToggled, properties: ["enabled": newValue])
                            }
                        Toggle("Testaments of the Twelve Patriarchs", isOn: $showTestaments)
                            .onChange(of: showTestaments) { _, newValue in
                                AnalyticsService.shared.capture(.testamentsToggled, properties: ["enabled": newValue])
                            }
                        Toggle("Didache", isOn: $showDidache)
                            .onChange(of: showDidache) { _, newValue in
                                AnalyticsService.shared.capture(.didacheToggled, properties: ["enabled": newValue])
                            }
                        Toggle("1 Clement", isOn: $showFirstClement)
                            .onChange(of: showFirstClement) { _, newValue in
                                AnalyticsService.shared.capture(.firstClementToggled, properties: ["enabled": newValue])
                            }
                    } label: {
                        HStack {
                            accentLabel("Additional Texts", systemImage: "books.vertical.fill")
                            Spacer()
                            Text("\(extraTextsEnabledCount) on")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    sectionHeader("Library Extras", systemImage: "scroll.fill")
                } footer: {
                    Text("Apocrypha, Jewish pseudepigrapha, and early Christian writings — valued by some traditions outside the standard biblical canon.")
                }
                .readingThemeCardRow(readingTheme, colorScheme: colorScheme)
                Section {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        HStack {
                            accentLabel("Devotional Reminder", systemImage: "bell.fill")
                            Spacer()
                            Text(reminderSummary)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Toggle(isOn: $showAchievementToasts) {
                        accentLabel("Achievement Celebrations", systemImage: "trophy.fill", tint: .brandGold)
                    }
                } header: {
                    sectionHeader("Notifications", systemImage: "bell.badge.fill")
                } footer: {
                    Text("Show a banner and confetti when you earn a badge. Badges are still recorded in your collection.")
                }
                .readingThemeCardRow(readingTheme, colorScheme: colorScheme)
                Section {
                    HStack {
                        accentLabel("Cache Size", systemImage: "internaldrive.fill")
                        Spacer()
                        Text(cacheSize)
                            .foregroundStyle(.secondary)
                    }
                    Button(role: .destructive) {
                        showClearCacheAlert = true
                    } label: {
                        Label("Clear All Cache", systemImage: "trash")
                    }
                } header: {
                    sectionHeader("Storage", systemImage: "externaldrive.fill")
                }
                .readingThemeCardRow(readingTheme, colorScheme: colorScheme)
                Section {
                    supportCard

                    if appViewModel.totalPaidCents > 0 || !appViewModel.donationHistory.isEmpty {
                        NavigationLink(destination: DonationHistoryView()) {
                            HStack {
                                accentLabel("Donation History", systemImage: "clock.arrow.circlepath")
                                Spacer()
                                Text(appViewModel.formattedNetDonation)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Toggle(isOn: Binding(
                        get: { !donationPromptOptOut },
                        set: {
                            donationPromptOptOut = !$0
                            if donationPromptOptOut {
                                AnalyticsService.shared.capture(.donationPromptOptedOut)
                            }
                        }
                    )) {
                        accentLabel("Donation Reminder Popup", systemImage: "bubble.left.and.bubble.right.fill")
                    }

                    if canAccessDonorPerks {
                        NavigationLink(destination: DonorPerksView()) {
                            HStack {
                                accentLabel("Donor Perks", systemImage: "sparkles", tint: .brandGold)
                                Spacer()
                                if !customAccentHex.isEmpty {
                                    Circle()
                                        .fill(Color(hex: customAccentHex))
                                        .frame(width: 14, height: 14)
                                }
                            }
                        }
                    }
                } header: {
                    sectionHeader("Support swiftbible", systemImage: "heart.fill")
                }
                .readingThemeCardRow(readingTheme, colorScheme: colorScheme)
                Section {
                    Button {
                        openMail(subject: "swiftbible - Contact Us")
                    } label: {
                        accentLabel("Contact Us", systemImage: "envelope.fill")
                    }
                    Button {
                        openMail(subject: "swiftbible - Bug")
                    } label: {
                        accentLabel("Report a Bug", systemImage: "ladybug.fill")
                    }
                    Button {
                        if let url = URL(string: "https://github.com/vanities/swiftbible") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        accentLabel("View Source on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    Button {
                        guard let url = URL(string: "itms-apps://itunes.apple.com/app/\(AppConfig.appleAppID)") else { return }
                        UIApplication.shared.open(url)
                    } label: {
                        accentLabel("View on App Store", systemImage: "applelogo")
                    }
                    if case .updateAvailable(let version) = updateService.updateStatus {
                        Button {
                            updateService.openAppStore()
                        } label: {
                            HStack {
                                accentLabel("Update to v\(version)", systemImage: "arrow.down.circle.fill", tint: .accentColor)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                    Button {
                        if let url = URL(string: "https://am2.biz/swiftbible") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        accentLabel("Website", systemImage: "globe")
                    }
                    NavigationLink(destination: TextSourcesView()) {
                        accentLabel("Text Sources", systemImage: "books.vertical.fill")
                    }
                    Button {
                        OnboardingPreferences.resetAll()
                        NotificationCenter.default.post(name: .onboardingReplayRequested, object: nil)
                    } label: {
                        accentLabel("Replay Welcome Tour", systemImage: "sparkles.rectangle.stack.fill")
                    }
                } header: {
                    sectionHeader("About", systemImage: "info.circle.fill")
                }
                .readingThemeCardRow(readingTheme, colorScheme: colorScheme)
                debugAndVersionSections
            }
            .readingThemeContentBackground(readingTheme, colorScheme: colorScheme)
            .navigationBarTitle("Settings")
            .navigationDestination(isPresented: $userViewModel.showSignInFlow) {
                AuthenticateView()
            }
            .accessibilityIdentifier("SettingsView")
        }
        .sheet(isPresented: $showDonationSheet) {
            DonationPromptContainer(
                isPresented: $showDonationSheet,
                currencyCode: donationCurrency,
                variant: appViewModel.donationVariant
            ) { amount in
                appViewModel.requestDonationFlow(
                    amount: amount,
                    currency: donationCurrency,
                    source: "settings"
                )
            }
            .environment(appViewModel)
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
                if showCacheToast || showCopiedToast || showOnboardingResetToast {
                    VStack {
                        Spacer()
                        Text(toastMessage)
                            .multilineTextAlignment(.center)
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

    private var canAccessDonorPerks: Bool {
        #if DEBUG
        return true
        #else
        return appViewModel.totalPaidCents > 0 || userViewModel.isAdmin
        #endif
    }

    private var showDebugSection: Bool {
        #if DEBUG
        return true
        #else
        return userViewModel.isAdmin
        #endif
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

    private var reminderSummary: String {
        guard reminderEnabled else { return "Off" }
        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "On"
    }

    private var hasBookmark: Bool {
        !bookmarkedBookName.isEmpty && bookmarkedChapterNumber > 0 && bookmarkedVerseNumber > 0
    }

    private var toastMessage: String {
        if showOnboardingResetToast {
            return "Onboarding reset.\nQuit and relaunch the app to see it."
        }
        if showCopiedToast {
            return "ID copied to clipboard"
        }
        return "Cache cleared successfully"
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

    // MARK: - Visual helpers

    private var extraTextsEnabledCount: Int {
        [showApocrypha, showJewishPseudepigraphaEnoch, showSecondEnoch, showJubilees,
         showTestaments, showDidache, showFirstClement].filter { $0 }.count
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.brandAccent)
            Text(title.uppercased())
                .tracking(0.5)
        }
    }

    private func accentLabel(_ title: String, systemImage: String, tint: Color = .brandAccent) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
        }
    }

    private var introCard: some View {
        let parchmentSurface: Color = colorScheme == .dark
            ? Color(red: 0.15, green: 0.10, blue: 0.07)
            : Color(red: 0.965, green: 0.94, blue: 0.88)
        let parchmentInk: Color = colorScheme == .dark
            ? Color(red: 0.95, green: 0.92, blue: 0.85)
            : Color(red: 0.18, green: 0.13, blue: 0.10)
        let parchmentMutedInk: Color = colorScheme == .dark
            ? Color(red: 0.78, green: 0.74, blue: 0.66)
            : Color(red: 0.40, green: 0.32, blue: 0.24)

        return HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.brandGold.opacity(0.20))
                    .frame(width: 40, height: 40)
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.brandGold)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Personalize your reading")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(parchmentInk)
                Text("Fonts, translations, notifications, and what's in the Bible browser.")
                    .font(.system(size: 12))
                    .foregroundStyle(parchmentMutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(parchmentSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.brandGold.opacity(0.25), lineWidth: 0.5)
                }
        )
    }

    private var supportCard: some View {
        Button {
            showDonationSheet = true
        } label: {
            HStack(alignment: .center, spacing: 14) {
                if appViewModel.totalPaidCents > 0 {
                    AnimatedDonorHeart()
                        .frame(width: 36, height: 36)
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.brandRed.opacity(0.18))
                            .frame(width: 40, height: 40)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.brandRed)
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(appViewModel.totalPaidCents > 0 ? "Thank you for supporting us" : "Keep swiftbible online")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(appViewModel.totalPaidCents > 0
                         ? "Tap to give again — every gift helps."
                         : "Donations cover server costs and the Apple developer fee.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
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
        .environment(AppViewModel())
}
