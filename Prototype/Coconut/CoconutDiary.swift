import SwiftUI

@main
struct CoconutPreviewApp: App {
    var body: some Scene {
        WindowGroup { CoconutDiary().preferredColorScheme(.light) }
    }
}

private struct CoconutDiary: View {
    private static let today = Calendar.current.startOfDay(for: .now)
    @State private var day = today
    @State private var days = [today: [
        Entry(food: .toast, servings: 1, meal: .breakfast),
        Entry(food: .yogurt, servings: 1, meal: .breakfast),
        Entry(food: .noodles, servings: 1, meal: .lunch)
    ]]
    @State private var logRoute: LogRoute?
    @State private var choosingDate = false
    private var entries: [Entry] { days[day] ?? [] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    HStack(spacing: 7) {
                        CoconutMark().frame(width: 25, height: 23).accessibilityHidden(true)
                        Text("Dietic").font(.system(.headline, design: .serif)).italic()
                    }
                    Spacer()
                    Button { choosingDate = true } label: {
                        HStack(spacing: 7) {
                            Text(day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                            Image(systemName: "chevron.down").font(.caption2)
                        }.font(.subheadline).frame(minHeight: 44)
                    }.accessibilityLabel("Choose diary date").accessibilityValue(day.formatted(date: .complete, time: .omitted))
                }
                Text("Food diary").font(.custom("Georgia", size: 47, relativeTo: .largeTitle))
                    .tracking(-2.4).padding(.top, 9).padding(.bottom, 19)
                Intake(entries: entries)
                if entries.isEmpty {
                    Text("No foods logged for this day.").font(.body)
                        .foregroundStyle(Coconut.taupe).padding(.top, 28)
                }
                ForEach(Meal.allCases) { meal in
                    let mealEntries = entries.filter { $0.meal == meal }
                    if !mealEntries.isEmpty {
                        MealGroup(meal: meal, entries: mealEntries).padding(.top, 25)
                    }
                }
            }.padding(.horizontal, 24).padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 10) {
                Button { logRoute = .search } label: {
                    Label("Log food", systemImage: "plus")
                        .font(.headline).foregroundStyle(Coconut.milk)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Coconut.shell, in: RoundedRectangle(cornerRadius: 12))
                }
                Button { logRoute = .scan } label: {
                    Image(systemName: "barcode.viewfinder").font(.title2)
                        .frame(width: 52, height: 48)
                        .background(Coconut.linen, in: RoundedRectangle(cornerRadius: 12))
                }.accessibilityLabel("Scan barcode")
            }.padding(.horizontal, 24).padding(.vertical, 8).background(Coconut.milk)
        }
        .buttonStyle(.plain).foregroundStyle(Coconut.shell).background(Coconut.milk)
        .sheet(item: $logRoute) { route in
            JournalLogger(start: route, palette: Coconut.palette) { food, meal, count in
                days[day, default: []].append(Entry(food: food, servings: count, meal: meal))
                logRoute = nil
            }
        }
        .sheet(isPresented: $choosingDate) {
            DatePicker("Diary date", selection: Binding(get: { day }, set: {
                day = Calendar.current.startOfDay(for: $0)
                choosingDate = false
            }), in: ...Self.today, displayedComponents: .date)
                .datePickerStyle(.graphical).padding().tint(Coconut.shell)
                .presentationDetents([.medium]).presentationBackground(Coconut.milk)
        }
    }
}

private struct Intake: View {
    let entries: [Entry]
    private let goal = 2000
    private var energy: Int { entries.reduce(0) { $0 + $1.energy } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily intake").font(.subheadline).foregroundStyle(Coconut.taupe)
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(energy, format: .number).font(.custom("Georgia", size: 39, relativeTo: .title))
                        Text("kcal").font(.subheadline)
                    }
                    Text("of \(goal) kcal").font(.caption).foregroundStyle(Coconut.taupe)
                }
                Spacer()
                ZStack {
                    Circle().stroke(Coconut.rule, lineWidth: 4)
                    Circle().trim(from: 0, to: min(1, CGFloat(energy) / CGFloat(goal)))
                        .stroke(Coconut.oak, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(Double(energy) / Double(goal), format: .percent.precision(.fractionLength(0)))
                        .font(.subheadline.weight(.medium).monospacedDigit())
                }.frame(width: 60, height: 60).accessibilityLabel("Daily goal used")
                    .accessibilityValue(Text(Double(energy) / Double(goal), format: .percent.precision(.fractionLength(0))))
            }
            Rectangle().fill(Coconut.rule).frame(height: 1)
            HStack {
                macro("Carbs", \.carbs)
                Spacer()
                macro("Protein", \.protein)
                Spacer()
                macro("Fat", \.fat)
            }
        }.padding(18).background(Coconut.linen, in: RoundedRectangle(cornerRadius: 14))
    }

    private func macro(_ name: String, _ key: KeyPath<Food, Int>) -> some View {
        let grams = entries.reduce(0) { $0 + $1.food[keyPath: key] * $1.servings }
        return VStack(alignment: .leading, spacing: 4) {
            Text(name).font(.caption).foregroundStyle(Coconut.taupe)
            Text("\(grams) g").font(.subheadline.weight(.medium).monospacedDigit())
        }.accessibilityElement(children: .combine)
    }
}

private struct MealGroup: View {
    let meal: Meal
    let entries: [Entry]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(meal.rawValue).font(.custom("Georgia", size: 26, relativeTo: .title2)).tracking(-0.8)
                Spacer()
                Text("\(entries.reduce(0) { $0 + $1.energy }) kcal")
                    .font(.caption.monospacedDigit()).foregroundStyle(Coconut.taupe)
            }.padding(.bottom, 9)
            Rectangle().fill(Coconut.rule).frame(height: 1)
            ForEach(entries) { entry in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.food.name).font(.body)
                        Text(entry.servings == 1 ? entry.food.portion : "\(entry.servings) × \(entry.food.portion)")
                            .font(.caption).foregroundStyle(Coconut.taupe)
                    }
                    Spacer()
                    Text(entry.energy, format: .number).font(.subheadline.monospacedDigit())
                        .accessibilityLabel("\(entry.energy) kilocalories")
                }.padding(.top, 11)
            }
        }
    }
}
