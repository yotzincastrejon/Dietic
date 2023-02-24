import SwiftUI

struct DietOptionsSegementedControl: View {
    @Binding var dietGoal: DietGoal
    @Binding var deficitLevel: DietDeficitLevel
    @State private var previousDietGoalTitle = ""
    @AppStorage("deficitOffset") var deficitOffset: Double = -100
    @AppStorage("maintainingOffset") var maintainingOffset: Double = 0
    @AppStorage("gainOffset") var gainOffset: Double = 100
    @AppStorage("agressiveOffset") var agressiveOffset: Double = 100
    @AppStorage("normalOffset") var normalOffset: Double = 0
    @AppStorage("lightOffset") var lightOffset: Double = -100
    @State private var isShowingSheet = false
    @State private var expandedBackgroundIsShowing = true
    @State private var isWorkItemCancelled = false
    @State private var hasFinished = true
    @State private var subcategoryChanged = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Capsule()
                    .foregroundStyle(.linearGradient(colors: dietGoalColor(dietGoal, deficitLevel), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .opacity(expandedBackgroundIsShowing ? 1 : 0)

                Capsule()
                    .stroke(.linearGradient(colors: dietGoalColor(dietGoal, deficitLevel), startPoint: .topLeading, endPoint: .bottomTrailing))
                VStack {
                    if deficitLevel == .light {
                        Text("Deficit")
                            .font(.headline)
                            .foregroundStyle(.linearGradient(colors: expandedBackgroundIsShowing ? [Color.black] : dietGoalColor(dietGoal, deficitLevel), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .offset(x: 0, y: deficitOffset)
                    } else {
                        Text("Deficit")
                            .font(.headline)
                            .foregroundStyle(.linearGradient(colors: expandedBackgroundIsShowing ? [Color.white] : dietGoalColor(dietGoal, deficitLevel), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .offset(x: 0, y: deficitOffset)
                    }

                    if case .deficit = dietGoal {
                        ZStack {
                            Text("Light")
                                .font(.caption)
                                .foregroundStyle(.linearGradient(colors: expandedBackgroundIsShowing ? [Color.black] : dietGoalColor(dietGoal, deficitLevel), startPoint: .topLeading, endPoint: .bottomTrailing))
                                .offset(x: lightOffset, y: 0)
                            Text("Normal")
                                .font(.caption)
                                .foregroundStyle(.linearGradient(colors: expandedBackgroundIsShowing ? [Color.white] : dietGoalColor(dietGoal, deficitLevel), startPoint: .topLeading, endPoint: .bottomTrailing))
                                .offset(x: normalOffset, y: 0)
                            Text("Aggressive")
                                .font(.caption)
                                .foregroundStyle(.linearGradient(colors: expandedBackgroundIsShowing ? [Color.white] : dietGoalColor(dietGoal, deficitLevel), startPoint: .topLeading, endPoint: .bottomTrailing))
                                .offset(x: agressiveOffset, y: 0)
                        }
                        .onChange(of: deficitLevel) { level in
                            withAnimation(.spring(response:0.35, dampingFraction:0.8, blendDuration:0)) {
                                switch deficitLevel {
                                case .light:
                                    lightOffset = 0
                                    normalOffset = 100
                                    agressiveOffset = 100
                                    if !hasFinished {
                                        isWorkItemCancelled = true
                                    }
                                    toggleExpandedBackgroundForSubCategories()
                                    //                                        toggleExpandedBackground()
                                case .normal:
                                    lightOffset = -100
                                    normalOffset = 0
                                    agressiveOffset = 100
                                    if !hasFinished {
                                        isWorkItemCancelled = true
                                    }
                                    toggleExpandedBackgroundForSubCategories()

                                    //                                        toggleExpandedBackground()
                                case .aggressive:
                                    lightOffset = -100
                                    normalOffset = -100
                                    agressiveOffset = 0
                                    if !hasFinished {
                                        isWorkItemCancelled = true
                                    }
                                    toggleExpandedBackgroundForSubCategories()

                                    //                                        toggleExpandedBackground()
                                }
                            }
                        }
                    }
                }
                Text("Maintaining")
                    .font(.headline)
                    .foregroundStyle(.linearGradient(colors: expandedBackgroundIsShowing ? [Color.white] : dietGoalColor(dietGoal, deficitLevel), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .offset(x: 0, y: maintainingOffset)
                Text("Gain")
                    .font(.headline)
                    .foregroundStyle(.linearGradient(colors: expandedBackgroundIsShowing ? [Color.white] : dietGoalColor(dietGoal, deficitLevel), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .offset(x: 0, y: gainOffset)
            }


        }.onAppear(perform: toggleExpandedBackground)

        //            .padding(expandedBackgroundIsShowing ? 15 : 0)
        .clipShape(Capsule())
        .onChange(of: dietGoal.title) { title in
            withAnimation(.spring(response:0.55, dampingFraction:0.8, blendDuration:0)) {
                switch dietGoal {
                case .deficit:
                    deficitOffset = 0
                    maintainingOffset = 100
                    gainOffset = 100
                    if !hasFinished {
                        isWorkItemCancelled = true
                    }
                    toggleExpandedBackground()
                case .maintaining:
                    deficitOffset = -100
                    maintainingOffset = 0
                    gainOffset = 100
                    if !hasFinished {
                        isWorkItemCancelled = true
                    }
                    toggleExpandedBackground()
                case .gain:
                    deficitOffset = -100
                    maintainingOffset = -100
                    gainOffset = 0
                    if !hasFinished {
                        isWorkItemCancelled = true
                    }
                    toggleExpandedBackground()
                }
            }
        }
        //            .animation(.spring(response:0.55, dampingFraction:0.70, blendDuration:0), value: dietGoal)
        .onTapGesture {
            isShowingSheet.toggle()
        }
        .sheet(isPresented: $isShowingSheet) {
            DietGoalPicker(dietGoal: $dietGoal, deficitLevel: $deficitLevel)
                .presentationDetents([.medium])
        }
        .frame(width: 120, height: 50)

    }
    func dietGoalColor(_ goal: DietGoal, _ level: DietDeficitLevel) -> [Color] {
        switch goal {
        case .deficit:
            switch level {
            case .light:
                return [Color(hex: "B9B7E3"),
                        Color(hex: "FFE1E6")]
            case .normal:
                return [Color.purple, Color(hex: "7D7BDB")]
            case .aggressive:
                return [Color.purple, Color(hex: "FF4500")]
            }
        case .maintaining:
            return [Color.green, Color.mint]
        case .gain:
            return [Color.red, Color.orange]
        }
    }

    func toggleExpandedBackground() {
        hasFinished = false
        expandedBackgroundIsShowing = true
        let workItem = DispatchWorkItem {
            if !isWorkItemCancelled {
                withAnimation(.linear(duration: 0.6)) {
                    expandedBackgroundIsShowing = false
                }
                hasFinished = true
            } else {
                isWorkItemCancelled = false
                hasFinished = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
    }

    func toggleExpandedBackgroundForSubCategories() {
        hasFinished = false

        expandedBackgroundIsShowing = true

        let workItem = DispatchWorkItem {
            if !isWorkItemCancelled {
                withAnimation(.linear(duration: 0.6)) {
                    expandedBackgroundIsShowing = false
                }
                hasFinished = true
            } else {
                isWorkItemCancelled = false
                hasFinished = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
    }
}

struct DietOptionsSegementedControlPreview: View {
    @State var dietGoal: DietGoal = .maintaining
    @State var deficitLevel: DietDeficitLevel = .normal
    var body: some View {
        DietOptionsSegementedControl(dietGoal: $dietGoal, deficitLevel: $deficitLevel)
    }
}

struct DietOptionsSegementedControl_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            DietOptionsSegementedControlPreview()
            Spacer()
        }
    }
}


struct DietGoalPicker: View {
    @Binding var dietGoal: DietGoal
    @Binding var deficitLevel: DietDeficitLevel

    var body: some View {
        VStack {
            Text("Select your diet goal: \(dietGoal.title)")
            Picker("", selection: $dietGoal) {
                ForEach(DietGoal.allCases, id: \.self) { goal in
                    Text(goal.title).tag(goal)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            if case .deficit = dietGoal {
                Group {
                    Text("Select your deficit level:")
                    Picker("",selection: $deficitLevel) {
                        ForEach(DietDeficitLevel.allCases, id: \.self) { level in
                            Text(level.title).tag(level)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                Text("Selected Level: \(deficitLevel.title)")
            }

            Spacer()
        }
        .padding(.top)
    }
}


enum DietGoal: String, Hashable, CaseIterable {
    case deficit
    case maintaining
    case gain

    var title: String {
        switch self {
        case .deficit:
            return "Deficit"
        case .maintaining:
            return "Maintaining"
        case .gain:
            return "Gain"
        }
    }

    static var allCases: [DietGoal] {
        [.deficit,.maintaining, .gain]
    }
}

enum DietDeficitLevel: String, Hashable, CaseIterable {
    case light
    case normal
    case aggressive

    var title: String {
        switch self {
        case .light:
            return "Light"
        case .normal:
            return "Normal"
        case .aggressive:
            return "Aggressive"
        }
    }
}
