import SwiftUI
import UniformTypeIdentifiers

struct DiaryCSV: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    let text: String

    init(entries: [HKSampleWithDescription]) {
        let date = DateFormatter()
        date.locale = Locale(identifier: "en_US_POSIX")
        date.calendar = Calendar(identifier: .gregorian)
        date.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        var records = [["Date", "Meal", "Food", "Brand", "Portion", "Calories (kcal)", "Protein (g)",
                        "Carbs (g)", "Fat (g)", "Fiber (g)", "Sugar (g)", "Sodium (mg)"]]
        for entry in entries {
            var row = [date.string(from: entry.date), entry.mealPeriod, entry.foodName, entry.brandName,
                       entry.portion.description(quantity: entry.numberOfServings,
                                                 measuredInGrams: entry.servingSelection == ServingType.gram.description)]
            for id in [208, 203, 205, 204, 291, 269, 307] {
                if entry.attrIDArray.contains(id), let path = HKSampleWithDescription.nutrientFields[id] {
                    row.append(String(entry[keyPath: path]))
                } else { row.append("") }
            }
            records.append(row)
        }
        text = records.map { $0.map(Self.cell).joined(separator: ",") }.joined(separator: "\r\n") + "\r\n"
    }

    private static func cell(_ value: String) -> String {
        let first = value.trimmingCharacters(in: .whitespacesAndNewlines).first
        let guarded = first.map { "=+-@".contains($0) } == true ? "'" + value : value
        return "\"" + guarded.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents, let contents = String(data: data, encoding: .utf8)
        else { throw CocoaError(.fileReadCorruptFile) }
        text = contents
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

struct DiaryArchiveView: View {
    let manager: FastingManager
    let endDay: Date
    var repeatMeals = false
    @State private var review: SharedMeal?
    @Environment(\.dismiss) private var dismiss
    @State private var days = 30
    @State private var query = ""
    @State private var entries: [HKSampleWithDescription] = []
    @State private var loading = true
    @State private var error: String?
    @State private var exporting = false
    @State private var csv: DiaryCSV?

    private var matches: [HKSampleWithDescription] {
        let words = query.split(whereSeparator: \.isWhitespace).map(String.init)
        return entries.filter { entry in
            let haystack = [entry.foodName, entry.brandName, entry.mealPeriod].joined(separator: " ")
            return words.allSatisfy { haystack.localizedStandardContains($0) }
        }
    }

    private struct MealGroup: Hashable {
        let day: Date
        let meal: String
    }

    private var mealGroups: [(key: MealGroup, value: [HKSampleWithDescription])] {
        let matching = Set(matches.map(\.uuid))
        return Dictionary(grouping: entries, by: {
            MealGroup(day: Calendar.current.startOfDay(for: $0.date), meal: $0.mealPeriod)
        }).filter { $0.value.contains { matching.contains($0.uuid) } }
          .sorted { ($0.value.first?.date ?? .distantPast) > ($1.value.first?.date ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            let filtered = matches
            List {
                Section {
                    Picker("Days to include", selection: $days) {
                        ForEach([7, 30, 90, 365], id: \.self) { Text($0 == 365 ? "1 year" : "\($0) days").tag($0) }
                    }.pickerStyle(.segmented)
                } footer: {
                    Text("Dietic entries through " + endDay.formatted(date: .abbreviated, time: .omitted))
                }
                if loading { ProgressView("Loading diary…") }
                else if let error { Text(error) }
                else if filtered.isEmpty { Text(query.isEmpty ? "No entries in this period." : "No foods match your search.") }
                else if repeatMeals {
                    ForEach(mealGroups, id: \.key) { group in
                        Button {
                            let items = group.value.sorted { $0.date < $1.date }.map(SharedMeal.Item.init)
                            let period = EatingTime.allCases.first { $0.description == group.key.meal }
                            review = SharedMeal(version: 1, id: UUID(), meal: period?.description ?? "Meal", items: items)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(group.key.meal + " · " + group.key.day.formatted(date: .abbreviated, time: .omitted))
                                    .font(.headline)
                                Text(group.value.map(\.foodName).joined(separator: ", ")).lineLimit(2)
                                    .font(.subheadline).foregroundStyle(WarmInk.muted)
                            }
                        }.accessibilityHint("Choose foods and portions to log again")
                    }
                } else {
                    Section {
                        ForEach(filtered) { entry in
                            Button {
                                manager.selectDay(entry.date)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.foodName).font(.headline)
                                        Text([entry.date.formatted(date: .abbreviated, time: .omitted), entry.mealPeriod,
                                              entry.portion.description(quantity: entry.numberOfServings,
                                                                        measuredInGrams: entry.servingSelection == ServingType.gram.description)].joined(separator: " · "))
                                            .font(.caption).foregroundStyle(WarmInk.muted)
                                    }
                                    Spacer()
                                    Text(entry.attrIDArray.contains(208) ? "\(entry.calories.formatted(.number.precision(.fractionLength(0)))) kcal" : "—").font(.caption)
                                }.foregroundStyle(WarmInk.text)
                            }.accessibilityHint("Opens this diary day")
                        }
                    } header: { Text(filtered.count == 1 ? "1 entry" : "\(filtered.count) entries") }
                }
            }
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .navigationTitle(repeatMeals ? "Repeat a meal" : "Diary history")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Food, brand, or meal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
            .sheet(item: $review) { meal in
                ReceiveMealView(shared: meal, manager: manager, title: "Repeat " + meal.meal.lowercased(),
                                initialDate: Calendar.current.isDateInToday(endDay) ? .now : endDay)
            }
            .safeAreaInset(edge: .bottom) {
                if !repeatMeals {
                Button {
                    csv = DiaryCSV(entries: filtered)
                    exporting = true
                } label: { Label("Export results as CSV", systemImage: "square.and.arrow.up") }
                .buttonStyle(JournalActionStyle()).disabled(loading || filtered.isEmpty)
                .padding(.horizontal).padding(.vertical, 6).background(WarmInk.paper)
                }
            }
            .fileExporter(isPresented: $exporting, document: csv, contentType: .commaSeparatedText,
                          defaultFilename: "Dietic diary") { result in
                if case .failure(let failure) = result { error = failure.localizedDescription }
            }
            .task(id: days) {
                loading = true
                error = nil
                entries = []
                let calendar = Calendar.current
                let last = calendar.startOfDay(for: endDay)
                guard let start = calendar.date(byAdding: .day, value: 1 - days, to: last),
                      let end = calendar.date(byAdding: .day, value: 1, to: last) else { loading = false; return }
                do {
                    let results = try await manager.diaryEntries(from: start, until: end)
                    try Task.checkCancellation()
                    entries = results
                } catch { if !Task.isCancelled { self.error = error.localizedDescription } }
                if !Task.isCancelled { loading = false }
            }
        }.preferredColorScheme(.light).tint(WarmInk.action)
    }
}
