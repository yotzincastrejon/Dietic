import SwiftUI

enum WarmInk {
    static let header = Color(red: 0.40, green: 0.18, blue: 0.23)
    static let headerBase = Color(red: 0.30, green: 0.13, blue: 0.18)
    static let paper = Color(red: 1.00, green: 0.97, blue: 0.92)
    static let text = Color(red: 0.23, green: 0.14, blue: 0.16)
    static let muted = Color(red: 0.43, green: 0.33, blue: 0.31)
    static let onHeaderSecondary = Color(red: 0.94, green: 0.81, blue: 0.77)
    static let apricot = Color(red: 1.00, green: 0.66, blue: 0.48)
    static let honey = Color(red: 1.00, green: 0.82, blue: 0.46)
    static let action = Color(red: 0.59, green: 0.25, blue: 0.16)

}

struct IntakeChart: View {
    let amount: Double
    let target: Double?
    var miniature = false

    private var progress: Double {
        guard let target, target >= 0, amount > 0 else { return 0 }
        return target == 0 ? 1 : min(1, amount / target)
    }

    var body: some View {
        Canvas { context, size in
            let count = miniature ? 17 : 43
            let step = size.width / CGFloat(count)
            let gap = min(miniature ? 2.0 : 3.0, step / 2)
            let width = (size.width - CGFloat(count - 1) * gap) / CGFloat(count)
            let filled = Int((Double(count) * progress).rounded())
            let highlight = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [WarmInk.apricot, WarmInk.honey]), startPoint: .zero,
                endPoint: CGPoint(x: max(width, CGFloat(filled) * (width + gap) - gap), y: 0)
            )
            for index in 0..<count {
                let rect = CGRect(x: CGFloat(index) * (width + gap), y: 0, width: width, height: size.height)
                let shading: GraphicsContext.Shading = index < filled ? highlight : .color(WarmInk.onHeaderSecondary.opacity(0.23))
                context.fill(Path(roundedRect: rect, cornerRadius: 1), with: shading)
            }
        }
        .frame(height: miniature ? 9 : 17)
        .accessibilityHidden(true)
    }
}
