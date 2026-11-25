import SwiftUI

enum Nutrient: String, CaseIterable, Identifiable {
    case carbs = "Carbs", protein = "Protein", fat = "Fat"
    var id: Self { self }

    var field: KeyPath<Food, Int> {
        switch self {
        case .carbs: \.carbs
        case .protein: \.protein
        case .fat: \.fat
        }
    }

    var color: Color {
        switch self {
        case .carbs: Color(red: 1, green: 0.69, blue: 0.28)
        case .protein: Color(red: 0.73, green: 0.54, blue: 0.98)
        case .fat: Color(red: 0.36, green: 0.80, blue: 0.95)
        }
    }
}

struct Intake {
    let entries: [Entry]
    var energy: Int { entries.reduce(0) { $0 + $1.energy } }
    func grams(_ nutrient: Nutrient) -> Int {
        entries.reduce(0) { $0 + $1.servings * $1.food[keyPath: nutrient.field] }
    }
    private func macroEnergy(_ nutrient: Nutrient) -> Int {
        grams(nutrient) * (nutrient == .fat ? 9 : 4)
    }
    func share(_ nutrient: Nutrient) -> Double {
        let total = Nutrient.allCases.reduce(0) { $0 + macroEnergy($1) }
        return total == 0 ? 0 : Double(macroEnergy(nutrient)) / Double(total)
    }
}

// The length of each color band follows its energy share. A curved coordinate
// field bends the boundaries while the stops keep adjacent colors feathered.
private struct CardWash: View, Animatable {
    var carbs: Double
    var protein: Double
    var fat: Double
    var strength: Double
    var animatableData: AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<Double, Double>> {
        get { .init(.init(carbs, protein), .init(fat, strength)) }
        set {
            carbs = newValue.first.first
            protein = newValue.first.second
            fat = newValue.second.first
            strength = newValue.second.second
        }
    }

    var body: some View {
        Canvas { ctx, size in
            let sum = carbs + protein + fat
            let silver = Color(red: 0.90, green: 0.91, blue: 0.94)
            let bounds = CGRect(origin: .zero, size: size)
            ctx.fill(Path(bounds), with: .color(silver))
            if sum > 0.0001 {
                let bands = [(carbs, Nutrient.carbs), (protein, .protein), (fat, .fat)].filter { $0.0 > 0.00001 }
                var stops: [Gradient.Stop] = []
                var cursor = 0.0
                for (weight, nutrient) in bands {
                    let portion = weight / sum
                    stops.append(.init(color: nutrient.color, location: cursor + 0.29 * portion))
                    stops.append(.init(color: nutrient.color, location: cursor + 0.70 * portion))
                    cursor += portion
                }
                let gradient = Gradient(stops: stops)
                var ink = ctx
                ink.opacity = min(sum, 1) * strength
                // Overlap scanlines to avoid antialias seams on fractional display scales.
                for y in stride(from: 0.0, to: size.height, by: 1) {
                    let v = y / max(1, size.height)
                    let drift = (0.18 * cos(v * .pi) + 0.08 * sin(v * 2 * .pi)) * size.width
                    ink.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1.1)),
                             with: .linearGradient(gradient, startPoint: CGPoint(x: drift, y: y),
                                                   endPoint: CGPoint(x: size.width + drift, y: y)))
                }
            }
            ctx.fill(Path(bounds), with: .linearGradient(
                Gradient(stops: [.init(color: .white.opacity(0.60), location: 0),
                                 .init(color: .white.opacity(0.09), location: 0.65),
                                 .init(color: .white.opacity(0.38), location: 1)]),
                startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
        }.accessibilityHidden(true)
    }
}

struct NutritionCard: View {
    let intake: Intake
    let reflectionEnabled: Bool
    let showMix: () -> Void
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Nutrition", systemImage: "fork.knife").font(.headline)
                Spacer()
                Button(action: showMix) {
                    Image(systemName: "info.circle").font(.title3)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }.accessibilityLabel("About card colors")
            }
            Spacer(minLength: 25)
            Text("Dietary Energy").font(.subheadline.weight(.medium))
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(intake.energy, format: .number).font(.system(size: 48, weight: .bold, design: .rounded))
                    .tracking(-2).lineLimit(1).minimumScaleFactor(0.7)
                Text("kcal").font(.headline)
            }
            Text("of 2,000 kcal").font(.subheadline)
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 20)
        .frame(maxWidth: .infinity, minHeight: 196, alignment: .leading)
        .foregroundStyle(Color(white: 0.11))
        .background {
            CardWash(carbs: intake.share(.carbs), protein: intake.share(.protein), fat: intake.share(.fat),
                     strength: 0.55 + 0.45 * min(1, Double(intake.energy) / 2000))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.55),
                           value: Nutrient.allCases.map(intake.grams))
                .overlay {
                    CardFoil(active: reflectionEnabled && scenePhase == .active && !reduceMotion,
                             silver: Nutrient.allCases.allSatisfy { intake.grams($0) == 0 })
                        .accessibilityHidden(true)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(.black.opacity(0.06)) }
    }
}
