import SwiftUI

extension Meal {
    var moonColor: Color {
        switch self {
        case .breakfast: Color(red: 0.70, green: 0.60, blue: 1)
        case .lunch: JournalInk.iceBlue
        case .dinner: Color(red: 0.55, green: 0.55, blue: 1)
        case .snack: Color(red: 0.91, green: 0.67, blue: 1)
        }
    }

    // Positions in the orbital plane, measured from the ascending node.
    var orbit: (radius: CGFloat, angle: Double) {
        switch self {
        case .breakfast: (0.36, 205)
        case .lunch: (0.46, 322)
        case .dinner: (0.36, 30)
        case .snack: (0.46, 133)
        }
    }
}

struct MealOrbit: View {
    @Binding var selected: Meal
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading) {
                ForEach(Meal.allCases) { meal in moonButton(meal) }
            }
        } else {
            GeometryReader { proxy in
                let size = proxy.size
                let center = CGPoint(x: size.width / 2, y: size.height * 0.46)
                ZStack {
                    Canvas { ctx, _ in
                        for i in 0..<90 {
                            // Two deterministic sequences keep stars fixed during interactions.
                            let x = (Double(i) * 0.754877666).truncatingRemainder(dividingBy: 1) * size.width
                            let y = (Double(i) * 0.569840296 + 0.3).truncatingRemainder(dividingBy: 1) * size.height
                            let side: CGFloat = i.isMultiple(of: 7) ? 1.65 : 0.9
                            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: side, height: side)),
                                     with: .color(.white.opacity(i.isMultiple(of: 7) ? 0.65 : 0.34)))
                        }
                        for radius in [0.36, 0.46] {
                            var orbit = Path()
                            for degree in stride(from: 0, through: 360, by: 2) {
                                let p = position(radius: radius, angle: Double(degree), size: size, center: center)
                                if degree == 0 { orbit.move(to: p) } else { orbit.addLine(to: p) }
                            }
                            orbit.closeSubpath()
                            ctx.stroke(orbit, with: .color(JournalInk.violet.opacity(0.43)), lineWidth: 0.8)
                        }
                    }.accessibilityHidden(true)
                    let diameter = min(size.width * 0.33, 136)
                    Circle().fill(JournalInk.action.opacity(0.62)).frame(width: diameter + 15, height: diameter + 15)
                        .blur(radius: 27).position(center)
                    // Voyager 2 photograph of Neptune. NASA/JPL, PIA01492.
                    Image("Neptune").resizable().scaledToFit().frame(width: diameter * 1.17)
                        .blendMode(.screen).position(center).accessibilityHidden(true)
                    ForEach(Meal.allCases) { meal in
                        let p = position(radius: meal.orbit.radius, angle: meal.orbit.angle, size: size, center: center)
                        moonButton(meal).position(x: p.x, y: p.y + 9)
                    }
                }
            }.frame(height: 226)
        }
    }

    private func position(radius: CGFloat, angle: Double, size: CGSize, center: CGPoint) -> CGPoint {
        let theta = angle * .pi / 180
        let tilt = -16.0 * .pi / 180
        let x = size.width * radius * cos(theta)
        let y = size.height * radius * 0.77 * sin(theta)
        return CGPoint(x: center.x + x * cos(tilt) - y * sin(tilt),
                       y: center.y + x * sin(tilt) + y * cos(tilt))
    }

    private func moonButton(_ meal: Meal) -> some View {
        Button { selected = meal } label: {
            VStack(spacing: 3) {
                ZStack {
                    if selected == meal {
                        Circle().strokeBorder(meal.moonColor, lineWidth: 1).frame(width: 32, height: 32)
                    }
                    Circle().fill(RadialGradient(colors: [.white, meal.moonColor, JournalInk.headerBase],
                                                 center: .init(x: 0.28, y: 0.23), startRadius: 0, endRadius: 20))
                        .frame(width: 21, height: 21).shadow(color: meal.moonColor.opacity(0.4), radius: 5)
                }.frame(height: 32)
                Text(meal.rawValue).font(.caption.weight(selected == meal ? .bold : .medium))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(JournalInk.header.opacity(0.85), in: Capsule())
            }.frame(minWidth: 48, minHeight: 48).contentShape(Rectangle())
        }
        .accessibilityLabel(meal.rawValue)
        .accessibilityHint("Show foods logged for this meal")
        .accessibilityAddTraits(selected == meal ? .isSelected : [])
    }
}
