import SwiftUI

struct DietOptionsSegementedControl: View {
    @State var dietGoal: DietGoal = .maintaining
    @State var deficitLevel: DietDeficitLevel = .normal
    @State private var previousDietGoalTitle = ""
    @State private var deficitOffset: CGFloat = -100
    @State private var maintainingOffset: CGFloat = 0
    @State private var gainOffset: CGFloat = 100
    @State private var agressiveOffset: CGFloat = 100
    @State private var normalOffset: CGFloat = 0
    @State private var lightOffset: CGFloat = -100
    @State private var isShowingSheet = false
    var body: some View {
        VStack {
            VStack {
                ZStack {
                    Text("Deficit")
                        .font(.headline)
                        .offset(x: 0, y: deficitOffset)
                    Text("Maintaining")
                        .font(.headline)
                        .offset(x: 0, y: maintainingOffset)
                    Text("Gain")
                        .font(.headline)
                        .offset(x: 0, y: gainOffset)
                }

                if case .deficit = dietGoal {
                    ZStack {
                        Text("Light")
                            .font(.caption)
                            .offset(x: lightOffset, y: 0)
                        Text("Normal")
                            .font(.caption)
                            .offset(x: normalOffset, y: 0)
                        Text("Aggressive")
                            .font(.caption)
                            .offset(x: agressiveOffset, y: 0)
                    }
                    .onChange(of: deficitLevel) { level in
                        withAnimation(.spring(response:0.35, dampingFraction:0.70, blendDuration:0)) {
                            switch deficitLevel {
                            case .light:
                                lightOffset = 0
                                normalOffset = 100
                                agressiveOffset = 100
                            case .normal:
                                lightOffset = -100
                                normalOffset = 0
                                agressiveOffset = 100
                            case .aggressive:
                                lightOffset = -100
                                normalOffset = -100
                                agressiveOffset = 0
                            }
                        }
                    }
                }
            }
            .padding()
            .background(LinearGradient(colors: dietGoalColor(dietGoal, deficitLevel), startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(Capsule())
            .onChange(of: dietGoal.title) { title in
                withAnimation(.spring(response:0.55, dampingFraction:0.70, blendDuration:0)) {
                    switch dietGoal {
                    case .deficit(_):
                        deficitOffset = 0
                        maintainingOffset = 100
                        gainOffset = 100
                    case .maintaining:
                        deficitOffset = -100
                        maintainingOffset = 0
                        gainOffset = 100
                    case .gain:
                        deficitOffset = -100
                        maintainingOffset = -100
                        gainOffset = 0
                    }
                }
            }
            .animation(.spring(response:0.55, dampingFraction:0.70, blendDuration:0), value: dietGoal)
            .onTapGesture {
                isShowingSheet.toggle()
            }
            .sheet(isPresented: $isShowingSheet) {
                DietGoalPicker(dietGoal: $dietGoal, deficitLevel: $deficitLevel)
                    .presentationDetents([.medium])
            }




        }
    }
    func dietGoalColor(_ goal: DietGoal, _ level: DietDeficitLevel) -> [Color] {
        switch goal {
        case .deficit(_):
            switch level {
            case .light:
                return [Color.yellow]
            case .normal:
                return [Color.red]
            case .aggressive:
                return [Color.purple, Color.green]
            }
        case .maintaining:
            return [Color.green]
        case .gain:
            return [Color.orange]
        }
    }
}

struct DietOptionsSegementedControl_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            DietOptionsSegementedControl()
            Spacer()
        }
    }
}

enum DietGoal: Hashable {
    case deficit(DietDeficitLevel)
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
        [.deficit(.normal),.maintaining, .gain]
    }
}

enum DietDeficitLevel: Hashable, CaseIterable {
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

struct DietGoalPicker: View {
    @Binding var dietGoal: DietGoal
    @Binding var deficitLevel: DietDeficitLevel
    var body: some View {
        VStack {
            Text("Select your diet goal: \(dietGoal.title)")
            Picker(selection: $dietGoal, label: Text("")) {
                ForEach(DietGoal.allCases, id: \.self) { goal in
                    Text(goal.title).tag(goal)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            if case .deficit = dietGoal {
                Group {
                    Text("Select your deficit level:")
                    Picker(selection: $deficitLevel, label: Text("")) {
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

