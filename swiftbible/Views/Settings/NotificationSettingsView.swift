//
//  NotificationSettingsView.swift
//  swiftbible
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @AppStorage("devotionalReminderEnabled") private var reminderEnabled = false
    @AppStorage("devotionalReminderHour") private var reminderHour: Int = 21
    @AppStorage("devotionalReminderMinute") private var reminderMinute: Int = 0

    @State private var selectedTime: Date = Date()
    @State private var permissionDenied = false
    @State private var justEnabled = false

    var body: some View {
        List {
            // Hero header — Halo Effect (#64) + Aesthetic-Usability (#122)
            Section {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange.opacity(0.2), .yellow.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: reminderEnabled ? "bell.badge.fill" : "bell.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolEffect(.bounce, value: justEnabled)
                    }

                    // Gain Framing (#53) — lead with the benefit
                    Text("Never miss your daily reflection")
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)

                    Text("A gentle reminder each day to pause, reflect, and grow in scripture.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }

            // Main toggle + time picker
            Section {
                Toggle(isOn: $reminderEnabled) {
                    Label("Daily Reminder", systemImage: "bell.circle.fill")
                }
                .onChange(of: reminderEnabled) { _, newValue in
                    AnalyticsService.shared.capture(.devotionalReminderToggled, properties: ["enabled": newValue])
                    if newValue {
                        withAnimation { justEnabled = true }
                        scheduleNotification()
                        // Reset bounce after animation — Feedback Loops (#104)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            justEnabled = false
                        }
                    } else {
                        NotificationService.shared.cancelDailyReminder()
                    }
                }

                if reminderEnabled {
                    DatePicker(
                        "Time",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .onChange(of: selectedTime) { _, newValue in
                        let calendar = Calendar.current
                        reminderHour = calendar.component(.hour, from: newValue)
                        reminderMinute = calendar.component(.minute, from: newValue)
                        scheduleNotification()
                    }

                    // Cognitive Ease (#20) — quick presets reduce friction
                    HStack(spacing: 12) {
                        TimePresetButton(label: "Morning", hour: 7, minute: 0,
                                         selectedTime: $selectedTime,
                                         reminderHour: $reminderHour,
                                         reminderMinute: $reminderMinute,
                                         onSelect: scheduleNotification)
                        TimePresetButton(label: "Midday", hour: 12, minute: 0,
                                         selectedTime: $selectedTime,
                                         reminderHour: $reminderHour,
                                         reminderMinute: $reminderMinute,
                                         onSelect: scheduleNotification)
                        TimePresetButton(label: "Evening", hour: 21, minute: 0,
                                         selectedTime: $selectedTime,
                                         reminderHour: $reminderHour,
                                         reminderMinute: $reminderMinute,
                                         onSelect: scheduleNotification)
                    }
                    .padding(.vertical, 4)
                }
            } footer: {
                if reminderEnabled {
                    // Confirmation feedback — Feedback Loops (#104)
                    Label("Scheduled daily at \(formattedTime)", systemImage: "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.green)
                }
            }

            // Permission denied warning
            if permissionDenied {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notifications Disabled")
                                .font(.subheadline.weight(.semibold))
                            Text("Enable notifications in your device settings to receive reminders.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Button("Open") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
            }

            // Developer note — Product-Person Bias (#83) + Tiny Habits (#114)
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("How it works", systemImage: "sparkles")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text("Each day, a new devotional is generated from scripture. Set a reminder to build it into your routine — even a few minutes of daily reflection adds up.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Divider()

                    // Personal note styled as a warm quote callout
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.orange.opacity(0.6))
                            .frame(width: 3)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("I like to read the daily devotional before bed during my wind-down routine. It's a nice way to reflect on the day and settle in with something meaningful.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .italic()
                                .fixedSize(horizontal: false, vertical: true)

                            Text("— Adam, developer")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            #if DEBUG
            Section(header: Text("Debug")) {
                Button {
                    sendTestNotification()
                } label: {
                    HStack {
                        Label("Send Test Notification Now", systemImage: "bell.badge")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
            }
            #endif
        }
        .navigationTitle("Devotional Reminder")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            var components = DateComponents()
            components.hour = reminderHour
            components.minute = reminderMinute
            if let date = Calendar.current.date(from: components) {
                selectedTime = date
            }

            checkNotificationPermission()
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: selectedTime)
    }

    private func scheduleNotification() {
        Task {
            let granted = await NotificationService.shared.requestAuthorization()
            await MainActor.run {
                permissionDenied = !granted
            }
            if granted {
                await NotificationService.shared.scheduleDailyReminder(at: selectedTime)
            } else {
                await MainActor.run {
                    reminderEnabled = false
                }
            }
        }
    }

    #if DEBUG
    private func sendTestNotification() {
        Task {
            let granted = await NotificationService.shared.requestAuthorization()
            guard granted else {
                await MainActor.run { permissionDenied = true }
                return
            }

            let content = NotificationService.shared.buildContent(for: Date())
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "test-devotional-reminder",
                content: content,
                trigger: trigger
            )

            try? await UNUserNotificationCenter.current().add(request)
        }
    }
    #endif

    private func checkNotificationPermission() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                permissionDenied = reminderEnabled && settings.authorizationStatus == .denied
            }
        }
    }
}

// Cognitive Ease (#20) — one-tap time presets
private struct TimePresetButton: View {
    let label: String
    let hour: Int
    let minute: Int
    @Binding var selectedTime: Date
    @Binding var reminderHour: Int
    @Binding var reminderMinute: Int
    let onSelect: () -> Void

    private var isSelected: Bool {
        reminderHour == hour && reminderMinute == minute
    }

    var body: some View {
        Button {
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            if let date = Calendar.current.date(from: components) {
                selectedTime = date
                reminderHour = hour
                reminderMinute = minute
                onSelect()
            }
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.tertiarySystemFill))
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.accentColor.opacity(0.4) : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
