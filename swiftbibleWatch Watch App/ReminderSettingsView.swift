import SwiftUI

struct ReminderSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var enabled: Bool = ReminderScheduler.isEnabled
    @State private var time: Date = {
        var comps = DateComponents()
        comps.hour = ReminderScheduler.hour
        comps.minute = ReminderScheduler.minute
        return Calendar.current.date(from: comps) ?? Date()
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Daily reminder", isOn: $enabled)
                    if enabled {
                        DatePicker(
                            "Time",
                            selection: $time,
                            displayedComponents: .hourAndMinute
                        )
                    }
                } footer: {
                    Text("Taps your wrist each day with a haptic nudge to read the devotional.")
                }
            }
            .navigationTitle("Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        apply()
                        dismiss()
                    }
                }
            }
        }
    }

    private func apply() {
        if enabled {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
            ReminderScheduler.schedule(
                hour: comps.hour ?? 8,
                minute: comps.minute ?? 0
            )
        } else {
            ReminderScheduler.cancel()
        }
    }
}

#Preview {
    ReminderSettingsView()
}
