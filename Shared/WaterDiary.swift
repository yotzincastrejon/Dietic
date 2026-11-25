import SwiftUI
import HealthKit

enum WaterUnit: String, CaseIterable, Sendable {
    case ounces = "US fl oz"
    case milliliters = "mL"

    var healthUnit: HKUnit { self == .ounces ? .fluidOunceUS() : .literUnit(with: .milli) }
    var presets: [Int] { self == .ounces ? [8, 12, 16] : [250, 350, 500] }

    func format(_ quantity: HKQuantity) -> String {
        quantity.doubleValue(for: healthUnit).formatted(.number.precision(.fractionLength(0...1))) + " " + rawValue
    }
}

enum DieticWater {
    static let entryKey = "Dietic Water Entry"

    static func save(_ amount: Double, unit: WaterUnit, at date: Date, in store: HKHealthStore) async throws {
        let sample = HKQuantitySample(type: HKQuantityType(.dietaryWater),
                                      quantity: HKQuantity(unit: unit.healthUnit, doubleValue: amount),
                                      start: date, end: date, metadata: [entryKey: true])
        try await store.save(sample)
    }
}

struct WaterDiaryView: View {
    let manager: FastingManager
    private let day: Date
    private let diaryTimestamp: Date
    private let water = HKQuantityType(.dietaryWater)

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("waterDisplayUnit") private var unit: WaterUnit = Locale.current.measurementSystem == .us ? .ounces : .milliliters
    @State private var amount = ""
    @State private var drinks = [HKQuantitySample]()
    @State private var total: HKQuantity?
    @State private var hasLoaded = false
    @State private var authorizing = false
    @State private var requestedAccess = false
    @State private var canWrite = false
    @State private var saving = false
    @State private var deleting: HKQuantitySample?
    @State private var message: String?
    @State private var readID = UUID()
    @FocusState private var editing: Bool

    init(manager: FastingManager) {
        self.manager = manager
        diaryTimestamp = manager.mealTimestamp
        day = Calendar.current.startOfDay(for: diaryTimestamp)
    }

    private var customAmount: Double? {
        guard let value = PortionInput.decimal(amount), value.isFinite, value > 0 else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                JournalHeading(title: "Water", subtitle: day.formatted(date: .complete, time: .omitted))
                VStack(alignment: .leading, spacing: 18) {
                    summary
                    if canWrite { entryForm }
                    if !drinks.isEmpty { drinkHistory }
                }.padding(20)
            }.scrollDismissesKeyboard(.interactively).journalPage()
            .refreshable { await authorizeAndRead() }
            .disabled(saving)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.disabled(saving) }
            }
        }
        .preferredColorScheme(.light)
        .interactiveDismissDisabled(saving)
        .task { await authorizeAndRead() }
        .onChange(of: scenePhase) {
            if $0 == .active, requestedAccess, !authorizing, !saving {
                Task { await read() }
            }
        }
        .alert("Remove this drink?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
               presenting: deleting) { drink in
            Button("Remove", role: .destructive) { Task { await remove(drink) } }
            Button("Cancel", role: .cancel) {}
        } message: { drink in Text(unit.format(drink.quantity) + " will be removed from Health.") }
    }


    @ViewBuilder private var summary: some View {
        HStack {
            Text("Daily total").font(.headline)
            Spacer()
            Picker("Water unit", selection: Binding(get: { unit }, set: changeUnit)) {
                ForEach(WaterUnit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented).frame(maxWidth: 168)
        }
        if let total {
            Text(unit.format(total)).font(.system(.largeTitle, design: .serif).weight(.semibold))
                .accessibilityLabel("Daily total, " + unit.format(total))
        } else if hasLoaded {
            Text("No water data available for this day.").font(.subheadline).foregroundStyle(WarmInk.muted)
        } else if message == nil {
            ProgressView("Reading Health…")
        }
        if let message { Text(message).font(.callout).foregroundStyle(WarmInk.muted) }
        if requestedAccess && !canWrite {
            Text("Allow Dietic to write Water in Health to log a drink.").font(.callout)
        }
    }

    @ViewBuilder private var entryForm: some View {
        Divider()
        Text("Add water").font(.system(.title2, design: .serif))
        HStack(spacing: 8) {
            ForEach(unit.presets, id: \.self) { size in
                Button {
                    Task { await add(Double(size), unit: unit) }
                } label: {
                    Text("\(size) \(unit.rawValue)").font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(WarmInk.apricot.opacity(0.26), in: Capsule())
                }.accessibilityLabel("Add \(size) \(unit.rawValue)")
            }
        }
        HStack {
            TextField("Custom amount", text: $amount).keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder).focused($editing)
            Text(unit.rawValue).foregroundStyle(WarmInk.muted)
            Button("Add") {
                if let value = customAmount { Task { await add(value, unit: unit) } }
            }.buttonStyle(.borderedProminent).disabled(customAmount == nil)
        }
    }

    @ViewBuilder private var drinkHistory: some View {
        Divider()
        Text("Logged in Dietic").font(.system(.title2, design: .serif))
        ForEach(drinks, id: \.uuid) { drink in
            HStack {
                Image(systemName: "drop").foregroundStyle(WarmInk.action)
                Text(unit.format(drink.quantity)).font(.body.weight(.medium))
                Spacer()
                Text(drink.startDate.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline).foregroundStyle(WarmInk.muted)
                if canWrite {
                    Button { deleting = drink } label: {
                        Image(systemName: "trash").frame(width: 44, height: 44)
                    }.accessibilityLabel("Remove " + unit.format(drink.quantity))
                }
            }
        }
    }

    private func changeUnit(_ next: WaterUnit) {
        guard unit != next else { return }
        if let customAmount {
            let quantity = HKQuantity(unit: unit.healthUnit, doubleValue: customAmount)
            amount = quantity.doubleValue(for: next.healthUnit).formatted(.number.grouping(.never).precision(.fractionLength(0...3)))
        }
        unit = next
    }

    @MainActor private func authorizeAndRead() async {
        guard !authorizing else { return }
        guard HKHealthStore.isHealthDataAvailable() else { message = "Health is unavailable on this device."; return }
        authorizing = true
        defer { authorizing = false }
        do {
            try await manager.healthStore.requestAuthorization(toShare: [water], read: [water])
            requestedAccess = true
            await read()
        } catch { message = error.localizedDescription }
    }

    @MainActor private func read() async {
        let token = UUID()
        readID = token
        let store = manager.healthStore
        canWrite = store.authorizationStatus(for: water) == .sharingAuthorized
        guard let dayInterval = Calendar.current.dateInterval(of: .day, for: day) else { return }
        let period = HKQuery.predicateForSamples(withStart: dayInterval.start, end: dayInterval.end, options: .strictStartDate)
        let own = NSCompoundPredicate(andPredicateWithSubpredicates: [
            period, HKQuery.predicateForObjects(from: .default()),
            HKQuery.predicateForObjects(withMetadataKey: DieticWater.entryKey)
        ])
        let totalQuery = HKStatisticsQueryDescriptor(predicate: .quantitySample(type: water, predicate: period), options: .cumulativeSum)
        let entriesQuery = HKSampleQueryDescriptor(predicates: [.quantitySample(type: water, predicate: own)],
                                                   sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)])
        do {
            async let records = entriesQuery.result(for: store)
            let result: HKStatistics?
            do { result = try await totalQuery.result(for: store) }
            catch let error as HKError where error.code == .errorNoData { result = nil }
            let entries = try await records
            guard token == readID, !Task.isCancelled else { return }
            total = result?.sumQuantity()
            drinks = entries
            hasLoaded = true
            message = nil
        } catch {
            if token == readID, !Task.isCancelled { message = error.localizedDescription }
        }
    }

    @MainActor private func add(_ value: Double, unit: WaterUnit) async {
        guard canWrite, !saving, value.isFinite, value > 0 else { return }
        saving = true
        defer { saving = false }
        let timestamp = Calendar.current.isDateInToday(day) ? Date() : diaryTimestamp
        do {
            try await DieticWater.save(value, unit: unit, at: timestamp, in: manager.healthStore)
            editing = false
            amount = ""
            await read()
        } catch { message = error.localizedDescription }
    }

    @MainActor private func remove(_ drink: HKQuantitySample) async {
        guard !saving, drinks.contains(where: { $0.uuid == drink.uuid }) else { return }
        saving = true
        defer { saving = false }
        do {
            try await manager.healthStore.delete(drink)
            await read()
        } catch { message = error.localizedDescription }
    }
}
