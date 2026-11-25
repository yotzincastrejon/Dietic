import SwiftUI

@main
struct JournalPreviewApp: App {
    var body: some Scene {
        WindowGroup { JournalView().preferredColorScheme(.dark) }
    }
}

private enum WarmInk {
    static let header = Color(red: 0.40, green: 0.18, blue: 0.23)
    static let headerBase = Color(red: 0.30, green: 0.13, blue: 0.18)
    static let paper = Color(red: 1.00, green: 0.97, blue: 0.92)
    static let text = Color(red: 0.23, green: 0.14, blue: 0.16)
    static let muted = Color(red: 0.43, green: 0.33, blue: 0.31)
    static let onHeaderSecondary = Color(red: 0.94, green: 0.81, blue: 0.77)
    static let apricot = Color(red: 1.00, green: 0.66, blue: 0.48)
    static let honey = Color(red: 1.00, green: 0.82, blue: 0.46)
    static let action = Color(red: 0.59, green: 0.25, blue: 0.16)
    static let logger = FoodLogPalette(paper: paper, text: text, muted: muted, action: action, accent: apricot)
}

struct JournalView: View {
    private static let today = Calendar.current.startOfDay(for: .now)
    @State private var day = today
    @State private var log = [today: [
        Entry(food: .toast, servings: 1, meal: .breakfast),
        Entry(food: .yogurt, servings: 1, meal: .breakfast),
        Entry(food: .noodles, servings: 1, meal: .lunch)
    ]]
    @State private var route: LogRoute?
    @State private var calendarOpen = false
    private var entries: [Entry] { log[day] ?? [] }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 21) {
                    HStack {
                        Text("Dietic").italic().font(.system(size: 29, weight: .semibold, design: .serif)).tracking(-1)
                        Spacer()
                        Button { calendarOpen = true } label: {
                            HStack(spacing: 7) {
                                Image(systemName: "calendar")
                                Text(day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                                Image(systemName: "chevron.down").font(.caption2)
                            }.font(.subheadline.weight(.medium)).frame(minHeight: 44)
                        }.accessibilityLabel("Choose diary date")
                    }
                    Rectangle().fill(WarmInk.onHeaderSecondary.opacity(0.4)).frame(height: 1)
                    DailyIntake(entries: entries)
                }
                .padding(.horizontal, 23).padding(.top, 2).padding(.bottom, 26)
                .foregroundStyle(WarmInk.paper)
                .background(LinearGradient(colors: [WarmInk.header, WarmInk.headerBase],
                                           startPoint: .top, endPoint: .bottom))
                ReceiptEdge().fill(WarmInk.headerBase).frame(height: 7).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Food log").font(.system(size: 36, weight: .medium, design: .serif)).tracking(-1.4)
                        Spacer()
                        Text(entries.count == 1 ? "1 entry" : "\(entries.count) entries")
                            .font(.subheadline.monospacedDigit()).foregroundStyle(WarmInk.muted)
                    }.padding(.bottom, 6)
                    if entries.isEmpty {
                        Text("Log a food to start this day.").font(.callout)
                            .foregroundStyle(WarmInk.muted).padding(.vertical, 24)
                    }
                    ForEach(Meal.allCases) { meal in
                        let items = entries.filter { $0.meal == meal }
                        if !items.isEmpty { MealSection(meal: meal, entries: items) }
                    }
                }
                .padding(.horizontal, 23).padding(.top, 19).padding(.bottom, 20)
                .foregroundStyle(WarmInk.text)
            }
        }
        .background { WarmInk.paper.ignoresSafeArea(edges: .bottom) }
        .background { WarmInk.header.ignoresSafeArea() }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 9) {
                Button { route = .search } label: {
                    Label("Log food", systemImage: "plus").font(.headline).frame(maxWidth: .infinity, minHeight: 49)
                        .background(WarmInk.action, in: Capsule()).foregroundStyle(WarmInk.paper)
                }
                Button { route = .scan } label: {
                    Image(systemName: "barcode.viewfinder").font(.title2.weight(.medium))
                        .frame(width: 52, height: 49).background(WarmInk.apricot, in: Capsule())
                }.accessibilityLabel("Scan barcode")
            }.padding(.horizontal, 22).padding(.vertical, 8).background(WarmInk.paper)
        }
        .buttonStyle(.plain).foregroundStyle(WarmInk.text)
        .sheet(item: $route) { start in
            JournalLogger(start: start, palette: WarmInk.logger) { food, meal, servings in
                log[day, default: []].append(Entry(food: food, servings: servings, meal: meal))
                route = nil
            }.preferredColorScheme(.light)
        }
        .sheet(isPresented: $calendarOpen) {
            DatePicker("Diary date", selection: Binding(get: { day }, set: {
                day = Calendar.current.startOfDay(for: $0)
                calendarOpen = false
            }), in: ...Self.today, displayedComponents: .date)
            .datePickerStyle(.graphical).padding().presentationDetents([.medium]).tint(WarmInk.action).preferredColorScheme(.light)
        }
    }
}

private struct DailyIntake: View {
    let entries: [Entry]
    private let goal = 2000
    private var eaten: Int { entries.reduce(0) { $0 + $1.energy } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Daily intake").font(.subheadline.weight(.medium)).foregroundStyle(WarmInk.onHeaderSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text(eaten, format: .number).font(.system(size: 76, weight: .regular, design: .serif))
                    .tracking(-4).lineLimit(1).minimumScaleFactor(0.6)
                Text("kcal").font(.system(size: 25, design: .serif)).italic().foregroundStyle(WarmInk.onHeaderSecondary)
            }
            GeometryReader { proxy in
                let count = 43
                let space: CGFloat = 3
                let w = max(1, (proxy.size.width - CGFloat(count - 1) * space) / CGFloat(count))
                Canvas { ctx, size in
                    let progress = min(1, Double(eaten) / Double(goal))
                    let filled = Int((Double(count) * progress).rounded())
                    let highlight = GraphicsContext.Shading.linearGradient(
                        Gradient(colors: [WarmInk.apricot, WarmInk.honey]), startPoint: .zero,
                        endPoint: CGPoint(x: max(w, CGFloat(filled) * (w + space) - space), y: 0)
                    )
                    for i in 0..<count {
                        let rect = CGRect(x: CGFloat(i) * (w + space), y: 0, width: w, height: size.height)
                        let shading = i < filled ? highlight : .color(WarmInk.onHeaderSecondary.opacity(0.23))
                        ctx.fill(Path(roundedRect: rect, cornerRadius: 1), with: shading)
                    }
                }
            }.frame(height: 17).accessibilityHidden(true)
            HStack {
                Text(eaten > goal ? "\(eaten - goal) kcal over" : "\(goal - eaten) kcal left")
                Spacer()
                Text("Goal \(goal)").foregroundStyle(WarmInk.onHeaderSecondary)
            }.font(.caption.monospacedDigit()).padding(.top, 8)
            HStack(spacing: 0) {
                macro("Carbs", \.carbs)
                separator
                macro("Protein", \.protein)
                separator
                macro("Fat", \.fat)
            }.padding(.top, 20)
        }
    }

    private var separator: some View {
        Rectangle().fill(WarmInk.onHeaderSecondary.opacity(0.35)).frame(width: 1, height: 28).padding(.trailing, 16)
    }

    private func macro(_ label: String, _ key: KeyPath<Food, Int>) -> some View {
        let total = entries.reduce(0) { $0 + $1.food[keyPath: key] * $1.servings }
        return VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(WarmInk.onHeaderSecondary)
            Text("\(total) g").font(.body.weight(.semibold).monospacedDigit())
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ReceiptEdge: Shape {
    func path(in rect: CGRect) -> Path {
        let count = max(1, Int(rect.width / 11))
        let step = rect.width / CGFloat(count)
        var path = Path()
        path.move(to: .zero)
        for i in 0..<count {
            path.addLine(to: CGPoint(x: (CGFloat(i) + 0.5) * step, y: rect.height))
            path.addLine(to: CGPoint(x: CGFloat(i + 1) * step, y: 0))
        }
        path.closeSubpath()
        return path
    }
}

private struct MealSection: View {
    let meal: Meal
    let entries: [Entry]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(meal.rawValue.uppercased()).tracking(1.4)
                Spacer()
                Text("\(entries.reduce(0) { $0 + $1.energy }) kcal")
            }.font(.caption.monospaced().weight(.semibold)).foregroundStyle(WarmInk.muted)
                .padding(.vertical, 9)
            Rectangle().fill(WarmInk.text.opacity(0.32)).frame(height: 1)
            ForEach(entries) { item in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.food.name).font(.body.weight(.medium))
                        Text(item.servings == 1 ? item.food.portion : "\(item.servings) × \(item.food.portion)")
                            .font(.caption).foregroundStyle(WarmInk.muted)
                    }
                    Spacer()
                    Text("\(item.energy)").font(.body.monospacedDigit())
                        .accessibilityLabel("\(item.energy) kilocalories")
                }.padding(.vertical, 6)
            }
        }.padding(.top, 4)
    }
}
