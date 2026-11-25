import SwiftUI

struct FoodLogger: View {
    let meal: Meal
    let recent: [Food]
    let add: (Food, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var selection: Food?
    @State private var scanner = false
    @State private var servings = 1

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 15) {
                        Art(meal: meal, size: 62)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(meal.rawValue).font(.subheadline.weight(.medium)).foregroundStyle(Style.muted)
                            Text("Add food").font(.largeTitle.bold())
                        }
                    }
                    HStack(spacing: 8) {
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundStyle(Style.muted)
                            TextField("Search food or brand", text: $query)
                                .accessibilityLabel("Search food or brand")
                                .autocorrectionDisabled().submitLabel(.search)
                            if !query.isEmpty {
                                Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
                                    .accessibilityLabel("Clear search")
                            }
                        }.padding(.horizontal, 13).frame(height: 50)
                            .background(.white, in: RoundedRectangle(cornerRadius: 15))
                        Button { scanner = true } label: {
                            Image(systemName: "barcode.viewfinder").font(.title2)
                                .frame(width: 50, height: 50).foregroundStyle(.white)
                                .background(Style.plum, in: RoundedRectangle(cornerRadius: 15))
                        }.accessibilityLabel("Scan barcode")
                    }
                    if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        foodList("Recently logged", foods: recent)
                        foodList("More foods", foods: Food.catalog.filter { !recent.contains($0) })
                    } else {
                        let results = Food.catalog.filter { $0.name.localizedCaseInsensitiveContains(query.trimmingCharacters(in: .whitespacesAndNewlines)) }
                        if results.isEmpty {
                            ContentUnavailableView.search(text: query)
                        } else {
                            foodList("Results", foods: results)
                        }
                    }
                }.padding(.horizontal, 22).padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $scanner) {
                VStack(spacing: 25) {
                    Image(systemName: "barcode.viewfinder").font(.system(size: 82, weight: .light))
                    Text("Barcode preview").font(.title.bold())
                    Text("Try the barcode from your Sprite mini can.").foregroundStyle(Style.muted)
                        .multilineTextAlignment(.center)
                    Text("049000061062").font(.body.monospacedDigit())
                    Button("Use sample barcode") { select(.sprite) }.buttonStyle(LogButton())
                }.padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Style.paper).navigationTitle("Scan barcode")
            }
            .navigationDestination(item: $selection) { food in
                VStack(alignment: .leading, spacing: 22) {
                    Art(meal: meal, size: 72)
                    VStack(alignment: .leading, spacing: 7) {
                        Text(food.name).font(.largeTitle.bold())
                        Text(food.portion).foregroundStyle(Style.muted)
                    }
                    HStack {
                        Text("Servings").font(.headline)
                        Spacer()
                        Text("\(servings)").monospacedDigit()
                        Stepper("Servings", value: $servings, in: 1...20).labelsHidden()
                    }
                    Divider()
                    HStack {
                        Text("Calories").font(.headline)
                        Spacer()
                        Text("\(food.kcal * servings) kcal").font(.headline)
                    }
                    Spacer()
                    Button("Add to \(meal.rawValue.lowercased())") { add(food, servings) }
                        .buttonStyle(LogButton())
                }.padding(22).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Style.paper).navigationTitle(meal.rawValue)
            }
            .background(Style.paper)
        }
        .tint(Style.ink).foregroundStyle(Style.ink)
        .presentationDragIndicator(.visible)
    }

    private func select(_ food: Food) {
        servings = 1
        selection = food
    }

    @ViewBuilder private func foodList(_ title: String, foods: [Food]) -> some View {
        if !foods.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                ForEach(foods) { food in
                    Button { select(food) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(food.name).font(.body.weight(.medium))
                                Text(food.portion).font(.caption).foregroundStyle(Style.muted)
                            }
                            Spacer()
                            Text("\(food.kcal) kcal").font(.caption.weight(.medium))
                            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(Style.muted)
                        }.padding(.vertical, 10).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                    Divider()
                }
            }
        }
    }
}

private struct LogButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).foregroundStyle(.white)
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(Style.plum, in: Capsule()).opacity(configuration.isPressed ? 0.8 : 1)
    }
}
