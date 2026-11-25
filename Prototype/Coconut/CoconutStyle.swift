import SwiftUI

enum Coconut {
    static let milk = Color(red: 0.985, green: 0.980, blue: 0.963)
    static let linen = Color(red: 0.932, green: 0.910, blue: 0.867)
    static let shell = Color(red: 0.248, green: 0.198, blue: 0.161)
    static let taupe = Color(red: 0.400, green: 0.369, blue: 0.326)
    static let oak = Color(red: 0.610, green: 0.490, blue: 0.360)
    static let rule = Color(red: 0.825, green: 0.800, blue: 0.745)
    static let palette = FoodLogPalette(paper: milk, text: shell, muted: taupe, action: shell, accent: oak)
}

// A cut coconut in profile, drawn at the size of a wordmark.
struct CoconutMark: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            var shell = Path()
            shell.move(to: CGPoint(x: 0, y: h * 0.33))
            shell.addQuadCurve(to: CGPoint(x: w, y: h * 0.33), control: CGPoint(x: w / 2, y: h * 1.53))
            shell.closeSubpath()
            ctx.fill(shell, with: .color(Coconut.shell))
            let rim = CGRect(x: 0.6, y: h * 0.13, width: w - 1.2, height: h * 0.35)
            ctx.fill(Path(ellipseIn: rim), with: .color(Coconut.milk))
            ctx.stroke(Path(ellipseIn: rim), with: .color(Coconut.shell), lineWidth: 1.1)
        }.rotationEffect(.degrees(-18))
    }
}
