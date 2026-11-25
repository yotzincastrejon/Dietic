import SwiftUI
import HealthKit

private enum TrendMetric: String, CaseIterable {
    case calories = "Calories"
    case protein = "Protein"
    case carbs = "Carbs"
    case fat = "Fat"
    case balance = "Balance"

    var unit: String { self == .calories || self == .balance ? "kcal" : "g" }
    var quantityUnit: HKUnit { self == .calories || self == .balance ? .kilocalorie() : .gram() }
    var quantityType: HKQuantityType {
        switch self {
        case .calories: return HKQuantityType(.dietaryEnergyConsumed)
        case .protein: return HKQuantityType(.dietaryProtein)
        case .carbs: return HKQuantityType(.dietaryCarbohydrates)
        case .fat: return HKQuantityType(.dietaryFatTotal)
        case .balance: return HKQuantityType(.activeEnergyBurned)
        }
    }

    func display(_ amount: Double?) -> String {
        guard let amount else { return "—" }
        if self == .balance {
            return abs(amount).formatted(.number.precision(.fractionLength(0))) + (amount < 0 ? " kcal surplus" : amount > 0 ? " kcal deficit" : " kcal")
        }
        return amount.formatted(.number.precision(.fractionLength(0))) + " " + unit
    }
}

private struct TrendDay: Identifiable {
    let date: Date
    let values: [TrendMetric: Double]
    var id: Date { date }
}

private struct DiaryWeek {
    let days: [TrendDay]

    func average(_ metric: TrendMetric) -> Double? {
        let amounts = days.compactMap { $0.values[metric] }
        guard !amounts.isEmpty else { return nil }
        return amounts.reduce(0, +) / Double(amounts.count)
    }

    static func dates(ending end: Date, calendar: Calendar = .current) -> [Date] {
        let last = calendar.startOfDay(for: end)
        return (-6...0).compactMap { calendar.date(byAdding: .day, value: $0, to: last) }
    }

    private static func measurements(_ type: HKQuantityTypeIdentifier, start: Date, end: Date,
                                     store: HKHealthStore) async throws -> [HKQuantitySample] {
        let metric = HKQuantityType(type)
        let before = HKQuery.predicateForSamples(withStart: nil, end: start, options: .strictEndDate)
        let period = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let mostRecent = HKSampleQueryDescriptor(predicates: [.quantitySample(type: metric, predicate: before)],
                                                 sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)], limit: 1)
        let updates = HKSampleQueryDescriptor(predicates: [.quantitySample(type: metric, predicate: period)],
                                              sortDescriptors: [SortDescriptor(\.startDate)])
        async let baseline = mostRecent.result(for: store)
        async let changes = updates.result(for: store)
        return try await baseline + changes
    }

    private static func dailyBMRs(_ dates: [Date], end: Date, calendar: Calendar, store: HKHealthStore) async -> [Double?] {
        let unknown = [Double?](repeating: nil, count: dates.count)
        guard let start = dates.first,
              let components = try? store.dateOfBirthComponents(), let birth = calendar.date(from: components),
              let sex = try? store.biologicalSex().biologicalSex, sex == .male || sex == .female else { return unknown }
        do {
            async let readWeight = measurements(.bodyMass, start: start, end: end, store: store)
            async let readHeight = measurements(.height, start: start, end: end, store: store)
            let (weights, heights) = try await (readWeight, readHeight)
            return baselines(dates: dates, calendar: calendar, weights: weights, heights: heights,
                             birth: birth, male: sex == .male)
        } catch { return unknown }
    }

    static func baselines(dates: [Date], calendar: Calendar, weights: [HKQuantitySample],
                          heights: [HKQuantitySample], birth: Date, male: Bool, now: Date = Date()) -> [Double?] {
        dates.map { day in
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { return nil }
            let cutoff = min(next, now)
            guard let pounds = weights.last(where: { $0.startDate < cutoff })?.quantity.doubleValue(for: .pound()),
                  let inches = heights.last(where: { $0.startDate < cutoff })?.quantity.doubleValue(for: .inch()),
                  let age = calendar.dateComponents([.year], from: birth, to: day).year,
                  pounds > 0, inches > 0, age > 0 else { return nil }
            let estimate = FastingManager.basalMetabolicRate(age: age, pounds: pounds, inches: inches, male: male)
            return estimate > 0 ? estimate : nil
        }
    }

    static func deficit(bmr: Double?, active: Double?, consumed: Double?) -> Double? {
        guard let bmr, let active, let consumed else { return nil }
        return bmr + active - consumed
    }

    static func read(ending end: Date, from store: HKHealthStore, calendar: Calendar = .current) async throws -> Self {
        let dates = dates(ending: end, calendar: calendar)
        guard let start = dates.first, let last = dates.last,
              let next = calendar.date(byAdding: .day, value: 1, to: last) else { return Self(days: []) }
        async let readBMRs = dailyBMRs(dates, end: next, calendar: calendar, store: store)
        let interval = DateComponents(calendar: calendar, timeZone: calendar.timeZone, day: 1)
        var values = [[TrendMetric: Double]](repeating: [:], count: dates.count)
        try await withThrowingTaskGroup(of: (TrendMetric, [Double?]).self) { group in
            for metric in TrendMetric.allCases {
                group.addTask {
                    let predicate = HKQuery.predicateForSamples(withStart: start, end: min(Date(), next),
                                                                 options: metric == .balance ? [] : .strictStartDate)
                    let query = HKStatisticsCollectionQueryDescriptor(
                        predicate: .quantitySample(type: metric.quantityType, predicate: predicate),
                        options: .cumulativeSum, anchorDate: start, intervalComponents: interval)
                    do {
                        let result = try await query.result(for: store)
                        return (metric, dates.map { result.statistics(for: $0)?.sumQuantity()?.doubleValue(for: metric.quantityUnit) })
                    } catch where metric == .balance {
                        return (metric, [Double?](repeating: nil, count: dates.count))
                    } catch let error as HKError where [.errorNoData, .errorAuthorizationDenied, .errorAuthorizationNotDetermined].contains(error.code) {
                        return (metric, [Double?](repeating: nil, count: dates.count))
                    }
                }
            }
            for try await (metric, amounts) in group {
                for (index, amount) in amounts.enumerated() { values[index][metric] = amount }
            }
        }
        let bmrs = await readBMRs
        for (index, bmr) in bmrs.enumerated() {
            values[index][.balance] = deficit(bmr: bmr, active: values[index][.balance], consumed: values[index][.calories])
        }
        return Self(days: zip(dates, values).map { TrendDay(date: $0, values: $1) })
    }
}

struct DiaryTrendsView: View {
    let manager: FastingManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var endDate: Date
    @State private var metric: TrendMetric = .calories
    @State private var selectedDate: Date?
    @State private var week: DiaryWeek?
    @State private var error: String?
    @State private var reload = UUID()

    init(manager: FastingManager) {
        self.manager = manager
        _endDate = State(initialValue: Calendar.current.startOfDay(for: manager.todaysDate))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                JournalHeading(title: "Weekly trends")
                VStack(alignment: .leading, spacing: 20) {
                    weekNavigation
                    if let error {
                        Text(error).font(.callout)
                        Button("Try again") { reload = UUID() }
                    } else if let week {
                        Picker("Nutrient", selection: $metric) {
                            ForEach(TrendMetric.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }.pickerStyle(.segmented)
                        let count = week.days.filter { $0.values[metric] != nil }.count
                        VStack(alignment: .leading, spacing: 4) {
                            Text(metric == .balance ? "Average estimated balance" : "Daily average").font(.subheadline).foregroundStyle(WarmInk.muted)
                            Text(metric.display(week.average(metric)))
                                .font(.system(.largeTitle, design: .serif).weight(.medium)).monospacedDigit()
                            Text(count == 0 && metric == .balance ? "No complete days this week." : count == 0 ? "No recorded \(metric.rawValue.lowercased()) this week." :
                                    "Across \(count) recorded \(count == 1 ? "day" : "days")")
                                .font(.footnote).foregroundStyle(WarmInk.muted)
                        }.accessibilityElement(children: .combine)
                        if metric == .balance {
                            Text("Estimated from resting needs, active calories, and logged intake. Days with missing measurements are blank.")
                                .font(.footnote).foregroundStyle(WarmInk.muted)
                        }
                        if let day = week.days.first(where: { $0.date == selectedDate }) ?? week.days.last {
                            chart(week, selected: day.date)
                            Divider()
                            dayDetail(day)
                        }
                    } else {
                        ProgressView("Loading nutrition…").frame(maxWidth: .infinity)
                    }
                }.padding(20)
            }
            .journalPage()
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .preferredColorScheme(.light)
        .task(id: reload) {
            do {
                let result = try await DiaryWeek.read(ending: endDate, from: manager.healthStore)
                try Task.checkCancellation()
                week = result
                error = nil
            } catch {
                if !Task.isCancelled { self.error = error.localizedDescription }
            }
        }
        .onChange(of: scenePhase) { if $0 == .active { reload = UUID() } }
    }

    private var weekNavigation: some View {
        let start = DiaryWeek.dates(ending: endDate).first ?? endDate
        return HStack {
            Button { shiftWeek(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                .accessibilityLabel("Previous week")
            Spacer()
            Text(start.formatted(.dateTime.month(.abbreviated).day()) + " – " +
                 endDate.formatted(.dateTime.month(.abbreviated).day().year()))
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button { shiftWeek(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                .disabled(Calendar.current.isDateInToday(endDate)).accessibilityLabel("Next week")
        }
    }

    private func shiftWeek(_ direction: Int) {
        let calendar = Calendar.current
        guard let end = calendar.date(byAdding: .day, value: 7 * direction, to: endDate) else { return }
        endDate = min(end, calendar.startOfDay(for: .now))
        selectedDate = nil
        week = nil
        error = nil
        reload = UUID()
    }

    private func chart(_ week: DiaryWeek, selected: Date) -> some View {
        let amounts = week.days.compactMap { $0.values[metric] }
        let above = max(0, amounts.max() ?? 0)
        let below = max(0, -(amounts.min() ?? 0))
        let scale = 90 / max(1, above + below)
        let baseline = below * scale
        return HStack(alignment: .bottom, spacing: 4) {
            ForEach(week.days) { day in
                let amount = day.values[metric]
                let isSelected = day.date == selected
                Button {
                    selectedDate = day.date
                } label: {
                    VStack(spacing: 8) {
                        ZStack(alignment: .bottom) {
                            if below > 0 {
                                Rectangle().fill(WarmInk.muted.opacity(0.45)).frame(height: 1).offset(y: -baseline)
                            }
                            if let amount {
                                let height = max(2, abs(amount) * scale)
                                Capsule().fill(isSelected ? WarmInk.header : WarmInk.action.opacity(0.7))
                                    .frame(height: height)
                                    .offset(y: -max(0, amount < 0 ? baseline - height : baseline))
                            } else {
                                Text("—").font(.caption).foregroundStyle(WarmInk.muted).offset(y: -baseline)
                            }
                        }.frame(maxWidth: 24).frame(height: 92, alignment: .bottom)
                        Text(day.date.formatted(.dateTime.weekday(.narrow))).font(.caption.weight(.medium))
                        Text(day.date.formatted(.dateTime.day())).font(.caption2.monospacedDigit())
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(isSelected ? WarmInk.apricot.opacity(0.26) : .clear, in: RoundedRectangle(cornerRadius: 8))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(day.date.formatted(date: .complete, time: .omitted))
                .accessibilityValue(amount == nil ? "No recorded \(metric.rawValue.lowercased())" : metric.display(amount))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    private func dayDetail(_ day: TrendDay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(day.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                .font(.system(.title3, design: .serif).weight(.semibold))
            if day.values.isEmpty {
                Text("No nutrition data for this day.").font(.callout).foregroundStyle(WarmInk.muted)
            } else {
                ForEach(TrendMetric.allCases, id: \.self) { nutrient in
                    LabeledContent(nutrient == .balance ? "Estimated balance" : nutrient.rawValue, value: nutrient.display(day.values[nutrient]))
                        .font(.subheadline.monospacedDigit())
                }
            }
            Button {
                manager.selectDay(day.date)
                dismiss()
            } label: {
                Label("Open day in diary", systemImage: "book")
                    .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
            }
        }
    }
}
