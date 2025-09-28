//
//  ContentView.swift
//  swiftbible
//
//  Created on 9/6/24.
//

import SwiftUI
import SwiftData
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

    @Environment(\.scenePhase) private var scenePhase

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

    @AppStorage("lastCelebratedDonationSessionID") private var lastCelebratedDonationSessionID: String = ""

    var body: some View {
        @Bindable var appViewModel = appViewModel

        TabView(selection: $selectedTab) {
            Tab("Bible", systemImage: "book.fill", value: .bible) {
                BibleView()
            }

            Tab("Devotional", systemImage: "sun.horizon.fill", value: .dailyDevotional) {
                DailyDevotionalView()
            }

            Tab("Search", systemImage: "magnifyingglass", value: .search, role: .search) {
                SearchDetailView(selectedTab: $selectedTab)
            }

            Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                SettingsView(selectedTab: $selectedTab)
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .onReceive(NotificationCenter.default.publisher(for: .donationStatusShouldRefresh)) { notification in
            safariCheckout = nil
            let sessionId = notification.userInfo?["session_id"] as? String
            Task { await refreshDonationStatusFromServer(sessionID: sessionId) }
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

            Task {
                await SupabaseService.shared.refreshToken()
                userViewModel.user = await SupabaseService.shared.getUser()
                await refreshDonationStatusFromServer()
                evaluateDonationPrompt()

                // Mark app as no longer launching after initial load
                await MainActor.run {
                    isAppLaunching = false
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onChange(of: donationPromptOptOut) { _, newValue in
            if newValue {
                showDonationPrompt = false
            } else {
                evaluateDonationPrompt()
            }
        }
        .sheet(isPresented: $showDonationPrompt) {
            DonationPromptView(
                isPresented: $showDonationPrompt,
                currencyCode: donationCurrency
            ) { amount in
                startDonationFlow(
                    amount: amount,
                    currency: donationCurrency,
                    source: "prompt"
                )
            }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showDonationPrompt = true
        }
    }

    private func startDonationFlow(amount: Decimal, currency: String, source: String) {
        guard !isCreatingDonationSession else { return }

        let sanitizedAmount = amount
        let sanitizedCurrency = currency.uppercased()
        donationCurrency = sanitizedCurrency

        showDonationPrompt = false
        showDonationCelebration = true
        donationFlowActive = true
        waitingForDonationReturn = false
        isCreatingDonationSession = true

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
        if donationAnonIdentifier.isEmpty {
            donationAnonIdentifier = UUID().uuidString
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

}
