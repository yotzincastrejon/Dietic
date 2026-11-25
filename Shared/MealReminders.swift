import SwiftUI
import UserNotifications

private struct MealReminder: Identifiable {
    let meal: EatingTime
    var enabled: Bool
    var time: Date
    var id: String { "dietic.reminder." + meal.description.lowercased() }

    static func defaults(calendar: Calendar = .current) -> [Self] {
        zip([EatingTime.breakfast, .lunch, .dinner, .snack], [8, 12, 18, 15]).map { meal, hour in
            Self(meal: meal, enabled: false, time: calendar.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now)
        }
    }

    var request: UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Log " + meal.description.lowercased()
        content.body = "Open Dietic to add what you ate."
        content.sound = .default
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }
}

struct MealRemindersView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var phase
    @State private var reminders = MealReminder.defaults()
    @State private var loaded = false
    @State private var saving = false
    @State private var denied = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach($reminders) { $reminder in
                        Toggle(reminder.meal.description, isOn: $reminder.enabled)
                        if reminder.enabled {
                            DatePicker("\(reminder.meal.description) time", selection: $reminder.time, displayedComponents: .hourAndMinute)
                        }
                    }
                } footer: { Text("Reminders repeat daily at the local times you choose.") }
                if denied {
                    Section {
                        Link("Open notification settings", destination: URL(string: UIApplication.openNotificationSettingsURLString)!)
                    } footer: { Text("Notifications for Dietic are turned off in Settings.") }
                }
                if let error { Text(error).foregroundStyle(WarmInk.action) }
            }
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .navigationTitle("Meal reminders")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Saving…" : "Save") {
                        guard !saving else { return }
                        saving = true
                        Task { await save() }
                    }
                }
            }
            .disabled(!loaded || saving)
            .task { await load() }
            .onChange(of: phase) { newPhase in
                if newPhase == .active { Task { denied = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .denied } }
            }
        }.interactiveDismissDisabled(saving).preferredColorScheme(.light).tint(WarmInk.action)
    }

    @MainActor private func load() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let calendar = Calendar.current
        for i in reminders.indices {
            guard let match = pending.first(where: { $0.identifier == reminders[i].id }),
                  let trigger = match.trigger as? UNCalendarNotificationTrigger,
                  let hour = trigger.dateComponents.hour, let minute = trigger.dateComponents.minute,
                  let time = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: .now) else { continue }
            reminders[i].enabled = true
            reminders[i].time = time
        }
        denied = await center.notificationSettings().authorizationStatus == .denied
        loaded = true
    }

    @MainActor private func save() async {
        defer { saving = false }
        let center = UNUserNotificationCenter.current()
        do {
            if reminders.contains(where: \.enabled) {
                guard try await center.requestAuthorization(options: [.alert, .sound]) else {
                    denied = true
                    return
                }
            }
            for reminder in reminders where reminder.enabled { try await center.add(reminder.request) }
            center.removePendingNotificationRequests(withIdentifiers: reminders.filter { !$0.enabled }.map(\.id))
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
