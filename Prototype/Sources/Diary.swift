import SwiftUI

@main
struct DieticPreviewApp: App {
    var body: some Scene {
        WindowGroup { Diary().preferredColorScheme(.light) }
    }
}

struct Diary: View {
    private static let today = Calendar.current.startOfDay(for: .now)
    @State private var day = today
    @State private var diary = [today: [
        Entry(food: .toast, servings: 1, meal: .breakfast),
        Entry(food: .yogurt, servings: 1, meal: .breakfast),
        Entry(food: .noodles, servings: 1, meal: .lunch)
    ]]
    @State private var editing: Meal?
    @State private var expanded: Set<Meal> = []
    @State private var choosingDate = false

    private var entries: [Entry] { diary[day] ?? [] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(day.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                            .font(.subheadline.weight(.medium)).foregroundStyle(Style.muted)
                        Text("My Diary").font(.system(size: 42, weight: .bold, design: .rounded))
                            .tracking(-2)
                    }
                    Spacer()
                    Button { choosingDate = true } label: {
                        Image(systemName: "calendar").font(.title3.weight(.medium))
                            .frame(width: 44, height: 44).background(.white, in: Circle())
                    }
                    .accessibilityLabel("Choose diary date")
                }
                .padding(.bottom, 18)
                EnergyCard(entries: entries).padding(.bottom, 24)
                HStack(alignment: .firstTextBaseline) {
                    Text("Meals").font(.title.bold())
                    Spacer()
                    Text("\(entries.count) foods logged").font(.subheadline).foregroundStyle(Style.muted)
                }
                .padding(.bottom, 5)
                ForEach(Meal.allCases) { meal in
                    let items = entries.filter { $0.meal == meal }
                    HStack(spacing: 6) {
                        Button {
                            if items.isEmpty { editing = meal }
                            else {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    if expanded.contains(meal) { expanded.remove(meal) } else { expanded.insert(meal) }
                                }
                            }
                        } label: {
                            HStack(spacing: 13) {
                                Art(meal: meal)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(meal.rawValue).font(.headline)
                                    Text(items.isEmpty ? "No foods yet" : items.map(\.food.name).joined(separator: " · "))
                                        .font(.caption).foregroundStyle(Style.muted).lineLimit(1)
                                }
                                Spacer(minLength: 0)
                                if !items.isEmpty {
                                    VStack(alignment: .trailing, spacing: 0) {
                                        Text("\(items.reduce(0) { $0 + $1.energy })").font(.subheadline.bold())
                                        Text("kcal").font(.caption2).foregroundStyle(Style.muted)
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .accessibilityHint(items.isEmpty ? "Add food" : "Show or hide logged foods")
                        Button { editing = meal } label: {
                            Image(systemName: "plus").font(.body.weight(.semibold))
                                .frame(width: 32, height: 32).background(.white, in: Circle())
                                .frame(width: 44, height: 44).contentShape(Rectangle())
                        }.accessibilityLabel("Add food to \(meal.rawValue)")
                    }
                    .padding(.vertical, 9)
                    if expanded.contains(meal) {
                        ForEach(items) { item in
                            HStack {
                                Text("\(item.servings) × \(item.food.name)")
                                Spacer()
                                Text("\(item.energy) kcal")
                            }.font(.caption).foregroundStyle(Style.muted).padding(.leading, 67).padding(.bottom, 9)
                        }
                    }
                    Divider()
                }
                HStack(spacing: 13) {
                    Image("scale2").resizable().scaledToFit().frame(width: 36, height: 36).accessibilityHidden(true)
                    Text("Weight").font(.headline)
                    Spacer()
                    Text("165.0 lb").font(.headline)
                }
                .padding(16).background(.white, in: RoundedRectangle(cornerRadius: 18))
                .padding(.top, 22)
            }
            .padding(.horizontal, 22).padding(.top, 6).padding(.bottom, 22)
        }
        .background(Style.paper).foregroundStyle(Style.ink).buttonStyle(.plain)
        .sheet(item: $editing) { meal in
            FoodLogger(meal: meal, recent: recentFoods) { food, servings in
                diary[day, default: []].append(Entry(food: food, servings: servings, meal: meal))
                editing = nil
            }
        }
        .sheet(isPresented: $choosingDate) {
            DatePicker("Diary date", selection: Binding(get: { day }, set: {
                day = Calendar.current.startOfDay(for: $0)
                expanded.removeAll()
                choosingDate = false
            }), in: ...Self.today, displayedComponents: .date)
                .datePickerStyle(.graphical).padding().presentationDetents([.medium])
        }
    }

    private var recentFoods: [Food] {
        var seen: Set<Food> = []
        return diary.keys.sorted(by: >).flatMap { diary[$0, default: []].reversed().map(\.food) }
            .filter { seen.insert($0).inserted }
    }
}

private struct EnergyCard: View {
    let entries: [Entry]
    private let target = 2000
    private var eaten: Int { entries.reduce(0) { $0 + $1.energy } }

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(eaten > target ? "Over daily goal" : "Calories left").font(.headline)
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(abs(target - eaten), format: .number)
                            .font(.system(size: 45, weight: .bold, design: .rounded)).tracking(-2)
                        Text("kcal").font(.subheadline.weight(.medium))
                    }
                    Text("\(eaten) of \(target) kcal eaten").font(.caption).foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                ZStack {
                    Circle().stroke(.white.opacity(0.15), lineWidth: 7)
                    Circle().trim(from: 0, to: min(1, CGFloat(eaten) / CGFloat(target)))
                        .stroke(Style.peach, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image("Eaten").resizable().scaledToFit().padding(18).accessibilityHidden(true)
                }.frame(width: 68, height: 68)
            }
            Rectangle().fill(.white.opacity(0.17)).frame(height: 1)
            HStack(spacing: 18) {
                macro("Carbs", \.carbs, 250, .cyan)
                macro("Protein", \.protein, 100, .pink)
                macro("Fat", \.fat, 67, .yellow)
            }
        }
        .padding(19).foregroundStyle(.white)
        .background(Style.plum, in: RoundedRectangle(cornerRadius: 24))
    }

    private func macro(_ name: String, _ field: KeyPath<Food, Int>, _ goal: Int, _ color: Color) -> some View {
        let value = entries.reduce(0) { $0 + $1.food[keyPath: field] * $1.servings }
        return VStack(alignment: .leading, spacing: 5) {
            Text(name).font(.caption.weight(.semibold))
            ProgressView(value: Double(min(value, goal)), total: Double(goal)).tint(color)
            Text("\(value) / \(goal) g").font(.caption2).foregroundStyle(.white.opacity(0.8))
        }
    }
}
