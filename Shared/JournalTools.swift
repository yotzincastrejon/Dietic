import SwiftUI

struct JournalToolsView: View {
    private struct Tool: Identifiable {
        let title: String
        let icon: String
        let keywords: String
        let destination: JournalSheet
        var id: String { title }
        init(_ title: String, _ icon: String, _ keywords: String, _ destination: JournalSheet) {
            self.title = title
            self.icon = icon
            self.keywords = keywords
            self.destination = destination
        }
    }
    private static let sections: [(name: String, tools: [Tool])] = [
        ("Log", [
            Tool("Quick add", "bolt", "calories manual macros", .quickAdd),
            Tool("Scan nutrition label", "text.viewfinder", "camera photo package OCR", .scanLabel),
            Tool("Scan barcode", "barcode.viewfinder", "grocery camera", .scan),
            Tool("Scan plate", "camera", "photo recognition", .plate),
            Tool("Water", "drop", "hydration drink ounces", .water),
        ]),
        ("Meals & groceries", [
            Tool("Saved meals", "book.closed", "recipes cookbook ingredients servings", .savedMeals),
            Tool("Repeat a meal", "arrow.clockwise", "recent yesterday log again", .repeatMeal),
            Tool("My groceries", "basket", "barcode pantry favorite offline create foods backup restore", .groceries),
            Tool("Meal planner", "calendar.badge.plus", "shopping list schedule recipes", .planner),
        ]),
        ("Review", [
            Tool("Nutrients & notes", "list.bullet.clipboard", "fiber sodium sugar vitamins targets journal backup", .dayDetails),
            Tool("Weekly trends", "chart.bar", "deficit balance calories macros history", .trends),
            Tool("Weight log", "scalemass", "weigh in chart pounds kilograms progress", .weight),
            Tool("Diary history & export", "magnifyingglass", "find past foods CSV download", .history),
        ]),
        ("Settings", [
            Tool("Daily goal", "flag", "deficit calories percentage plan", .goals),
            Tool("Macro targets", "scope", "grams fat protein carbs", .macroGoals),
            Tool("Meal reminders", "bell", "notifications time", .reminders),
            Tool("Home shortcuts", "square.grid.2x2", "customize change buttons", .shortcuts),
        ])
    ]

    let open: (JournalSheet) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    var body: some View {
        NavigationStack {
            List {
                let words = search.split(whereSeparator: \.isWhitespace).map(String.init)
                let matches = Self.sections.map { section in
                    (section.name, section.tools.filter { tool in
                        let text = tool.title + " " + tool.keywords
                        return words.allSatisfy { text.localizedStandardContains($0) }
                    })
                }
                if matches.allSatisfy({ $0.1.isEmpty }) {
                    Text("No matching tools.").foregroundStyle(WarmInk.muted)
                }
                ForEach(matches.indices, id: \.self) { index in
                    if !matches[index].1.isEmpty {
                        Section(matches[index].0) {
                            ForEach(matches[index].1) { tool in
                                Button { open(tool.destination) } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: tool.icon).foregroundStyle(WarmInk.action).frame(width: 24)
                                        Text(tool.title).foregroundStyle(WarmInk.text)
                                        Spacer()
                                        Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
                                    }.contentShape(Rectangle())
                                }.accessibilityLabel(tool.title)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .navigationTitle("Diary tools")
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Find a tool")
            .toolbar { Button("Done") { dismiss() } }
        }.preferredColorScheme(.light).tint(WarmInk.action)
    }
}
