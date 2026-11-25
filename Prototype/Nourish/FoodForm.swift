import SwiftUI

struct FoodForm: View {
    let scan: Bool
    let save: (Food, Meal, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var meal: Meal
    @State private var path: [Food] = []
    @State private var query = ""
    @State private var count = 1

    init(initialMeal: Meal?, scan: Bool, save: @escaping (Food, Meal, Int) -> Void) {
        self.scan = scan
        self.save = save
        let hour = Calendar.current.component(.hour, from: .now)
        let suggested: Meal = switch hour {
        case 5..<11: .breakfast
        case 11..<16: .lunch
        case 16..<21: .dinner
        default: .snack
        }
        _meal = State(initialValue: initialMeal ?? suggested)
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if scan {
                    List {
                        Section("Sample barcode") {
                            Label("Sprite mini can", systemImage: "barcode.viewfinder")
                            Text("049000061062").font(.body.monospacedDigit())
                            Button("Use sample barcode") { choose(.sprite) }
                        }
                    }
                } else {
                    let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
                    let foods = Food.catalog.filter { term.isEmpty || $0.name.localizedCaseInsensitiveContains(term) }
                    List {
                        Section("Foods") {
                            ForEach(foods) { food in
                                Button { choose(food) } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(food.name).foregroundStyle(.primary)
                                            Text(food.portion).font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text("\(food.kcal) kcal").font(.subheadline).foregroundStyle(.secondary)
                                    }.contentShape(Rectangle())
                                }.buttonStyle(.plain)
                            }
                        }
                    }.searchable(text: $query, prompt: "Food or brand")
                        .overlay { if foods.isEmpty { ContentUnavailableView.search(text: query) } }
                }
            }
            .navigationTitle(scan ? "Scan barcode" : "Log food")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .navigationDestination(for: Food.self) { food in
                Form {
                    Section(food.portion) {
                        Picker("Meal", selection: $meal) {
                            ForEach(Meal.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Stepper("Servings   \(count)", value: $count, in: 1...20)
                    }
                    Section {
                        LabeledContent("Dietary Energy", value: "\(count * food.kcal) kcal")
                        ForEach(Nutrient.allCases) { nutrient in
                            LabeledContent(nutrient.rawValue, value: "\(count * food[keyPath: nutrient.field]) g")
                        }
                    }
                }
                .navigationTitle(food.name)
                .toolbar { ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save(food, meal, count) }.fontWeight(.semibold)
                } }
            }
        }
    }

    private func choose(_ food: Food) {
        count = 1
        path.append(food)
    }
}
