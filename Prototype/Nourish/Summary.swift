import SwiftUI

@main
struct NourishApp: App {
    var body: some Scene {
        WindowGroup { Summary() }
    }
}

private enum Sheet: Identifiable {
    case calendar, mix, food(Meal?, Bool)
    var id: String {
        switch self {
        case .calendar: "calendar"
        case .mix: "mix"
        case let .food(meal, scan): "\(meal?.rawValue ?? "Any")-\(scan)"
        }
    }
}

extension Meal {
    var symbol: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.stars.fill"
        case .snack: "carrot.fill"
        }
    }
}

private struct Summary: View {
    private static let today = Calendar.current.startOfDay(for: .now)
    @State private var day = today
    @State private var days = [today: [
        Entry(food: .toast, servings: 1, meal: .breakfast),
        Entry(food: .yogurt, servings: 1, meal: .breakfast),
        Entry(food: .noodles, servings: 1, meal: .lunch)
    ]]
    @State private var sheet: Sheet?
    @State private var path: [Meal] = []
    private var entries: [Entry] { days[day] ?? [] }
    private var intake: Intake { Intake(entries: entries) }
    private let accent = Color(red: 0.86, green: 0.18, blue: 0.32)

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Button { sheet = .calendar } label: {
                        HStack(spacing: 6) {
                            Text(day.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                            Image(systemName: "chevron.down").font(.caption2.weight(.bold))
                        }.font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                    }.buttonStyle(.plain).accessibilityLabel("Choose summary date")
                        .accessibilityValue(day.formatted(date: .complete, time: .omitted))
                    NutritionCard(intake: intake, reflectionEnabled: sheet == nil && path.isEmpty, showMix: { sheet = .mix }).padding(.top, 12)
                    HStack(spacing: 0) {
                        ForEach(Nutrient.allCases) { nutrient in
                            VStack(alignment: .leading, spacing: 5) {
                                HStack(spacing: 5) {
                                    Circle().fill(nutrient.color).frame(width: 8, height: 8)
                                    Text(nutrient.rawValue).font(.caption.weight(.semibold))
                                }
                                Text("\(intake.grams(nutrient)) g").font(.title3.weight(.bold).monospacedDigit())
                            }.accessibilityElement(children: .combine)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 14)
                            if nutrient != .fat { Divider().frame(height: 28) }
                        }
                    }.padding(.vertical, 13).background(.background, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.top, 10)
                    HStack {
                        Text("Meals").font(.title2.bold())
                        Spacer()
                        Button { sheet = .food(nil, true) } label: { Label("Scan", systemImage: "barcode.viewfinder") }
                            .font(.subheadline.weight(.semibold))
                            .accessibilityLabel("Scan barcode")
                    }.padding(.top, 20).padding(.bottom, 9)
                    VStack(spacing: 0) {
                        ForEach(Meal.allCases) { meal in
                            let items = entries.filter { $0.meal == meal }
                            HStack(spacing: 8) {
                                Button { path.append(meal) } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: meal.symbol).frame(width: 31, height: 31)
                                            .foregroundStyle(accent).background(accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(meal.rawValue).font(.body.weight(.semibold))
                                            Text(items.isEmpty ? "No foods logged" : items.map(\.food.name).joined(separator: " · "))
                                                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                        }
                                        Spacer(minLength: 2)
                                        if !items.isEmpty {
                                            Text("\(items.reduce(0) { $0 + $1.energy }) kcal")
                                                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                                        }
                                    }.frame(minHeight: 55).contentShape(Rectangle())
                                }.buttonStyle(.plain)
                                Button { sheet = .food(meal, false) } label: {
                                    Image(systemName: "plus.circle.fill").font(.title3)
                                        .frame(width: 44, height: 44).contentShape(Rectangle())
                                }.accessibilityLabel("Add food to \(meal.rawValue)")
                            }.padding(.leading, 13).padding(.trailing, 4)
                            if meal != .snack { Divider().padding(.leading, 56) }
                        }
                    }.background(.background, in: RoundedRectangle(cornerRadius: 16))
                }.padding(.horizontal, 16).padding(.bottom, 18)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Summary")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { sheet = .food(nil, false) } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Log food")
                }
            }
            .navigationDestination(for: Meal.self) { meal in
                let items = entries.filter { $0.meal == meal }
                List {
                    Section(day.formatted(.dateTime.month(.wide).day())) {
                        if items.isEmpty { Text("No foods logged").foregroundStyle(.secondary) }
                        ForEach(items) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.food.name)
                                    Text("\(item.servings) × \(item.food.portion)").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(item.energy) kcal").font(.subheadline).foregroundStyle(.secondary)
                            }
                        }.onDelete { offsets in
                            let ids = Set(offsets.map { items[$0].id })
                            days[day, default: []].removeAll { ids.contains($0.id) }
                        }
                        Button("Add food") { sheet = .food(meal, false) }
                    }
                }.navigationTitle(meal.rawValue)
                .toolbar { if !items.isEmpty { EditButton() } }
            }
        }
        .tint(accent)
        .sheet(item: $sheet) { route in
            switch route {
            case .calendar:
                DatePicker("Summary date", selection: Binding(get: { day }, set: {
                    day = Calendar.current.startOfDay(for: $0)
                    sheet = nil
                }), in: ...Self.today, displayedComponents: .date)
                    .datePickerStyle(.graphical).padding().presentationDetents([.medium])
            case .mix:
                NavigationStack {
                    List {
                        Section {
                            ForEach(Nutrient.allCases) { nutrient in
                                HStack {
                                    Circle().fill(nutrient.color).frame(width: 11, height: 11)
                                    Text(nutrient.rawValue)
                                    Spacer()
                                    Text(intake.share(nutrient), format: .percent.precision(.fractionLength(0)))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } footer: {
                            Text("Each color fills the card in proportion to the energy from that nutrient for the selected day. Carbs and protein count as 4 kcal per gram, and fat as 9. Colors deepen as energy accumulates toward 2,000 kcal. Without recorded macros, the card stays silver. Tilt your phone or drag across the card to catch the light.")
                        }
                    }.navigationTitle("Card colors").navigationBarTitleDisplayMode(.inline)
                        .toolbar { Button("Done") { sheet = nil } }
                }.presentationDetents([.medium, .large])
            case let .food(meal, scan):
                FoodForm(initialMeal: meal, scan: scan) { food, meal, servings in
                    days[day, default: []].append(Entry(food: food, servings: servings, meal: meal))
                    sheet = nil
                }.tint(accent)
            }
        }
    }
}
