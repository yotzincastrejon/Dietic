import SwiftUI

struct DietOptionsSegementedControl: View {
    @State var dietGoal: DietGoal = .maintaining
    @State var deficitLevel: DietDeficitLevel = .normal

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



        }
    }
}

struct DietOptionsSegementedControl_Previews: PreviewProvider {
    static var previews: some View {
        DietOptionsSegementedControl()
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
    case aggressive
    case normal
    case light

    var title: String {
        switch self {
        case .aggressive:
            return "Aggressive"
        case .normal:
            return "Normal"
        case .light:
            return "Light"
        }
    }
}
