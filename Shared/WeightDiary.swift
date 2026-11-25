import SwiftUI
import HealthKit
import Charts

private enum WeightUnit: String, CaseIterable {
    case pounds = "lb"
    case kilograms = "kg"
    var healthUnit: HKUnit { self == .pounds ? .pound() : .gramUnit(with: .kilo) }
    func display(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2))) + " " + rawValue
    }
}

struct WeightDiaryView: View {
    let manager: FastingManager
    private let diaryDay: Date
    private let diaryTimestamp: Date
    private let bodyMass = HKQuantityType(.bodyMass)
    private let entryKey = "Dietic Weigh-In"

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("weightDiaryUnit") private var unit: WeightUnit = Locale.current.measurementSystem == .us ? .pounds : .kilograms
    @State private var endDay: Date
    @State private var samples: [HKQuantitySample] = []
    @State private var value = ""
    @State private var loading = true
    @State private var saving = false
    @State private var requestID = UUID()
    @State private var message: String?
    @State private var deleting: HKQuantitySample?
    @FocusState private var editing: Bool

    init(manager: FastingManager) {
        self.manager = manager
        diaryTimestamp = manager.mealTimestamp
        let day = Calendar.current.startOfDay(for: diaryTimestamp)
        diaryDay = day
        _endDay = State(initialValue: day)
    }

    private var startDay: Date {
        Calendar.current.date(byAdding: .day, value: -29, to: endDay) ?? endDay
    }

    private var validValue: Double? {
        guard let number = PortionInput.decimal(value), number.isFinite, number > 0 else { return nil }
        return number
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                JournalHeading(title: "Weight journal", subtitle: diaryDay.formatted(date: .complete, time: .omitted))
                VStack(alignment: .leading, spacing: 18) {
                    if endDay == diaryDay { entryForm; Divider() }
                    rangeNavigation
                    if loading { ProgressView("Reading Health…") }
                    if let message { Text(message).foregroundStyle(WarmInk.muted).font(.callout) }
                    if !loading {
                        if samples.isEmpty {
                            Text("No weigh-ins available for this period.").font(.callout).foregroundStyle(WarmInk.muted)
                        } else {
                            trend
                            weeklyChange
                            Divider()
                            history
                        }
                    }
                }.padding(20)
            }.scrollDismissesKeyboard(.interactively).journalPage()
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.disabled(saving) } }
        }
        .preferredColorScheme(.light).interactiveDismissDisabled(saving)
        .task(id: requestID) { await read() }
        .onChange(of: scenePhase) { if $0 == .active, !saving { requestID = UUID() } }
        .alert("Remove this weigh-in?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
               presenting: deleting) { sample in
            Button("Remove", role: .destructive) { Task { await remove(sample) } }
            Button("Cancel", role: .cancel) {}
        } message: { sample in Text(formatted(sample) + " will be removed from Health.") }
    }

    private var entryForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Log a weigh-in").font(.system(.title2, design: .serif))
                Spacer()
                Picker("Weight unit", selection: Binding(get: { unit }, set: changeUnit)) {
                    ForEach(WeightUnit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented).frame(maxWidth: 120)
            }
            HStack {
                TextField("Weight", text: $value).textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad).focused($editing)
                Text(unit.rawValue).foregroundStyle(WarmInk.muted)
                Button("Save weigh-in") {
                    if let validValue { Task { await log(validValue, unit: unit) } }
                }.buttonStyle(.borderedProminent).disabled(validValue == nil)
            }
        }.disabled(saving)
    }

    private var rangeNavigation: some View {
        HStack {
            Button { shift(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                .accessibilityLabel("Previous 30 days")
            Spacer()
            Text(startDay.formatted(.dateTime.month(.abbreviated).day()) + " – " + endDay.formatted(.dateTime.month(.abbreviated).day().year()))
                .font(.subheadline.weight(.medium))
            Spacer()
            Button { shift(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                .accessibilityLabel("Next 30 days").disabled(endDay >= diaryDay)
        }.disabled(saving)
    }

    private func shift(_ direction: Int) {
        guard let next = Calendar.current.date(byAdding: .day, value: direction * 30, to: endDay) else { return }
        endDay = min(next, diaryDay)
        samples = []
        loading = true
        message = nil
        requestID = UUID()
    }

    private var trend: some View {
        let weights = samples.map { $0.quantity.doubleValue(for: unit.healthUnit) }
        let low = weights.min() ?? 0
        let high = weights.max() ?? low
        let padding = max(1, (high - low) * 0.15)
        return Chart(samples.reversed(), id: \.uuid) { sample in
            LineMark(x: .value("Date", sample.startDate),
                     y: .value(unit.rawValue, sample.quantity.doubleValue(for: unit.healthUnit)))
                .foregroundStyle(WarmInk.header)
            PointMark(x: .value("Date", sample.startDate),
                      y: .value(unit.rawValue, sample.quantity.doubleValue(for: unit.healthUnit)))
                .foregroundStyle(WarmInk.action)
        }
        .chartYScale(domain: max(0, low - padding)...(high + padding))
        .chartYAxisLabel(unit.rawValue)
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 3)) { _ in AxisValueLabel(format: .dateTime.month(.abbreviated).day()) } }
        .frame(height: 150)
        .accessibilityLabel("Weight trend in " + unit.rawValue)
    }

    @ViewBuilder private var weeklyChange: some View {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -6, to: endDay) ?? endDay
        let week = samples.filter { $0.startDate >= start }
        if let newest = week.first, let oldest = week.last,
           !calendar.isDate(newest.startDate, inSameDayAs: oldest.startDate) {
            let change = newest.quantity.doubleValue(for: unit.healthUnit) - oldest.quantity.doubleValue(for: unit.healthUnit)
            VStack(alignment: .leading, spacing: 4) {
                LabeledContent("7-day change", value: (change > 0 ? "+" : "") + unit.display(change))
                    .font(.headline)
                Text(oldest.startDate.formatted(.dateTime.month(.abbreviated).day()) + " to " +
                     newest.startDate.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption).foregroundStyle(WarmInk.muted)
            }
        } else {
            Text("7-day change needs weigh-ins on two different days in the last week of this period.")
                .font(.footnote).foregroundStyle(WarmInk.muted)
        }
    }

    @ViewBuilder private var history: some View {
        Text("Weigh-ins").font(.system(.title2, design: .serif))
        ForEach(samples, id: \.uuid) { sample in
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(formatted(sample)).font(.body.weight(.medium))
                    Text(sample.startDate.formatted(date: .abbreviated, time: .shortened) + " · " + sample.sourceRevision.source.name)
                        .font(.caption).foregroundStyle(WarmInk.muted)
                }
                Spacer()
                if canRemove(sample) {
                    Button { deleting = sample } label: { Image(systemName: "trash").frame(width: 44, height: 44) }
                        .accessibilityLabel("Remove " + formatted(sample)).disabled(saving)
                }
            }
        }
    }

    private func canRemove(_ sample: HKQuantitySample) -> Bool {
        sample.sourceRevision.source == HKSource.default() && sample.metadata?[entryKey] as? Bool == true
    }

    private func changeUnit(_ newUnit: WeightUnit) {
        guard unit != newUnit else { return }
        if let number = validValue {
            value = HKQuantity(unit: unit.healthUnit, doubleValue: number).doubleValue(for: newUnit.healthUnit)
                .formatted(.number.grouping(.never).precision(.fractionLength(0...3)))
        }
        unit = newUnit
    }

    private func formatted(_ sample: HKQuantitySample) -> String {
        unit.display(sample.quantity.doubleValue(for: unit.healthUnit))
    }

    @MainActor private func read() async {
        let token = requestID
        guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: endDay) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: startDay, end: nextDay, options: .strictStartDate)
        let query = HKSampleQueryDescriptor(predicates: [.quantitySample(type: bodyMass, predicate: predicate)],
                                            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)])
        do {
            // The diary already requests read access to body mass for historical daily energy.
            let result = try await query.result(for: manager.healthStore)
            guard !Task.isCancelled, requestID == token else { return }
            samples = result.filter { $0.startDate < nextDay }
            loading = false
            message = nil
        } catch {
            guard !Task.isCancelled, requestID == token else { return }
            loading = false
            message = error.localizedDescription
        }
    }

    @MainActor private func log(_ amount: Double, unit: WeightUnit) async {
        guard !saving, amount.isFinite, amount > 0 else { return }
        saving = true
        defer { saving = false }
        let store = manager.healthStore
        do {
            try await store.requestAuthorization(toShare: [bodyMass], read: [bodyMass])
            guard store.authorizationStatus(for: bodyMass) == .sharingAuthorized else {
                message = "Allow Dietic to write Weight in Health to save a weigh-in."
                return
            }
            let time = Calendar.current.isDateInToday(diaryDay) ? Date() : diaryTimestamp
            let sample = HKQuantitySample(type: bodyMass, quantity: HKQuantity(unit: unit.healthUnit, doubleValue: amount),
                                          start: time, end: time, metadata: [entryKey: true])
            try await store.save(sample)
            editing = false
            value = ""
            manager.scheduleDiaryUpdate()
            requestID = UUID()
        } catch { message = error.localizedDescription }
    }

    @MainActor private func remove(_ sample: HKQuantitySample) async {
        guard !saving, canRemove(sample), samples.contains(where: { $0.uuid == sample.uuid }) else { return }
        saving = true
        defer { saving = false }
        do {
            try await manager.healthStore.delete(sample)
            manager.scheduleDiaryUpdate()
            requestID = UUID()
        } catch { message = error.localizedDescription }
    }
}
