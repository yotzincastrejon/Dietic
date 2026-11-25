import SwiftUI

enum MealDateAction: String {
    case copy = "Copy"
    case move = "Move"
}

struct MealDateView: View {
    let action: MealDateAction
    let title: String
    let entries: [HKSampleWithDescription]
    let sourceDay: Date
    let manager: FastingManager

    @Environment(\.dismiss) private var dismiss
    @State private var destination: Date
    @State private var saving = false
    @State private var errorMessage: String?

    init(action: MealDateAction, title: String, entries: [HKSampleWithDescription], sourceDay: Date, manager: FastingManager) {
        self.action = action
        self.title = title
        self.entries = entries
        self.sourceDay = sourceDay
        self.manager = manager
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        _destination = State(initialValue: Calendar.current.isDateInToday(sourceDay) ? yesterday : today)
    }

    var body: some View {
        NavigationStack {
            List {
                Section(action.rawValue + " to") {
                    DatePicker("Destination date", selection: $destination, in: ...Date.now, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                Section("\(title) · \(sourceDay.formatted(date: .abbreviated, time: .omitted))") {
                    ForEach(entries) { item in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.foodName)
                            Text(item.portion.description(quantity: item.numberOfServings,
                                                          measuredInGrams: item.servingSelection == ServingType.gram.description))
                                .font(.caption).foregroundStyle(WarmInk.muted)
                        }
                    }
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(WarmInk.action) }
            }
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .safeAreaInset(edge: .bottom) {
                Button(saving ? "Saving…" : action.rawValue + " to " + destination.formatted(.dateTime.month(.abbreviated).day())) {
                    Task { await apply() }
                }.buttonStyle(JournalActionStyle())
                    .disabled(Calendar.current.isDate(sourceDay, inSameDayAs: destination) || saving)
                    .padding().background(WarmInk.paper)
            }
            .navigationTitle(action.rawValue + (entries.count == 1 ? " entry" : " meal"))
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .disabled(saving)
        }.tint(WarmInk.action).preferredColorScheme(.light).interactiveDismissDisabled(saving)
    }

    @MainActor private func apply() async {
        let calendar = Calendar.current
        guard !saving, !entries.isEmpty, !calendar.isDate(sourceDay, inSameDayAs: destination) else { return }
        saving = true
        defer { saving = false }
        let now = Date()
        let targetDay = calendar.startOfDay(for: destination)
        let sourceStart = calendar.startOfDay(for: sourceDay)
        guard let days = calendar.dateComponents([.day], from: sourceStart, to: targetDay).day else { return }
        func timestamp(_ date: Date) -> Date {
            min(calendar.date(byAdding: .day, value: days, to: date) ?? targetDay, now)
        }
        do {
            switch action {
            case .copy:
                let copies = entries.map { entry in
                    var copy = entry
                    copy.uuid = UUID().uuidString
                    copy.date = timestamp(entry.date)
                    return copy
                }
                try await manager.saveMeals(copies)
            case .move:
                try await manager.moveMeal(entries, from: sourceDay, to: destination, timestamp: timestamp)
            }
            manager.selectDay(destination)
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}
