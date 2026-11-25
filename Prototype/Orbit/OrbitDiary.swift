import SwiftUI

@main
struct OrbitPreviewApp: App {
    var body: some Scene {
        WindowGroup { OrbitDiary().preferredColorScheme(.dark) }
    }
}

enum OrbitRoute: String, Identifiable {
    case food, barcode, calendar
    var id: Self { self }
}

struct OrbitDiary: View {
    private static let today = Calendar.current.startOfDay(for: .now)
    @State private var day = today
    @State private var selected = Meal.breakfast
    @State private var route: OrbitRoute?
    @State private var log = [today: [
        Entry(food: .toast, servings: 1, meal: .breakfast),
        Entry(food: .yogurt, servings: 1, meal: .breakfast),
        Entry(food: .noodles, servings: 1, meal: .lunch)
    ]]
    private var entries: [Entry] { log[day] ?? [] }
    private var mealEntries: [Entry] { entries.filter { $0.meal == selected } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "circle.grid.cross").foregroundStyle(JournalInk.violet)
                        Text("Dietic").font(.headline)
                    }.accessibilityElement(children: .combine)
                    Spacer()
                    Button { route = .calendar } label: {
                        HStack(spacing: 6) {
                            Text(day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                            Image(systemName: "chevron.down").font(.caption2)
                        }.font(.subheadline).frame(minHeight: 44)
                    }.accessibilityLabel("Choose diary date")
                }.padding(.horizontal, 22)
                Text("Daily orbit").font(.system(size: 43, weight: .medium, design: .serif))
                    .tracking(-1.7).padding(.horizontal, 22)
                MealOrbit(selected: $selected).padding(.bottom, 15)
                OrbitIntake(entries: entries).padding(.horizontal, 22)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        HStack(spacing: 9) {
                            Circle().fill(selected.moonColor).frame(width: 8, height: 8).accessibilityHidden(true)
                            Text(selected.rawValue).font(.title2.weight(.semibold))
                        }
                        Spacer()
                        Text("\(mealEntries.reduce(0) { $0 + $1.energy }) kcal")
                            .font(.subheadline.monospacedDigit()).foregroundStyle(JournalInk.onHeaderSecondary)
                    }.padding(.bottom, 10)
                    if mealEntries.isEmpty {
                        Text("No foods logged yet.").font(.callout)
                            .foregroundStyle(JournalInk.onHeaderSecondary).padding(.vertical, 12)
                    }
                    ForEach(mealEntries) { entry in
                        Divider()
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(entry.food.name).font(.body.weight(.medium))
                                Text(entry.servings == 1 ? entry.food.portion : "\(entry.servings) × \(entry.food.portion)")
                                    .font(.caption).foregroundStyle(JournalInk.onHeaderSecondary)
                            }
                            Spacer()
                            Text("\(entry.energy) kcal").font(.caption.monospacedDigit())
                        }.padding(.vertical, 9)
                    }
                }
                .padding(.horizontal, 22).padding(.top, 21).padding(.bottom, 12)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 10) {
                Button { route = .food } label: {
                    Label("Log \(selected.rawValue.lowercased())", systemImage: "plus")
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(LinearGradient(colors: [JournalInk.violet, JournalInk.iceBlue],
                                                   startPoint: .leading, endPoint: .trailing), in: Capsule())
                        .foregroundStyle(JournalInk.header)
                }
                Button { route = .barcode } label: {
                    Image(systemName: "barcode.viewfinder").font(.title2)
                        .frame(width: 54, height: 48).background(JournalInk.headerBase, in: Capsule())
                        .overlay { Capsule().strokeBorder(JournalInk.violet.opacity(0.55)) }
                }.accessibilityLabel("Scan barcode")
            }.font(.headline).padding(.horizontal, 20).padding(.vertical, 9)
                .background(JournalInk.header)
        }
        .foregroundStyle(JournalInk.paper).buttonStyle(.plain).background(JournalInk.header)
        .sheet(item: $route) { screen in
            if screen == .calendar {
                DatePicker("Diary date", selection: Binding(get: { day }, set: {
                    day = Calendar.current.startOfDay(for: $0)
                    route = nil
                }), in: ...Self.today, displayedComponents: .date)
                    .datePickerStyle(.graphical).padding().tint(JournalInk.violet)
                    .presentationDetents([.medium]).presentationBackground(JournalInk.header)
            } else {
                OrbitLogger(meal: selected, scan: screen == .barcode) { food, count in
                    log[day, default: []].append(Entry(food: food, servings: count, meal: selected))
                    route = nil
                }
            }
        }
    }
}

private struct OrbitIntake: View {
    let entries: [Entry]
    private let goal = 2000
    private var eaten: Int { entries.reduce(0) { $0 + $1.energy } }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text("Daily intake").font(.subheadline.weight(.medium))
                Spacer()
                Text("Goal \(goal) kcal").font(.caption.monospacedDigit()).foregroundStyle(JournalInk.onHeaderSecondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(eaten, format: .number).font(.system(size: 36, weight: .semibold, design: .rounded))
                Text("kcal").font(.subheadline)
                Spacer()
                Text(eaten > goal ? "\(eaten - goal) kcal over" : "\(goal - eaten) kcal left")
                    .font(.caption.monospacedDigit()).foregroundStyle(JournalInk.iceBlue)
            }
            GeometryReader { proxy in
                Capsule().fill(JournalInk.paper.opacity(0.12))
                    .overlay(alignment: .leading) {
                        Capsule().fill(LinearGradient(colors: [JournalInk.violet, JournalInk.iceBlue],
                                                      startPoint: .leading, endPoint: .trailing))
                            .frame(width: proxy.size.width * min(1, CGFloat(eaten) / CGFloat(goal)))
                    }
            }.frame(height: 5).accessibilityHidden(true)
            HStack {
                nutrient("Carbs", \.carbs)
                Spacer()
                nutrient("Protein", \.protein)
                Spacer()
                nutrient("Fat", \.fat)
            }.padding(.top, 3)
        }
        .padding(16).background(JournalInk.headerBase, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(JournalInk.violet.opacity(0.24)) }
    }

    private func nutrient(_ label: String, _ key: KeyPath<Food, Int>) -> some View {
        let total = entries.reduce(0) { $0 + $1.food[keyPath: key] * $1.servings }
        return VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(JournalInk.onHeaderSecondary)
            Text("\(total) g").font(.subheadline.weight(.semibold).monospacedDigit())
        }
    }
}
