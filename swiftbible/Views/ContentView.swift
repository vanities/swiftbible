//
//  ContentView.swift
//  swiftbible
//
//  Created on 9/6/24.
//

import SwiftUI
import SwiftData
import StoreKit
import UIKit
import SafariServices
import Combine
import ConfettiSwiftUI

struct ContentView: View {
    @State private var appViewModel = AppViewModel()
    @State private var userViewModel = UserViewModel()
    @State private var selectedTab: Tabs = .bible

    @AppStorage(DonationPreferences.promptOptOutKey) private var donationPromptOptOut = false
    @AppStorage(DonationPreferences.donationCompletedKey) private var hasCompletedDonation = false
    @AppStorage(DonationPreferences.anonIdentifierKey) private var donationAnonIdentifier: String = ""
    @AppStorage("customAccentColor") private var customAccentHex: String = ""

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    @State private var transactionListenerTask: Task<Void, Error>?
    @State private var showDonationPrompt = false
    @State private var showDonationCelebration = false
    @State private var donationFlowActive = false
    @State private var waitingForDonationReturn = false
    @State private var donationCurrency: String = "USD"
    @State private var donationErrorMessage: String?
    @State private var showDonationErrorAlert = false
    @State private var isCreatingDonationSession = false
    @State private var safariCheckout: SafariCheckoutItem?
    @State private var confettiTrigger = 0
    @State private var isAppLaunching = true
    private var donationVariant: DonationPromptVariant { appViewModel.donationVariant }

    @AppStorage("lastCelebratedDonationSessionID") private var lastCelebratedDonationSessionID: String = ""

    var body: some View {
        @Bindable var appViewModel = appViewModel

        TabView(selection: $selectedTab) {
            Tab("Bible", systemImage: "book.fill", value: .bible) {
                BibleView()
            }

            Tab("Devotional", systemImage: "sun.horizon.fill", value: .dailyDevotional) {
                DailyDevotionalView(selectedTab: $selectedTab)
            }

            Tab("Search", systemImage: "magnifyingglass", value: .search, role: .search) {
                SearchDetailView(selectedTab: $selectedTab)
            }

            Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                SettingsView(selectedTab: $selectedTab)
            }
        }
        .tint(customAccentHex.isEmpty ? nil : Color(hex: customAccentHex))
        .tabViewStyle(.sidebarAdaptable)
        .onChange(of: selectedTab) { _, newTab in
            AnalyticsService.shared.capture(.tabSwitched, properties: [
                "tab": String(describing: newTab)
            ])
        }
        .onReceive(NotificationCenter.default.publisher(for: .devotionalReminderTapped)) { _ in
            selectedTab = .dailyDevotional
        }
        .onReceive(NotificationCenter.default.publisher(for: .donationStatusShouldRefresh)) { notification in
            guard DonationPreferences.useStripePayments else { return }
            safariCheckout = nil
            let sessionId = notification.userInfo?["session_id"] as? String
            Task { await refreshDonationStatusFromServer(sessionID: sessionId) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .storeKitDonationCompleted)) { notification in
            guard !DonationPreferences.useStripePayments else { return }
            guard let txID = notification.userInfo?["transactionID"] as? String,
                  let productID = notification.userInfo?["productID"] as? String,
                  let amountCents = notification.userInfo?["amountCents"] as? Int,
                  let purchaseDate = notification.userInfo?["purchaseDate"] as? Date else { return }
            let record = LocalDonationRecord(
                transactionID: txID, productID: productID,
                amountCents: amountCents, currency: "USD",
                purchaseDate: purchaseDate
            )
            modelContext.insert(record)
            try? modelContext.save()
            appViewModel.totalPaidCents += amountCents
            hasCompletedDonation = true
            if !isAppLaunching { confettiTrigger += 1 }

            // Sync to Supabase so donation history is complete
            let anonId = donationAnonIdentifier
            Task {
                try? await DonationService.shared.recordStoreKitDonation(
                    transactionId: txID,
                    productId: productID,
                    amountCents: amountCents,
                    currency: "USD",
                    purchaseDate: purchaseDate,
                    anonymousId: anonId
                )
                await refreshDonationStatusFromServer()
            }
        }
        .onChange(of: appViewModel.donationFlowRequest) { _, request in
            guard let request else { return }
            startDonationFlow(
                amount: request.amount,
                currency: request.currency,
                source: request.source
            )
            appViewModel.donationFlowRequest = nil
        }
        .onChange(of: appViewModel.shouldTriggerConfetti) { _, shouldTrigger in
            if shouldTrigger {
                print("🎊 TEST: ContentView received confetti trigger signal")
                confettiTrigger += 1
                appViewModel.shouldTriggerConfetti = false
            }
        }
        .onAppear {
            ensureDonationAnonIdentifier()
            if let localeCurrency = Locale.current.currency?.identifier {
                donationCurrency = localeCurrency.uppercased()
            }

            // Wire up App Intent navigation
            AppIntentNavigator.shared.onNavigateToBook = { bookName in
                selectedTab = .bible
                appViewModel.navigateToVerse(bookName: bookName, chapterNumber: 1, verseNumber: 1)
            }
            AppIntentNavigator.shared.onNavigateToSearch = { _ in
                selectedTab = .search
            }
            AppIntentNavigator.shared.onNavigateToVerse = { bookName, chapter, verse in
                selectedTab = .bible
                appViewModel.navigateToVerse(bookName: bookName, chapterNumber: chapter, verseNumber: verse)
            }

            Task {
                await SupabaseService.shared.ensureSession()
                userViewModel.user = await SupabaseService.shared.getUser()
                await userViewModel.fetchAdminStatus()

                // Always check Supabase for existing Stripe donations
                // so previous Stripe donors are still recognized
                await refreshDonationStatusFromServer()

                if DonationPreferences.useStripePayments {
                    // Stripe mode: server status already refreshed above
                } else {
                    await StoreKitDonationService.shared.loadProducts()
                    transactionListenerTask = StoreKitDonationService.shared.listenForTransactions()
                    await MainActor.run { loadLocalDonationHistory() }
                }

                evaluateDonationPrompt()
                await refreshDevotionalReminders()

                // Mark app as no longer launching after initial load
                await MainActor.run {
                    isAppLaunching = false
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
            if newPhase == .active {
                Task { await refreshDevotionalReminders() }
            }
        }
        .onChange(of: donationPromptOptOut) { _, newValue in
            if newValue {
                showDonationPrompt = false
            } else {
                evaluateDonationPrompt()
            }
        }
        .onChange(of: showDonationPrompt) { _, shown in
            if shown {
                AnalyticsService.shared.capture(.donationPromptShown, properties: [
                    "variant": donationVariant.rawValue
                ])
            } else {
                AnalyticsService.shared.capture(.donationPromptDismissed, properties: [
                    "variant": donationVariant.rawValue
                ])
            }
        }
        .sheet(isPresented: $showDonationPrompt) {
            DonationPromptContainer(
                isPresented: $showDonationPrompt,
                currencyCode: donationCurrency,
                variant: donationVariant
            ) { amount in
                startDonationFlow(
                    amount: amount,
                    currency: donationCurrency,
                    source: "prompt"
                )
            }
            .environment(appViewModel)
            .presentationDetents([.height(900), .large])
            .presentationDragIndicator(.visible)
        }
        .alert("Donation", isPresented: $showDonationErrorAlert, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(donationErrorMessage ?? "Something went wrong. Please try again.")
        })
        .fullScreenCover(item: $safariCheckout) { item in
            SafariContainer(url: item.url)
                .ignoresSafeArea()
                .onDisappear {
                    Task {
                        // Immediate check
                        await refreshDonationStatusFromServer()

                        // Delayed checks to catch processing donations
                        for delay in [1.0, 2.0, 4.0] {
                            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                            await refreshDonationStatusFromServer()
                        }
                    }
                }
        }
        .overlay {
            ZStack {
                if showDonationCelebration {
                    DonationCelebrationView()
                }
            }
        }
        .environment(appViewModel)
        .environment(userViewModel)
        .confettiCannon(
            trigger: $confettiTrigger,
            num: 50,
            confettis: [.text("📖"), .text("📚"), .text("✝️"), .text("🙏"), .text("❤️"), .text("✨")],
            confettiSize: 30,
            radius: 500,
            repetitions: 2,
            repetitionInterval: 0.3
        )
    }

    private func evaluateDonationPrompt() {
        guard !donationPromptOptOut else { return }
        appViewModel.donationVariant = DonationPromptVariant.fromPostHog()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            showDonationPrompt = true
        }
    }

    private func startDonationFlow(amount: Decimal, currency: String, source: String) {
        if DonationPreferences.useStripePayments {
            startStripeDonationFlow(amount: amount, currency: currency, source: source)
        } else {
            startStoreKitDonationFlow(amount: amount, source: source)
        }
    }

    // MARK: - StoreKit IAP Donation Flow

    private func startStoreKitDonationFlow(amount: Decimal, source: String) {
        showDonationPrompt = false
        showDonationCelebration = true

        AnalyticsService.shared.capture(.donationStarted, properties: [
            "amount": "\(amount)",
            "source": source,
            "variant": donationVariant.rawValue,
            "payment_method": "storekit"
        ])

        Task {
            do {
                let transaction = try await StoreKitDonationService.shared.purchase(amount: amount)
                await MainActor.run {
                    recordStoreKitDonation(transaction)
                    confettiTrigger += 1
                    hasCompletedDonation = true
                    donationPromptOptOut = true
                    showDonationCelebration = false

                    AnalyticsService.shared.capture(.donationCompleted, properties: [
                        "amount_cents": StoreKitDonationService.shared.amountCents(for: transaction.productID),
                        "product_id": transaction.productID,
                        "payment_method": "storekit"
                    ])
                }
            } catch let error as StoreKitDonationError where error == .userCancelled {
                await MainActor.run { showDonationCelebration = false }
            } catch {
                await MainActor.run {
                    showDonationCelebration = false
                    presentDonationError(error)
                }
            }
        }
    }

    @MainActor
    private func recordStoreKitDonation(_ transaction: StoreKit.Transaction) {
        let amountCents = StoreKitDonationService.shared.amountCents(for: transaction.productID)
        let txID = String(transaction.id)
        let currency = transaction.currency?.identifier ?? "USD"
        let record = LocalDonationRecord(
            transactionID: txID,
            productID: transaction.productID,
            amountCents: amountCents,
            currency: currency,
            purchaseDate: transaction.purchaseDate
        )
        modelContext.insert(record)
        try? modelContext.save()

        // Update AppViewModel
        appViewModel.totalPaidCents += amountCents

        // Sync to Supabase
        let anonId = donationAnonIdentifier
        let purchaseDate = transaction.purchaseDate
        let productID = transaction.productID
        Task {
            try? await DonationService.shared.recordStoreKitDonation(
                transactionId: txID,
                productId: productID,
                amountCents: amountCents,
                currency: currency,
                purchaseDate: purchaseDate,
                anonymousId: anonId
            )
            await refreshDonationStatusFromServer()
        }
    }

    @MainActor
    private func loadLocalDonationHistory() {
        // Local SwiftData records are now synced to Supabase, so the server
        // total from refreshDonationStatusFromServer() already includes them.
        // Only use local records as a fallback if the server returned nothing.
        guard appViewModel.totalPaidCents == 0 else { return }

        let descriptor = FetchDescriptor<LocalDonationRecord>(
            sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]
        )
        if let records = try? modelContext.fetch(descriptor) {
            let localTotal = records.reduce(0) { $0 + $1.amountCents }
            appViewModel.totalPaidCents = localTotal
        }
    }

    // MARK: - Stripe Donation Flow (preserved for future use)

    private func startStripeDonationFlow(amount: Decimal, currency: String, source: String) {
        guard !isCreatingDonationSession else { return }

        let sanitizedAmount = amount
        let sanitizedCurrency = currency.uppercased()
        donationCurrency = sanitizedCurrency

        showDonationPrompt = false
        showDonationCelebration = true
        donationFlowActive = true
        waitingForDonationReturn = false
        isCreatingDonationSession = true

        AnalyticsService.shared.capture(.donationStarted, properties: [
            "amount": "\(sanitizedAmount)",
            "currency": sanitizedCurrency,
            "source": source,
            "variant": donationVariant.rawValue
        ])

        Task {
            do {
                let response = try await DonationService.shared
                    .createDonationSession(
                        amount: sanitizedAmount,
                        currency: sanitizedCurrency,
                        anonymousId: donationAnonIdentifier,
                        source: source
                    )

                await MainActor.run {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        showDonationCelebration = false
                        openStripeDonation(url: response.sessionURL)
                    }
                }
            } catch {
                await MainActor.run {
                    showDonationCelebration = false
                    donationFlowActive = false
                    waitingForDonationReturn = false
                    presentDonationError(error)
                }
            }

            await MainActor.run {
                isCreatingDonationSession = false
            }
        }
    }

    @MainActor
    private func openStripeDonation(url: URL) {
        safariCheckout = SafariCheckoutItem(url: url)
    }

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        guard donationFlowActive else { return }

        switch newPhase {
        case .inactive, .background:
            waitingForDonationReturn = true
        case .active:
            guard waitingForDonationReturn else { return }
            Task {
                await refreshDonationStatusFromServer()
                await MainActor.run {
                    donationFlowActive = false
                    waitingForDonationReturn = false
                }
            }
        @unknown default:
            break
        }
    }

    private func ensureDonationAnonIdentifier() {
        let keychainKey = "donation_anonymous_identifier"
        let iCloud = NSUbiquitousKeyValueStore.default

        if donationAnonIdentifier.isEmpty {
            // Try recovering from Keychain (survives reinstall)
            if let keychainId = KeychainService.get(keychainKey), !keychainId.isEmpty {
                donationAnonIdentifier = keychainId
                print("🔑 Recovered donation anonymous ID from Keychain: \(keychainId)")
                return
            }

            // Try recovering from iCloud (cross-device sync)
            iCloud.synchronize()
            if let iCloudId = iCloud.string(forKey: keychainKey), !iCloudId.isEmpty {
                donationAnonIdentifier = iCloudId
                KeychainService.set(iCloudId, forKey: keychainKey)
                print("☁️ Recovered donation anonymous ID from iCloud: \(iCloudId)")
                return
            }

            // Generate new ID as last resort
            let newId = UUID().uuidString
            donationAnonIdentifier = newId
            KeychainService.set(newId, forKey: keychainKey)
            iCloud.set(newId, forKey: keychainKey)
            iCloud.synchronize()
            print("🆕 Generated new donation anonymous ID: \(newId)")
        } else {
            // Ensure existing ID is persisted to Keychain + iCloud
            if KeychainService.get(keychainKey) == nil {
                KeychainService.set(donationAnonIdentifier, forKey: keychainKey)
                iCloud.set(donationAnonIdentifier, forKey: keychainKey)
                iCloud.synchronize()
                print("💾 Migrated donation anonymous ID to Keychain + iCloud")
            }
        }
    }

    private func refreshDonationStatusFromServer(sessionID: String? = nil) async {
        guard !donationAnonIdentifier.isEmpty else {
            print("🔴 No anonymous identifier - skipping refresh")
            return
        }

        print("🔄 Refreshing donation status - sessionID: \(sessionID ?? "none"), anonymousId: \(donationAnonIdentifier)")

        do {
            async let statusTask = DonationService.shared
                .fetchDonationStatus(
                    anonymousId: donationAnonIdentifier,
                    sessionId: sessionID
                )
            async let historyTask = DonationService.shared
                .fetchDonationHistory(anonymousId: donationAnonIdentifier)

            let (status, history) = try await (statusTask, historyTask)

            print("✅ Donation status fetched - hasDonated: \(status.hasDonated), latestSession: \(status.latestDonation?.sessionId ?? "none")")
            print("✅ History - totalPaid: \(history.totalPaidCents), donations: \(history.donations.count)")

            await MainActor.run {
                if let record = status.latestDonation {
                    appViewModel.latestDonation = DonationSummary(
                        sessionId: record.sessionId,
                        amountCents: record.amountCents,
                        currency: record.currency,
                        createdAt: record.createdAt
                    )
                } else {
                    appViewModel.latestDonation = nil
                }

                appViewModel.totalPaidCents = history.totalPaidCents
                appViewModel.totalRefundedCents = history.totalRefundedCents
                appViewModel.donationHistory = history.donations

                updateDonationFlags(
                    hasDonated: status.hasDonated,
                    latestDonation: status.latestDonation
                )
            }
        } catch {
            print("🔴 Failed to refresh donation status: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func updateDonationFlags(hasDonated: Bool, latestDonation: DonationRecord?) {
        print("🎯 updateDonationFlags called - hasDonated: \(hasDonated), latestSession: \(latestDonation?.sessionId ?? "none")")

        if hasDonated {
            let wasCompleted = hasCompletedDonation
            let previousSession = lastCelebratedDonationSessionID
            let latestSession = latestDonation?.sessionId ?? ""

            print("🎯 Previous completed: \(wasCompleted), Previous session: \(previousSession), Latest session: \(latestSession)")

            hasCompletedDonation = true
            donationPromptOptOut = true  // Disable popup after donation
            showDonationPrompt = false

            var shouldCelebrate = false

            if !latestSession.isEmpty {
                shouldCelebrate = latestSession != previousSession
                print("🎯 Session comparison - should celebrate: \(shouldCelebrate)")
                if shouldCelebrate {
                    lastCelebratedDonationSessionID = latestSession
                }
            } else if !wasCompleted || previousSession.isEmpty {
                shouldCelebrate = true
                print("🎯 First donation or no previous session - should celebrate: \(shouldCelebrate)")
            }

            if shouldCelebrate && !isAppLaunching {
                print("🎉 TRIGGERING CONFETTI! Trigger: \(confettiTrigger) -> \(confettiTrigger + 1)")
                confettiTrigger += 1
                AnalyticsService.shared.capture(.donationCompleted, properties: [
                    "session_id": latestSession,
                    "amount_cents": latestDonation?.amountCents ?? 0,
                    "currency": latestDonation?.currency ?? "unknown"
                ])
            } else if shouldCelebrate && isAppLaunching {
                print("🎯 Would celebrate but app is launching - skipping confetti")
                // Still update the last celebrated session to prevent future triggers
                if !latestSession.isEmpty {
                    lastCelebratedDonationSessionID = latestSession
                }
            } else {
                print("🎯 Not celebrating - confetti conditions not met")
            }
        } else {
            print("🎯 No donation detected - skipping celebration")
        }
    }

    @MainActor
    private func presentDonationError(_ error: Error) {
        if let donationError = error as? DonationServiceError {
            donationErrorMessage = donationError.errorDescription
        } else if let localized = error as? LocalizedError,
                  let description = localized.errorDescription {
            donationErrorMessage = description
        } else {
            donationErrorMessage = error.localizedDescription
        }
        showDonationErrorAlert = true
    }

    /// Prefetch today's devotional and reschedule the notification with fresh content.
    private func refreshDevotionalReminders() async {
        let enabled = UserDefaults.standard.bool(forKey: "devotionalReminderEnabled")
        guard enabled else { return }

        // Prefetch today's devotional so the notification has real content
        let today = Date()
        if CacheService.shared.loadDevotional(for: today) == nil {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: today)

            do {
                let devotional: DailyDevotional = try await SupabaseService.shared.client
                    .from("Daily Devotional")
                    .select()
                    .eq("for_date", value: dateString)
                    .single()
                    .execute()
                    .value
                CacheService.shared.saveDevotional(devotional, for: today)
                CacheService.shared.syncDevotionalToWidget(devotional, for: today)
            } catch {
                // No devotional for today yet — notification will use generic message
            }
        }

        let hour = UserDefaults.standard.integer(forKey: "devotionalReminderHour")
        let minute = UserDefaults.standard.integer(forKey: "devotionalReminderMinute")

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        guard let time = Calendar.current.date(from: components) else { return }

        await NotificationService.shared.scheduleDailyReminder(at: time)
    }

}
