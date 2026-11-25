import SwiftUI

enum LogRoute: String, Identifiable {
    case search, scan
    var id: Self { self }
}

struct FoodLogPalette {
    let paper: Color
    let text: Color
    let muted: Color
    let action: Color
    let accent: Color

    static let journal = FoodLogPalette(paper: JournalInk.paper, text: JournalInk.text,
                                        muted: JournalInk.muted, action: JournalInk.action,
                                        accent: JournalInk.violet)
}

struct JournalLogger: View {
    let start: LogRoute
    let palette: FoodLogPalette
    let save: (Food, Meal, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var food: Food?
    @State private var servings = 1
    @State private var meal: Meal

    init(start: LogRoute, palette: FoodLogPalette = .journal, initialMeal: Meal? = nil,
         save: @escaping (Food, Meal, Int) -> Void) {
        self.start = start
        self.palette = palette
        self.save = save
        _meal = State(initialValue: initialMeal ?? Self.mealForCurrentHour)
    }

    private static var mealForCurrentHour: Meal {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<11: .breakfast
        case 11..<16: .lunch
        case 16..<21: .dinner
        default: .snack
        }
    }

    private var results: [Food] {
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return term.isEmpty ? Food.catalog : Food.catalog.filter { $0.name.localizedCaseInsensitiveContains(term) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(start == .scan ? "Scan barcode" : "Log food")
                        .font(.system(size: 39, weight: .medium, design: .serif)).tracking(-1.5)
                    if start == .scan {
                        VStack(spacing: 18) {
                            Image(systemName: "barcode.viewfinder").font(.system(size: 75, weight: .light))
                                .accessibilityHidden(true)
                            Text("Sprite mini can").font(.headline)
                            Text("049000061062").font(.body.monospaced())
                            Button("Use sample barcode") { food = .sprite }.buttonStyle(JournalAction(palette: palette))
                        }.padding(22).frame(maxWidth: .infinity)
                            .background(palette.accent.opacity(0.38), in: RoundedRectangle(cornerRadius: 18))
                    } else {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            TextField("Find a food", text: $search).accessibilityLabel("Find a food")
                                .autocorrectionDisabled().submitLabel(.search)
                        }
                        .padding(14).background(.white, in: RoundedRectangle(cornerRadius: 12))
                        if results.isEmpty {
                            ContentUnavailableView.search(text: search)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(results) { result in
                                    Button { food = result } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(result.name).font(.headline)
                                                Text(result.portion).font(.caption).foregroundStyle(palette.muted)
                                            }
                                            Spacer()
                                            Text("\(result.kcal) kcal").font(.subheadline.monospacedDigit())
                                            Image(systemName: "chevron.right").font(.caption2)
                                        }.padding(.vertical, 12).contentShape(Rectangle())
                                    }.buttonStyle(.plain)
                                    Divider()
                                }
                            }
                        }
                    }
                }.padding(.horizontal, 22).padding(.bottom, 22)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(palette.paper)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } } }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $food) { chosen in
                VStack(alignment: .leading, spacing: 21) {
                    Text(chosen.name).font(.system(size: 40, weight: .medium, design: .serif)).tracking(-1.4)
                    Text(chosen.portion).foregroundStyle(palette.muted)
                    Divider()
                    Picker("Meal", selection: $meal) {
                        ForEach(Meal.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    Stepper(value: $servings, in: 1...20) {
                        Text("Servings   \(servings)").font(.headline.monospacedDigit())
                    }
                    Divider()
                    HStack(alignment: .firstTextBaseline) {
                        Text("Total").font(.headline)
                        Spacer()
                        Text("\(chosen.kcal * servings) kcal").font(.system(size: 30, design: .serif))
                    }
                    Spacer()
                    Button("Add to \(meal.rawValue.lowercased())") { save(chosen, meal, servings) }
                        .buttonStyle(JournalAction(palette: palette))
                }
                .padding(22).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(palette.paper)
            }
        }
        .foregroundStyle(palette.text).tint(palette.action)
        .presentationDragIndicator(.visible)
    }
}

private struct JournalAction: ButtonStyle {
    let palette: FoodLogPalette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).foregroundStyle(palette.paper)
            .frame(maxWidth: .infinity).padding(.vertical, 15)
            .background(palette.action, in: Capsule()).opacity(configuration.isPressed ? 0.8 : 1)
    }
}
