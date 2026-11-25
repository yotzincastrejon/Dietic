import SwiftUI

/// Shared masthead for the journal’s secondary pages.
struct JournalHeading: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 7) {
                Text(title).font(.system(.largeTitle, design: .serif).weight(.medium)).tracking(-1)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle).font(.subheadline).foregroundStyle(WarmInk.onHeaderSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 22).padding(.vertical, 18)
            .foregroundStyle(WarmInk.paper)
            .background(LinearGradient(colors: [WarmInk.header, WarmInk.headerBase], startPoint: .top, endPoint: .bottom))
            ReceiptEdge().fill(WarmInk.headerBase).frame(height: 6).accessibilityHidden(true)
        }
    }
}

extension View {
    func journalPage() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(WarmInk.paper).foregroundStyle(WarmInk.text).tint(WarmInk.action)
            .toolbarBackground(WarmInk.header, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct JournalActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity, minHeight: 49)
            .foregroundStyle(WarmInk.paper).background(WarmInk.action, in: Capsule())
            .opacity(enabled ? (configuration.isPressed ? 0.8 : 1) : 0.45)
    }
}

enum JournalSheet: Identifiable {
    case search, scan, plate, date, goals, plan
    case quickAdd, history, trends, savedMeals, dayDetails, reminders, water, macroGoals, scanLabel, planner, weight, groceries, repeatMeal, shortcuts, tools
    case saveTemplate(String, [HKSampleWithDescription])
    case received(SharedMeal)
    case sharing(String, [HKSampleWithDescription])
    case mealDate(MealDateAction, String, [HKSampleWithDescription], Date)

    var id: String {
        switch self {
        case .search: return "search"
        case .scan: return "scan"
        case .plate: return "plate"
        case .date: return "date"
        case .goals: return "goals"
        case .plan: return "plan"
        case .macroGoals: return "macroGoals"
        case .scanLabel: return "scanLabel"
        case .planner: return "planner"
        case .groceries: return "groceries"
        case .repeatMeal: return "repeatMeal"
        case .shortcuts: return "shortcuts"
        case .tools: return "tools"
        case .weight: return "weight"
        case .water: return "water"
        case .reminders: return "reminders"
        case .quickAdd: return "quickAdd"
        case .history: return "history"
        case .trends: return "trends"
        case .savedMeals: return "savedMeals"
        case .dayDetails: return "dayDetails"
        case .saveTemplate(let name, _): return "saveMeal-" + name
        case .received(let meal): return meal.id.uuidString
        case .sharing(let title, _): return "share-" + title
        case .mealDate(let action, let title, _, _): return action.rawValue + "-" + title
        }
    }
    var isScan: Bool { if case .scan = self { return true }; return false }
}

private enum HomeShortcut: String, CaseIterable {
    case plate = "Scan plate", scan = "Scan barcode", quickAdd = "Quick add", label = "Scan label"
    case water = "Water", groceries = "My groceries", meals = "Saved meals", repeatMeal = "Repeat a meal"

    var symbol: String {
        switch self {
        case .plate: return "camera"
        case .scan: return "barcode.viewfinder"
        case .quickAdd: return "bolt"
        case .label: return "text.viewfinder"
        case .water: return "drop"
        case .groceries: return "basket"
        case .meals: return "book.closed"
        case .repeatMeal: return "arrow.clockwise"
        }
    }
    var route: JournalSheet {
        switch self {
        case .plate: return .plate
        case .scan: return .scan
        case .quickAdd: return .quickAdd
        case .label: return .scanLabel
        case .water: return .water
        case .groceries: return .groceries
        case .meals: return .savedMeals
        case .repeatMeal: return .repeatMeal
        }
    }
}

struct Home: View {
    @ObservedObject var fastingManager: FastingManager
    let plan: NutritionPlan
    let savePlan: (NutritionPlan) -> Void
    @Binding var incoming: SharedMeal?
    @Binding var shortcut: DiaryShortcut?
    let chooseMealFile: () -> Void
    @AppStorage("home.primaryShortcut") private var middleShortcut = HomeShortcut.plate
    @AppStorage("home.secondaryShortcut") private var trailingShortcut = HomeShortcut.scan
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var route: JournalSheet?
    @State private var editing: HKSampleWithDescription?
    @State private var removing: HKSampleWithDescription?

    private var entries: [HKSampleWithDescription] { fastingManager.theSamples }
    private var goal: Int { plan.calorieGoal(for: fastingManager.dailyEnergy) ?? 0 }
    private var macroTargets: DailyMacroTargets { plan.targets(for: fastingManager.dailyEnergy) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Dietic").italic().font(.system(size: 29, weight: .semibold, design: .serif)).tracking(-1)
                        Spacer()
                        journalTools
                        Button { route = .date } label: {
                            HStack(spacing: 7) {
                                Image(systemName: "calendar")
                                Text(fastingManager.todaysDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                                Image(systemName: "chevron.down").font(.caption2)
                            }.font(.subheadline.weight(.medium)).frame(minHeight: 44)
                        }.accessibilityLabel("Choose diary date")
                        .accessibilityValue(fastingManager.todaysDate.formatted(date: .complete, time: .omitted))
                        .accessibilityAdjustableAction { direction in
                            switch direction {
                            case .increment: fastingManager.moveDay(by: 1)
                            case .decrement: fastingManager.moveDay(by: -1)
                            @unknown default: break
                            }
                        }
                    }
                    Rectangle().fill(WarmInk.onHeaderSecondary.opacity(0.4)).frame(height: 1)
                    DailyIntake(eaten: Int(fastingManager.consumedCalories.rounded()), goal: goal,
                                carbs: fastingManager.carbohydrates, protein: fastingManager.protein,
                                fat: fastingManager.fat, targets: macroTargets, showGoals: { route = .goals })
                }
                .padding(.horizontal, 23).padding(.bottom, 16)
                .foregroundStyle(WarmInk.paper)
                .background(LinearGradient(colors: [WarmInk.header, WarmInk.headerBase],
                                           startPoint: .top, endPoint: .bottom))
                ReceiptEdge().fill(WarmInk.headerBase).frame(height: 7).accessibilityHidden(true)
                EnergyBalance(energy: fastingManager.dailyEnergy, plan: plan, showGoal: { route = .goals })
                    .padding(.horizontal, 18).padding(.top, 14)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Meals").font(.system(.title, design: .serif).weight(.medium)).accessibilityAddTraits(.isHeader)
                        Spacer()
                        Button(action: chooseMealFile) {
                            Image(systemName: "tray.and.arrow.down").frame(width: 44, height: 44)
                        }.accessibilityLabel("Import meal file")
                        Text(entries.count == 1 ? "1 entry" : "\(entries.count) entries")
                            .font(.subheadline.monospacedDigit()).foregroundStyle(WarmInk.muted)
                    }.padding(.bottom, 6)
                    if entries.isEmpty {
                        Text("Log a food to start this day.").font(.callout)
                            .foregroundStyle(WarmInk.muted).padding(.vertical, 24)
                    }
                    ForEach(EatingTime.allCases, id: \.self) { meal in
                        let items = entries.filter { $0.mealPeriod == meal.description }
                        if !items.isEmpty {
                            MealSection(meal: meal, entries: items,
                                        edit: { editing = $0 }, remove: { removing = $0 }, share: presentShare, changeDate: presentMealDate, saveTemplate: presentTemplate)
                        }
                    }
                    let other = entries.filter { item in
                        !EatingTime.allCases.contains { $0.description == item.mealPeriod }
                    }
                    if !other.isEmpty {
                        MealSection(meal: nil, entries: other, edit: { editing = $0 }, remove: { removing = $0 }, share: presentShare, changeDate: presentMealDate, saveTemplate: presentTemplate)
                    }
                }
                .id(Calendar.current.startOfDay(for: fastingManager.todaysDate))
                .padding(.horizontal, 23).padding(.top, 14).padding(.bottom, 12)
                .foregroundStyle(WarmInk.text)
            }
        }
        .simultaneousGesture(DragGesture(minimumDistance: 24).onEnded { drag in
            let horizontal = drag.translation.width
            guard abs(horizontal) >= 60, abs(horizontal) > abs(drag.translation.height) * 1.5 else { return }
            fastingManager.moveDay(by: horizontal > 0 ? -1 : 1)
        })
        .background { WarmInk.paper.ignoresSafeArea(edges: .bottom) }
        .background { WarmInk.header.ignoresSafeArea() }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 9) {
                Button { route = .search } label: {
                    Label("Log food", systemImage: "plus").font(.headline).frame(maxWidth: .infinity, minHeight: 49)
                        .background(WarmInk.action, in: Capsule()).foregroundStyle(WarmInk.paper)
                }
                shortcutButton(middleShortcut, showName: !typeSize.isAccessibilitySize)
                shortcutButton(trailingShortcut, showName: false)
            }.padding(.horizontal, 22).padding(.vertical, 8).background(WarmInk.paper)
        }
        .buttonStyle(.plain).foregroundStyle(WarmInk.text)
        .preferredColorScheme(.dark)
        .sheet(item: $route) { sheet in
            switch sheet {
            case .tools:
                JournalToolsView { route = $0 }
            case .shortcuts:
                NavigationStack {
                    Form {
                        shortcutPicker("Middle button", selection: $middleShortcut, other: $trailingShortcut)
                        shortcutPicker("Right button", selection: $trailingShortcut, other: $middleShortcut)
                        Button("Restore default buttons") { middleShortcut = .plate; trailingShortcut = .scan }
                    }
                    .navigationTitle("Home shortcuts")
                    .scrollContentBackground(.hidden).background(WarmInk.paper)
                    .toolbar { Button("Done") { route = nil } }
                }.tint(WarmInk.action).preferredColorScheme(.light)
            case .scanLabel:
                NutritionLabelScanView(manager: fastingManager)
            case .macroGoals:
                MacroTargetEditor(plan: plan, energy: fastingManager.dailyEnergy) { updated in
                    savePlan(updated)
                    route = .goals
                }
            case .planner:
                MealPlannerView(manager: fastingManager)
            case .groceries:
                GroceryLibraryView(manager: fastingManager)
            case .repeatMeal:
                DiaryArchiveView(manager: fastingManager, endDay: fastingManager.todaysDate, repeatMeals: true)
            case .weight:
                WeightDiaryView(manager: fastingManager)
            case .water:
                WaterDiaryView(manager: fastingManager)
            case .reminders:
                MealRemindersView()
            case .quickAdd:
                QuickAddView(manager: fastingManager)
            case .history:
                DiaryArchiveView(manager: fastingManager, endDay: fastingManager.todaysDate)
            case .trends:
                DiaryTrendsView(manager: fastingManager)
            case .savedMeals:
                SavedMealsView(manager: fastingManager)
            case .saveTemplate(let meal, let entries):
                SaveMealTemplateView(mealName: meal, entries: entries)
            case .dayDetails:
                DiaryDayDetails(date: fastingManager.todaysDate, entries: entries)
            case .mealDate(let action, let title, let entries, let sourceDay):
                MealDateView(action: action, title: title, entries: entries, sourceDay: sourceDay, manager: fastingManager)
            case .sharing(let title, let entries):
                ShareMealView(title: title, entries: entries)
            case .received(let received):
                ReceiveMealView(shared: received, manager: fastingManager)
            case .plate:
                PlateScanView(manager: fastingManager)
            case .search, .scan:
                NavigationStack {
                    AddMoreFoodView(fastingManager: fastingManager, mealPeriod: EatingTime.current,
                                    rootIsActive: Binding(get: { route != nil }, set: { if !$0 { route = nil } }),
                                    scan: sheet.isScan)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) { Button("Close") { route = nil } }
                        }
                }
                .preferredColorScheme(.light).tint(WarmInk.action).presentationDragIndicator(.visible)
            case .date:
                VStack(spacing: 0) {
                    JournalHeading(title: "Diary date")
                    if !Calendar.current.isDateInToday(fastingManager.todaysDate) {
                        Button("Jump to today") { fastingManager.selectDay(.now); route = nil }
                            .frame(minHeight: 44)
                    }
                    ScrollView {
                        DiaryCalendar(manager: fastingManager) { date in
                            fastingManager.selectDay(date)
                            route = nil
                        }.padding(.horizontal, 20)
                    }
                }
                .background(WarmInk.paper).presentationDetents([.height(515), .large])
                .presentationDragIndicator(.visible).tint(WarmInk.action).preferredColorScheme(.light)
            case .plan:
                WelcomeView(plan: plan, energy: fastingManager.dailyEnergy, onReview: {},
                            save: { savePlan($0); route = .goals },
                            closeTitle: "Cancel", close: { route = .goals })
            case .goals:
                NavigationStack {
                    ScrollView {
                        JournalHeading(title: "Daily goal", subtitle: fastingManager.todaysDate.formatted(date: .complete, time: .omitted))
                        VStack(alignment: .leading, spacing: 18) {
                            if goal > 0 {
                                Text("\(goal.formatted()) kcal").font(.system(.largeTitle, design: .serif))
                            }
                            LabeledContent("Goal", value: plan.goal.planTitle)
                            LabeledContent("Macro focus", value: plan.focus.title)
                            Button { route = .plan } label: {
                                Label("Edit my plan", systemImage: "slider.horizontal.3")
                            }
                            Button { route = .macroGoals } label: {
                                Label("Customize macro targets", systemImage: "scope")
                            }
                            Divider()
                            LabeledContent("Active energy", value: fastingManager.dailyEnergy.active.map { "\(Int($0.rounded()).formatted()) kcal" } ?? "Unavailable")
                            if fastingManager.dailyEnergy.bmr == nil {
                                Text("The daily estimate needs weight, height, date of birth, and biological sex from Apple Health.")
                                    .font(.callout).foregroundStyle(WarmInk.muted)
                            }
                            Text(plan.overrides == nil ? plan.focus.formula + " Carbs use the remaining calories." : "Your custom macro targets take priority over the plan formula.")
                                .font(.callout).foregroundStyle(WarmInk.muted)
                            if goal > 0 && macroTargets.protein != nil && macroTargets.carbs == nil {
                                Text("Your protein and fat targets already exceed this calorie goal, so a carb target is unavailable.")
                                    .font(.callout).foregroundStyle(WarmInk.muted)
                            }
                            if fastingManager.hasRecordedWeight {
                                Divider()
                                WeightCard(fastingManager: fastingManager)
                            }
                        }.padding(22)
                    }
                    .journalPage()
                    .toolbar { Button("Done") { route = nil } }
                }
                .preferredColorScheme(.light).tint(WarmInk.action)
            }
        }
        .sheet(item: $editing, onDismiss: presentIncoming) { entry in
            NavigationStack {
                EditingResultsView(fastingManager: fastingManager, sample: entry)
            }.preferredColorScheme(.light).tint(WarmInk.action)
        }
        .onAppear(perform: presentIncoming)
        .onChange(of: incoming?.id) { _ in presentIncoming() }
        .onAppear(perform: presentShortcut)
        .onChange(of: shortcut) { _ in presentShortcut() }
        .alert("Delete this entry?", isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } }),
               presenting: removing) { entry in
            Button("Delete", role: .destructive) { fastingManager.deleteTheCorrelationObject(uuid: entry.uuid) }
            Button("Cancel", role: .cancel) {}
        } message: { entry in Text(entry.foodName) }
    }

    private func shortcutButton(_ shortcut: HomeShortcut, showName: Bool) -> some View {
        Button { route = shortcut.route } label: {
            HStack(spacing: 6) {
                Image(systemName: shortcut.symbol)
                if showName { Text(shortcut.rawValue).lineLimit(1).minimumScaleFactor(0.8) }
            }.font(.headline).padding(.horizontal, showName ? 12 : 15).frame(minWidth: 46, minHeight: 49)
                .foregroundStyle(WarmInk.action).background(WarmInk.apricot.opacity(0.34), in: Capsule())
        }
        .accessibilityLabel(shortcut.rawValue)
        .contextMenu {
            Button { route = .shortcuts } label: { Label("Customize home shortcuts", systemImage: "slider.horizontal.3") }
        }
    }

    private func shortcutPicker(_ title: String, selection: Binding<HomeShortcut>, other: Binding<HomeShortcut>) -> some View {
        Picker(title, selection: Binding(get: { selection.wrappedValue }, set: { next in
            if other.wrappedValue == next { other.wrappedValue = selection.wrappedValue }
            selection.wrappedValue = next
        })) {
            ForEach(HomeShortcut.allCases, id: \.self) { action in
                Label(action.rawValue, systemImage: action.symbol).tag(action)
            }
        }.pickerStyle(.navigationLink)
    }

    private var journalTools: some View {
        Button { route = .tools } label: {
            Image(systemName: "ellipsis.circle").font(.title3).frame(minWidth: 44, minHeight: 44)
        }.accessibilityLabel("Diary tools")
    }

    private func presentTemplate(_ title: String, entries: [HKSampleWithDescription]) {
        route = .saveTemplate(title, entries.sorted { $0.date < $1.date })
    }

    private func presentMealDate(_ action: MealDateAction, title: String, entries: [HKSampleWithDescription]) {
        route = .mealDate(action, title, entries.sorted { $0.date < $1.date }, fastingManager.todaysDate)
    }

    private func presentShare(_ title: String, entries: [HKSampleWithDescription]) {
        route = .sharing(title, entries.sorted { $0.date < $1.date })
    }

    private func presentShortcut() {
        guard let shortcut else { return }
        self.shortcut = nil
        editing = nil
        removing = nil
        fastingManager.selectDay(.now)
        switch shortcut {
        case .today: route = nil
        case .barcode: route = .scan
        case .plate: route = .plate
        case .quickAdd: route = .quickAdd
        }
    }

    private func presentIncoming() {
        guard let incoming else { return }
        if editing != nil { editing = nil; return }
        removing = nil
        route = .received(incoming)
        self.incoming = nil
    }
}

private struct EnergyBalance: View {
    let energy: DailyEnergy
    let plan: NutritionPlan
    let showGoal: () -> Void

    @State private var showsBurnDetails = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if energy.estimatedMaintenance != nil {
                let layout = typeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                    : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))
                let rate = plan.selectedFixedDeficit == nil ? abs(1 - plan.multiplier).formatted(.percent.precision(.fractionLength(0))) : "Fixed"
                layout {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Estimated balance").font(.caption.weight(.medium)).foregroundStyle(WarmInk.muted)
                        Text(balanceText(energy.deficit)).font(.system(.title3, design: .serif).weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("diary-energy-balance")
                    VStack(alignment: typeSize.isAccessibilitySize ? .leading : .trailing, spacing: 3) {
                        Text("Daily target · \(rate)").font(.caption.weight(.medium)).foregroundStyle(WarmInk.muted)
                        Text(balanceText(plan.targetBalance(for: energy)))
                            .font(.subheadline.weight(.medium).monospacedDigit())
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("diary-energy-target")
                }
            } else {
                Button(action: showGoal) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Energy balance").font(.system(.title3, design: .serif).weight(.semibold))
                            Text("Daily estimate unavailable").font(.caption).foregroundStyle(WarmInk.muted)
                        }
                        Spacer()
                        Text("View goal")
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "chevron.right").font(.caption2)
                    }
                    .frame(minHeight: 44).contentShape(Rectangle())
                }
            }
            Rectangle().fill(WarmInk.action.opacity(0.18)).frame(height: 1).padding(.top, 8)
            Button {
                showsBurnDetails.toggle()
            } label: {
                HStack {
                    Label("Calories burned", systemImage: "flame").foregroundStyle(WarmInk.muted)
                    Spacer()
                    Text(energy.recordedBurn.map { "\(Int($0.rounded()).formatted()) kcal" } ?? "Unavailable")
                        .fontWeight(.medium).monospacedDigit()
                    Image(systemName: showsBurnDetails ? "chevron.up" : "chevron.down").font(.caption2)
                }
                .font(.subheadline).frame(minHeight: 44).contentShape(Rectangle())
            }
            .accessibilityValue(showsBurnDetails ? "Expanded" : "Collapsed")
            if showsBurnDetails {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 16) { breakdown }
                    VStack(alignment: .leading, spacing: 4) { breakdown }
                }.padding(.bottom, 10)
            }
        }
        .padding(.horizontal, 14).padding(.top, 12)
        .background(WarmInk.apricot.opacity(0.18), in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(WarmInk.text)
    }

    private func balanceText(_ deficit: Double?) -> String {
        guard let deficit else { return "Unavailable" }
        let kcal = Int(deficit.rounded())
        if kcal == 0 { return "Break even · 0 kcal" }
        return kcal > 0 ? "\(kcal.formatted()) kcal deficit" : "\(abs(kcal).formatted()) kcal surplus"
    }

    @ViewBuilder private var breakdown: some View {
        metric("Active", energy.active)
        metric("Resting", energy.resting)
    }

    private func metric(_ name: String, _ value: Double?) -> some View {
        Text(name + " " + (value.map { "\(Int($0.rounded()).formatted()) kcal" } ?? "unavailable"))
            .font(.subheadline.monospacedDigit()).foregroundStyle(WarmInk.muted).fixedSize(horizontal: false, vertical: true)
    }
}

private struct DailyIntake: View {
    let eaten: Int
    let goal: Int
    let carbs: Double
    let protein: Double
    let fat: Double
    let targets: DailyMacroTargets
    let showGoals: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            let summaryLayout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                : AnyLayout(HStackLayout(alignment: .center, spacing: 8))
            summaryLayout {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Daily intake").font(.caption).foregroundStyle(WarmInk.onHeaderSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(eaten, format: .number).font(.system(.largeTitle, design: .serif)).monospacedDigit()
                        Text("kcal").font(.system(.headline, design: .serif).italic())
                            .foregroundStyle(WarmInk.onHeaderSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: showGoals) {
                    VStack(alignment: typeSize.isAccessibilitySize ? .leading : .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(goal > 0 ? "Goal \(goal.formatted()) kcal" : "Daily goal")
                            Image(systemName: "chevron.right").font(.caption2)
                        }.font(.subheadline.weight(.medium))
                        Text(goal > 0 ? (eaten > goal ? "\((eaten - goal).formatted()) kcal over" : "\((goal - eaten).formatted()) kcal left") : "Goal unavailable")
                            .font(.caption).foregroundStyle(WarmInk.onHeaderSecondary)
                    }.frame(minHeight: 44)
                }.accessibilityLabel("Daily goal settings")
                .accessibilityValue(goal > 0 ? "\(goal) kilocalories" : "Goal unavailable")
            }

            IntakeChart(amount: Double(eaten), target: goal > 0 ? Double(goal) : nil)
                .padding(.top, 6)

            let macroLayout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
                : AnyLayout(HStackLayout(alignment: .top, spacing: 14))
            macroLayout {
                macro("Carbs", carbs, target: targets.carbs)
                macro("Protein", protein, target: targets.protein)
                macro("Fat", fat, target: targets.fat)
            }.padding(.top, 10)
        }
    }

    private func macro(_ label: String, _ grams: Double, target: Double?) -> some View {
        let total = Int(grams.rounded())
        let targetGrams = target.map { Int($0.rounded()) }
        return VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.weight(.semibold))
            IntakeChart(amount: grams, target: target, miniature: true)
            Text(targetGrams.map { "\(total.formatted()) / \($0.formatted()) g" } ?? "\(total.formatted()) g · No target")
                .font(.caption.monospacedDigit()).foregroundStyle(WarmInk.onHeaderSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityValue(targetGrams.map { Text("\(total) of \($0) grams") } ?? Text("\(total) grams, no target"))
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
    let meal: EatingTime?
    let entries: [HKSampleWithDescription]
    let edit: (HKSampleWithDescription) -> Void
    let remove: (HKSampleWithDescription) -> Void
    let share: (String, [HKSampleWithDescription]) -> Void
    let changeDate: (MealDateAction, String, [HKSampleWithDescription]) -> Void
    let saveTemplate: (String, [HKSampleWithDescription]) -> Void

    @State private var expanded = false

    private var calories: Int { Int(entries.reduce(0) { $0 + $1.calories }.rounded()) }

    private var title: String { meal?.description ?? "Other" }
    private var symbol: String {
        switch meal {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "moon.stars"
        case .snack: return "carrot"
        case nil: return "fork.knife"
        }
    }

    @ViewBuilder private var mealActions: some View {
        Button { changeDate(.copy, title, entries) } label: {
            Label("Copy meal", systemImage: "doc.on.doc").frame(minHeight: 44)
        }
        Button { changeDate(.move, title, entries) } label: {
            Label("Move meal", systemImage: "calendar.badge.clock").frame(minHeight: 44)
        }
        Button { saveTemplate(title, entries) } label: {
            Label("Save meal", systemImage: "bookmark").frame(minHeight: 44)
        }
        Button { share(meal?.description ?? "Meal", entries) } label: {
            Label("Share meal", systemImage: "square.and.arrow.up").frame(minHeight: 44)
        }
    }

    private var foodPreview: String {
        var names = Set<String>()
        return entries.sorted { $0.date < $1.date }
            .map(\.foodName)
            .filter { !$0.isEmpty && names.insert($0).inserted }
            .prefix(2).joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                expanded.toggle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: symbol)
                        .font(.body.weight(.medium)).foregroundStyle(WarmInk.action)
                        .frame(width: 33, height: 33)
                        .background(WarmInk.apricot.opacity(0.25), in: Circle())
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.headline)
                        if !expanded {
                            Text(foodPreview).font(.caption).foregroundStyle(WarmInk.muted).lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(calories.formatted()) kcal").font(.subheadline.weight(.medium).monospacedDigit())
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption2).foregroundStyle(WarmInk.muted)
                }
                .padding(.vertical, 4).frame(minHeight: 49).contentShape(Rectangle())
            }
            .accessibilityLabel(Text(title))
            .accessibilityValue("\(entries.count) entries, \(calories) kilocalories, \(expanded ? "expanded" : "collapsed")")
            if expanded {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), alignment: .leading)], alignment: .leading, spacing: 0) {
                    mealActions
                }.font(.subheadline.weight(.medium)).foregroundStyle(WarmInk.action)
                ForEach(entries.sorted { $0.date < $1.date }) { item in
                    Button { edit(item) } label: {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.foodName).font(.body.weight(.medium))
                                if Restaurant.brandNames.contains(item.brandName) {
                                    Text(item.brandName).font(.caption).foregroundStyle(WarmInk.muted)
                                }
                                Text(item.portion.description(quantity: item.numberOfServings, measuredInGrams: item.servingSelection == ServingType.gram.description))
                                    .font(.caption).foregroundStyle(WarmInk.muted)
                            }
                            Spacer()
                            Text("\(Int(item.calories.rounded()))").font(.body.monospacedDigit())
                                .accessibilityLabel("\(Int(item.calories.rounded())) kilocalories")
                        }.frame(minHeight: 44).contentShape(Rectangle())
                    }
                    .contextMenu {
                        Button("Edit entry") { edit(item) }
                        Button("Copy entry to another day") { changeDate(.copy, item.foodName, [item]) }
                        Button("Move entry to another day") { changeDate(.move, item.foodName, [item]) }
                        Button("Delete entry", role: .destructive) { remove(item) }
                    }
                }
            }
            Rectangle().fill(WarmInk.text.opacity(0.13)).frame(height: 1)
        }
    }
}
