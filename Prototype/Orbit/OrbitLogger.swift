import SwiftUI

struct OrbitLogger: View {
    let meal: Meal
    let scan: Bool
    let save: (Food, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var servings = 1
    @State private var selection: Food?

    private var results: [Food] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return term.isEmpty ? Food.catalog : Food.catalog.filter { $0.name.localizedCaseInsensitiveContains(term) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(scan ? "Scan barcode" : "Log \(meal.rawValue.lowercased())")
                        .font(.largeTitle.weight(.semibold))
                    if scan {
                        VStack(spacing: 17) {
                            Image(systemName: "barcode.viewfinder").font(.system(size: 65, weight: .light))
                                .foregroundStyle(JournalInk.iceBlue)
                            Text("Sample Sprite mini can").font(.headline)
                            Text("049000061062").font(.body.monospaced())
                            Button("Use sample barcode") { choose(.sprite) }.buttonStyle(OrbitButton())
                        }.padding(16).frame(maxWidth: .infinity)
                            .background(JournalInk.headerBase, in: RoundedRectangle(cornerRadius: 18))
                    } else {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            TextField("Find a food", text: $query).accessibilityLabel("Find a food")
                                .autocorrectionDisabled().submitLabel(.search)
                        }.padding(15).background(JournalInk.headerBase, in: RoundedRectangle(cornerRadius: 14))
                        if results.isEmpty { ContentUnavailableView.search(text: query) }
                        ForEach(results) { food in
                            Button { choose(food) } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(food.name).font(.headline)
                                        Text(food.portion).font(.caption).foregroundStyle(JournalInk.onHeaderSecondary)
                                    }
                                    Spacer()
                                    Text("\(food.kcal) kcal").font(.caption.monospacedDigit())
                                    Image(systemName: "chevron.right").font(.caption2)
                                }.frame(minHeight: 46).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                            Divider()
                        }
                    }
                }.padding(20)
            }.background(JournalInk.header)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } } }
            .navigationDestination(item: $selection) { food in
                VStack(alignment: .leading, spacing: 22) {
                    Text(food.name).font(.largeTitle.weight(.semibold))
                    Text(food.portion).foregroundStyle(JournalInk.onHeaderSecondary)
                    Divider()
                    Stepper("Servings   \(servings)", value: $servings, in: 1...20)
                    HStack { Text("Calories"); Spacer(); Text("\(food.kcal * servings) kcal").font(.headline) }
                    Spacer()
                    Button("Add to \(meal.rawValue.lowercased())") { save(food, servings) }.buttonStyle(OrbitButton())
                }.padding(22).background(JournalInk.header).navigationTitle(meal.rawValue)
            }
        }.tint(JournalInk.iceBlue).foregroundStyle(JournalInk.paper)
            .presentationDragIndicator(.visible)
    }

    private func choose(_ food: Food) {
        servings = 1
        selection = food
    }
}

private struct OrbitButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity, minHeight: 48)
            .background(JournalInk.iceBlue, in: Capsule()).foregroundStyle(JournalInk.header)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
