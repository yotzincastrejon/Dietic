import SwiftUI

extension DietGoal {
    var planTitle: String {
        switch self {
        case .deficit: return "Lose fat"
        case .maintaining: return "Maintain weight"
        case .gain: return "Gain weight"
        }
    }
}

struct WelcomeView: View {
    @State private var draft: NutritionPlan
    @State private var step = 0
    @State private var usesFixedDeficit: Bool
    @State private var fixedAmount: String
    let energy: DailyEnergy
    let onReview: () -> Void
    let save: (NutritionPlan) -> Void
    let closeTitle: String
    let close: () -> Void

    init(plan: NutritionPlan, energy: DailyEnergy, onReview: @escaping () -> Void,
         save: @escaping (NutritionPlan) -> Void, closeTitle: String, close: @escaping () -> Void) {
        _draft = State(initialValue: plan)
        _usesFixedDeficit = State(initialValue: plan.fixedDeficit != nil)
        _fixedAmount = State(initialValue: plan.fixedDeficit?.formatted(.number.grouping(.never)) ?? "")
        self.energy = energy
        self.onReview = onReview
        self.save = save
        self.closeTitle = closeTitle
        self.close = close
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Dietic").italic().font(.system(.title, design: .serif).weight(.semibold))
                    Spacer()
                    Button(closeTitle, action: close).font(.subheadline).frame(minHeight: 44)
                }
                HStack(spacing: 5) {
                    ForEach(0..<3) { index in
                        Capsule().fill(index <= step ? WarmInk.honey : WarmInk.paper.opacity(0.25)).frame(height: 4)
                    }
                }.accessibilityHidden(true)
                Text(["1 of 3 · Goal", "2 of 3 · Macro focus", "3 of 3 · Your plan"][step])
                    .font(.caption.weight(.medium)).foregroundStyle(WarmInk.onHeaderSecondary)
            }
            .padding(.horizontal, 23).padding(.top, 8).padding(.bottom, 16)
            .foregroundStyle(WarmInk.paper).background(WarmInk.header)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(["What would you like to work on?", "What should your macros support?", "Your daily targets"][step])
                        .font(.system(.largeTitle, design: .serif).weight(.medium))
                        .fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
                        .padding(.bottom, 4)
                    switch step {
                    case 0: goals
                    case 1: focus
                    default: review
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(23)
            }.id(step)
            HStack(spacing: 14) {
                if step > 0 {
                    Button("Back") { step -= 1 }.frame(minWidth: 54, minHeight: 49)
                }
                Button(step == 2 ? "Save my plan" : (step == 1 ? "Preview my plan" : "Continue")) {
                    if step == 2 { save(draft) } else {
                        if step == 1 { onReview() }
                        step += 1
                    }
                }.buttonStyle(JournalActionStyle())
                    .disabled(draft.goal == .deficit && usesFixedDeficit && !validFixedAmount)
            }.padding(.horizontal, 23).padding(.vertical, 8)
        }
        .background(WarmInk.paper).foregroundStyle(WarmInk.text)
        .tint(WarmInk.action).environment(\.colorScheme, .light).preferredColorScheme(.dark)
    }

    private var goals: some View {
        VStack(alignment: .leading, spacing: 9) {
            choice("Lose fat", "Set a calorie target below estimated maintenance.", "arrow.down.right", draft.goal == .deficit) { draft.goal = .deficit }
            choice("Maintain weight", "Aim to match your estimated daily burn.", "equal", draft.goal == .maintaining) { draft.goal = .maintaining }
            choice("Gain weight", "Aim for 10% above estimated maintenance.", "arrow.up.right", draft.goal == .gain) { draft.goal = .gain }
            if draft.goal == .deficit {
                Text("Daily deficit").font(.headline).padding(.top, 10)
                Picker("Target type", selection: $usesFixedDeficit) {
                    Text("Percentage").tag(false)
                    Text("Calories").tag(true)
                }.pickerStyle(.segmented)
                .onChange(of: usesFixedDeficit) { fixed in draft.fixedDeficit = fixed ? PortionInput.decimal(fixedAmount) : nil }
                if usesFixedDeficit {
                    HStack {
                        Text("Daily deficit")
                        TextField("Amount", text: $fixedAmount).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing).accessibilityLabel("Daily calorie deficit")
                        Text("kcal")
                    }
                    .onChange(of: fixedAmount) { text in draft.fixedDeficit = PortionInput.decimal(text) }
                    if !fixedAmount.isEmpty && !validFixedAmount {
                        Text("Enter a positive deficit below estimated maintenance.").font(.footnote).foregroundStyle(WarmInk.action)
                    }
                } else {
                    Picker("Daily deficit", selection: $draft.level) {
                        ForEach(DietDeficitLevel.allCases, id: \.self) { level in
                            Text((1 - DietGoal.deficit.multiplier(for: level)).formatted(.percent)).tag(level)
                        }
                    }.pickerStyle(.segmented)
                }
            }
        }
    }

    private var validFixedAmount: Bool {
        guard let value = PortionInput.decimal(fixedAmount), value >= 1, value <= 100_000 else { return false }
        return energy.estimatedMaintenance.map { value < $0 } ?? true
    }

    private var focus: some View {
        VStack(alignment: .leading, spacing: 9) {
            choice(MacroFocus.balanced.title, "Use Dietic’s original protein and fat targets.", "fork.knife", draft.focus == .balanced) { draft.focus = .balanced }
            choice(MacroFocus.strength.title, "Give protein a larger share for strength training.", "dumbbell", draft.focus == .strength) { draft.focus = .strength }
            choice(MacroFocus.endurance.title, "Set fat as a share of calories so carbs adjust with your training day.", "bicycle", draft.focus == .endurance) { draft.focus = .endurance }
            Text("Dietic uses your weight, profile and active energy from Apple Health to preview your targets.")
                .font(.footnote).foregroundStyle(WarmInk.muted).padding(.top, 9)
        }
    }

    private var review: some View {
        let calories = draft.calorieGoal(for: energy)
        let macros = draft.targets(for: energy)
        let adjustment = draft.selectedFixedDeficit.map { $0.formatted() + " kcal" } ?? abs(1 - draft.multiplier).formatted(.percent)
        return VStack(alignment: .leading, spacing: 14) {
            Text("\(draft.goal.planTitle) · \(draft.focus.title)").font(.headline)
            VStack(alignment: .leading, spacing: 10) {
                Text(draft.goal == .maintaining ? "Estimated maintenance" : "\(adjustment) \(draft.goal == .gain ? "above" : "below") estimated maintenance")
                    .font(.subheadline)
                if let calories {
                    Text("\(calories.formatted()) kcal").font(.system(.largeTitle, design: .serif))
                }
                if draft.goal != .maintaining, let balance = draft.targetBalance(for: energy) {
                    Text("\(abs(Int(balance.rounded())).formatted()) kcal target \(draft.goal == .deficit ? "deficit" : "surplus")")
                        .font(.footnote).foregroundStyle(WarmInk.muted)
                }
                Divider()
                targetLine("Protein", macros.protein)
                targetLine("Fat", macros.fat)
                targetLine("Carbs", macros.carbs)
            }.padding(16).background(WarmInk.apricot.opacity(0.2), in: RoundedRectangle(cornerRadius: 16))
            Text(draft.overrides == nil ? draft.focus.formula + " Carbs use the calories left over." : "Your custom macro targets take priority over the plan formula.").font(.subheadline)
            if calories == nil {
                Text("You can save this plan now. Calorie targets appear when Dietic can read your weight, height, age, sex and activity estimate from Apple Health.")
                    .font(.footnote).foregroundStyle(WarmInk.muted)
            } else if macros.carbs == nil {
                Text("This calorie goal leaves too little energy for the selected protein and fat targets. Go back to adjust your plan.")
                    .font(.footnote).foregroundStyle(WarmInk.muted)
            }
        }
    }

    private func targetLine(_ label: String, _ value: Double?) -> some View {
        LabeledContent(label, value: value.map { "\(Int($0.rounded()).formatted()) g" } ?? "Unavailable")
            .font(.subheadline.monospacedDigit())
    }

    private func choice(_ title: String, _ detail: String, _ symbol: String, _ selected: Bool,
                        action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.headline).foregroundStyle(WarmInk.action).frame(width: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(detail).font(.subheadline).foregroundStyle(WarmInk.muted)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? WarmInk.action : WarmInk.muted.opacity(0.65))
            }
            .padding(14).background(selected ? WarmInk.apricot.opacity(0.25) : WarmInk.paper, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(selected ? WarmInk.action : WarmInk.muted.opacity(0.3), lineWidth: selected ? 2 : 1))
            .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(Text(title)).accessibilityHint(Text(detail))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
