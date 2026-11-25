import SwiftUI

@main
struct MarketApp: App {
    var body: some Scene {
        WindowGroup { MarketDiary().preferredColorScheme(.light) }
    }
}

private enum Market {
    static let cobalt = Color(red: 0.12, green: 0.20, blue: 0.69)
    static let citrus = Color(red: 1, green: 0.94, blue: 0.64)
    static let paper = Color(red: 0.995, green: 0.989, blue: 0.965)
    static let ink = Color(red: 0.095, green: 0.105, blue: 0.16)
    static let muted = Color(red: 0.35, green: 0.36, blue: 0.40)
    static let palette = FoodLogPalette(paper: paper, text: ink, muted: muted, action: cobalt, accent: citrus)
}

private struct FoodSheet: Identifiable {
    let id = UUID()
    let route: LogRoute
    var meal: Meal?
}

private struct MarketDiary: View {
    static let today = Calendar.current.startOfDay(for: .now)
    @State private var day = today
    @State private var days = [today: [
        Entry(food: .toast, servings: 1, meal: .breakfast),
        Entry(food: .yogurt, servings: 1, meal: .breakfast),
        Entry(food: .noodles, servings: 1, meal: .lunch)
    ]]
    @State private var calendar = false
    @State private var foodSheet: FoodSheet?
    @State private var expanded: Set<Meal> = [.breakfast, .lunch]
    private var entries: [Entry] { days[day] ?? [] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("dietic").font(.system(size: 37, weight: .black)).italic().tracking(-3)
                        .foregroundStyle(Market.cobalt)
                    Spacer()
                    Button { calendar = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                            Text(day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                            Image(systemName: "chevron.down").font(.caption2)
                        }.font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                    }.accessibilityLabel("Choose diary date").accessibilityValue(day.formatted(date: .complete, time: .omitted))
                }.padding(.horizontal, 20).padding(.bottom, 12)
                Intake(entries: entries).padding(.horizontal, 16)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Meal log").font(.system(.title, weight: .heavy)).tracking(-1.3)
                        Spacer()
                        Text(entries.count == 1 ? "1 entry" : "\(entries.count) entries")
                            .font(.subheadline).foregroundStyle(Market.muted)
                    }.padding(.top, 20).padding(.bottom, 9)
                    ForEach(Meal.allCases) { meal in
                        let items = entries.filter { $0.meal == meal }
                        let visible = expanded.contains(meal) && !items.isEmpty
                        HStack(spacing: 6) {
                            Button {
                                if items.isEmpty { openFood(for: meal) }
                                else if visible { expanded.remove(meal) }
                                else { expanded.insert(meal) }
                            } label: {
                                HStack(spacing: 8) {
                                    Text(meal.rawValue).font(.headline)
                                    if !items.isEmpty {
                                        Image(systemName: visible ? "chevron.up" : "chevron.down")
                                            .font(.caption2).foregroundStyle(Market.muted)
                                    }
                                    Spacer()
                                    if !items.isEmpty {
                                        Text("\(items.reduce(0) { $0 + $1.energy }) kcal")
                                            .font(.caption.weight(.semibold).monospacedDigit())
                                    }
                                }.frame(minHeight: 44).contentShape(Rectangle())
                            }.accessibilityLabel(meal.rawValue)
                                .accessibilityHint(items.isEmpty ? "Log food for this meal" : "Show or hide foods")
                            Button { openFood(for: meal) } label: {
                                Image(systemName: "plus").font(.body.weight(.semibold))
                                    .frame(width: 28, height: 28)
                                    .background(Market.cobalt.opacity(0.09), in: Circle())
                                    .frame(width: 44, height: 44).contentShape(Rectangle())
                            }.foregroundStyle(Market.cobalt).accessibilityLabel("Add food to \(meal.rawValue)")
                        }
                        if visible {
                            ForEach(items) { item in
                                HStack(alignment: .firstTextBaseline) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.food.name).font(.subheadline)
                                        Text(item.servings == 1 ? item.food.portion : "\(item.servings) × \(item.food.portion)")
                                            .font(.caption).foregroundStyle(Market.muted)
                                    }
                                    Spacer(minLength: 8)
                                    Text("\(item.energy) kcal").font(.caption.monospacedDigit())
                                        .foregroundStyle(Market.muted)
                                }.padding(.bottom, 8).padding(.trailing, 13)
                            }
                        }
                        Divider().padding(.top, visible ? 4 : 0)
                    }
                }.padding(.horizontal, 20).padding(.bottom, 15)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 10) {
                Button { openFood(for: nil) } label: {
                    Label("Log food", systemImage: "plus").frame(maxWidth: .infinity, minHeight: 48)
                        .foregroundStyle(.white).background(Market.cobalt, in: Capsule())
                }
                Button { foodSheet = FoodSheet(route: .scan) } label: {
                    Label("Scan", systemImage: "barcode.viewfinder")
                        .padding(.horizontal, 17).frame(minHeight: 48)
                        .foregroundStyle(Market.cobalt).background(Market.citrus, in: Capsule())
                }.accessibilityLabel("Scan barcode")
            }.font(.headline).padding(.horizontal, 16).padding(.vertical, 8).background(Market.paper)
        }
        .buttonStyle(.plain).foregroundStyle(Market.ink).background(Market.paper)
        .sheet(item: $foodSheet) { sheet in
            JournalLogger(start: sheet.route, palette: Market.palette, initialMeal: sheet.meal) { food, meal, count in
                days[day, default: []].append(Entry(food: food, servings: count, meal: meal))
                expanded.insert(meal)
                foodSheet = nil
            }
        }
        .sheet(isPresented: $calendar) {
            DatePicker("Diary date", selection: Binding(get: { day }, set: {
                day = Calendar.current.startOfDay(for: $0)
                calendar = false
            }), in: ...Self.today, displayedComponents: .date)
                .datePickerStyle(.graphical).padding().tint(Market.cobalt)
                .presentationDetents([.medium]).presentationBackground(Market.paper)
        }
    }

    private func openFood(for meal: Meal?) {
        foodSheet = FoodSheet(route: .search, meal: meal)
    }
}

private struct Intake: View {
    let entries: [Entry]
    private let goal = 2000
    private var eaten: Int { entries.reduce(0) { $0 + $1.energy } }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily intake").font(.headline)
                    Text(eaten, format: .number)
                        .font(.system(size: 64, weight: .heavy)).tracking(-4)
                        .lineLimit(1).minimumScaleFactor(0.55)
                    Text("of \(goal) kcal").font(.subheadline.weight(.medium))
                }
                .padding(.leading, 20).padding(.vertical, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                // Orange-Fruit-Pieces by Evan-Amos, resized. CC BY-SA 3.0.
                // https://commons.wikimedia.org/wiki/File:Orange-Fruit-Pieces.jpg
                Image("Oranges").resizable().scaledToFit().rotationEffect(.degrees(-11))
                    .scaleEffect(1.22).offset(x: 6)
                    .frame(maxWidth: .infinity).blendMode(.multiply).accessibilityHidden(true)
            }
            .foregroundStyle(Market.cobalt)
            .background(Market.citrus)
            .compositingGroup()
            HStack(spacing: 14) {
                macro("Carbs", \.carbs)
                divider
                macro("Protein", \.protein)
                divider
                macro("Fat", \.fat)
            }
            .padding(.horizontal, 20).padding(.vertical, 13)
            .foregroundStyle(.white).background(Market.cobalt)
        }.clipShape(RoundedRectangle(cornerRadius: 21))
    }

    private var divider: some View {
        Rectangle().fill(.white.opacity(0.32)).frame(width: 1, height: 28)
    }

    private func macro(_ label: String, _ key: KeyPath<Food, Int>) -> some View {
        let grams = entries.reduce(0) { $0 + $1.food[keyPath: key] * $1.servings }
        return VStack(alignment: .leading, spacing: 1) {
            Text(label).font(.caption)
            Text("\(grams) g").font(.headline.monospacedDigit())
        }.frame(maxWidth: .infinity, alignment: .leading).accessibilityElement(children: .combine)
    }
}
