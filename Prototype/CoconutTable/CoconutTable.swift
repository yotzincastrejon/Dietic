import SwiftUI

@main
struct CoconutTableApp: App {
    var body: some Scene {
        WindowGroup { CoconutTable().preferredColorScheme(.light) }
    }
}

private struct CoconutTable: View {
    private static let today = Calendar.current.startOfDay(for: .now)
    @State private var day = today
    @State private var meal = Meal.breakfast
    @State private var days = [today: [
        Entry(food: .toast, servings: 1, meal: .breakfast),
        Entry(food: .yogurt, servings: 1, meal: .breakfast),
        Entry(food: .noodles, servings: 1, meal: .lunch)
    ]]
    @State private var route: LogRoute?
    @State private var calendarOpen = false
    private var entries: [Entry] { days[day] ?? [] }
    private var foods: [Entry] { entries.filter { $0.meal == meal } }

    var body: some View {
        GeometryReader { viewport in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            HStack(spacing: 7) {
                                CoconutMark().frame(width: 29, height: 25).accessibilityHidden(true)
                                Text("Dietic").font(.custom("Georgia-Italic", size: 22, relativeTo: .headline))
                            }
                            Spacer()
                            Button { calendarOpen = true } label: {
                                HStack(spacing: 6) {
                                    Text(day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                                    Image(systemName: "chevron.down").font(.caption2)
                                }.font(.subheadline).frame(minHeight: 44)
                            }.accessibilityLabel("Choose diary date")
                                .accessibilityValue(day.formatted(date: .complete, time: .omitted))
                        }
                        MealTabs(selection: $meal)
                    }.padding(.horizontal, 24).padding(.bottom, 1).background(Coconut.linen)

                    HStack {
                        VStack(alignment: .leading, spacing: 7) {
                            Text(meal.rawValue).font(.custom("Georgia", size: 43, relativeTo: .largeTitle))
                                .tracking(-1.8).minimumScaleFactor(0.7)
                            Text(foods.count == 1 ? "1 food logged" : "\(foods.count) foods logged")
                                .font(.subheadline).foregroundStyle(Coconut.taupe)
                        }
                        Spacer(minLength: 5)
                        Plate(energy: foods.reduce(0) { $0 + $1.energy })
                    }.padding(.horizontal, 24).padding(.vertical, 20).background(Coconut.linen)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(foods) { entry in
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.food.name).font(.body.weight(.medium))
                                    Text(entry.servings == 1 ? entry.food.portion : "\(entry.servings) × \(entry.food.portion)")
                                        .font(.subheadline).foregroundStyle(Coconut.taupe)
                                }
                                Spacer()
                                Text("\(entry.energy) kcal").font(.subheadline.monospacedDigit()).foregroundStyle(Coconut.taupe)
                            }.padding(.vertical, 15)
                            Rectangle().fill(Coconut.rule).frame(height: 0.7)
                        }
                        HStack(spacing: 12) {
                            Button { route = .search } label: {
                                Label("Add food", systemImage: "plus").font(.headline)
                                    .foregroundStyle(Coconut.milk).frame(maxWidth: .infinity, minHeight: 46)
                                    .background(Coconut.shell, in: Capsule())
                            }
                            Button { route = .scan } label: {
                                Label("Scan", systemImage: "barcode.viewfinder").font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 18).frame(minHeight: 46)
                                    .overlay { Capsule().strokeBorder(Coconut.rule) }
                            }.accessibilityLabel("Scan barcode")
                        }.padding(.top, 20)
                    }.padding(.horizontal, 24).padding(.top, 9)
                    Spacer(minLength: 34)
                    DaySummary(entries: entries)
                }.frame(minHeight: viewport.size.height, alignment: .top).background(Coconut.milk)
            }
        }
        .buttonStyle(.plain).foregroundStyle(Coconut.shell)
        .background {
            VStack(spacing: 0) { Coconut.linen; Coconut.milk; Coconut.shell }.ignoresSafeArea()
        }
        .sheet(item: $route) { start in
            JournalLogger(start: start, palette: Coconut.palette, initialMeal: meal) { food, destination, count in
                days[day, default: []].append(Entry(food: food, servings: count, meal: destination))
                meal = destination
                route = nil
            }
        }
        .sheet(isPresented: $calendarOpen) {
            DatePicker("Diary date", selection: Binding(get: { day }, set: {
                day = Calendar.current.startOfDay(for: $0)
                calendarOpen = false
            }), in: ...Self.today, displayedComponents: .date)
                .datePickerStyle(.graphical).padding().tint(Coconut.shell)
                .presentationDetents([.medium]).presentationBackground(Coconut.milk)
        }
    }
}

private struct MealTabs: View {
    @Binding var selection: Meal

    var body: some View {
        ViewThatFits(in: .horizontal) {
            tabs
            ScrollView(.horizontal) { tabs }.scrollIndicators(.hidden)
        }
    }

    private var tabs: some View {
        HStack(spacing: 0) {
            ForEach(Meal.allCases) { item in
                Button { selection = item } label: {
                    Text(item.rawValue)
                        .font(.subheadline.weight(selection == item ? .semibold : .regular))
                        .fixedSize().padding(.horizontal, 6)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(selection == item ? Coconut.shell : Coconut.taupe)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(selection == item ? Coconut.shell : Coconut.rule)
                                .frame(height: selection == item ? 2 : 0.7)
                        }
                        .contentShape(Rectangle())
                }.accessibilityAddTraits(selection == item ? .isSelected : [])
            }
        }
    }
}

private struct Plate: View {
    let energy: Int
    var body: some View {
        ZStack {
            Circle().strokeBorder(Coconut.oak, lineWidth: 1.2)
            Circle().strokeBorder(Coconut.rule, lineWidth: 0.9).padding(5)
            Circle().fill(Coconut.milk).padding(10)
            VStack(spacing: 0) {
                Text(energy, format: .number)
                    .font(.custom("Georgia", size: 24, relativeTo: .headline)).minimumScaleFactor(0.6)
                Text("kcal").font(.caption2)
            }.padding(13)
        }.frame(width: 86, height: 86).accessibilityElement(children: .ignore)
            .accessibilityLabel("Meal total").accessibilityValue("\(energy) kilocalories")
    }
}

private struct DaySummary: View {
    let entries: [Entry]
    private let goal = 2000
    private var energy: Int { entries.reduce(0) { $0 + $1.energy } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Daily intake").font(.custom("Georgia", size: 23, relativeTo: .title2))
                Spacer()
                Text("\(energy) / \(goal) kcal").font(.subheadline.monospacedDigit())
            }
            GeometryReader { proxy in
                Capsule().fill(Coconut.milk.opacity(0.20)).overlay(alignment: .leading) {
                    Capsule().fill(Coconut.linen)
                        .frame(width: proxy.size.width * min(1, CGFloat(energy) / CGFloat(goal)))
                }
            }.frame(height: 4).accessibilityHidden(true)
            HStack {
                macro("Carbs", \.carbs)
                Spacer()
                macro("Protein", \.protein)
                Spacer()
                macro("Fat", \.fat)
            }.padding(.top, 3)
        }.foregroundStyle(Coconut.milk).padding(.horizontal, 24).padding(.vertical, 20)
            .background(Coconut.shell)
    }

    private func macro(_ label: String, _ key: KeyPath<Food, Int>) -> some View {
        let value = entries.reduce(0) { $0 + $1.food[keyPath: key] * $1.servings }
        return VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption).foregroundStyle(Coconut.linen)
            Text("\(value) g").font(.body.weight(.medium).monospacedDigit())
        }.accessibilityElement(children: .combine)
    }
}
