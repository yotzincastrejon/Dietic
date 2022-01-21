//
//  ProgressRingView.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/18/21.
//

import SwiftUI

struct ProgressRingView: View {
    
    @Binding var progress: Double
    
    var thickness: CGFloat = 30.0
//    var width: CGFloat = 250.0
    var dotOnTip: Bool
    var width: CGFloat
    var gradient = Gradient(colors: [Color.purple, Color.yellow])
    var startAngle = -90.0
    var backgroundCircleWidth: Int
    var backgroundCircleColor: Color
    private var radius: Double {
        Double(width / 2)
    }
    
    private var ringTipShadowOffset: CGPoint {
        let shadowPosition = ringTipPosition(progress: progress + 0.01)
        let circlePosition = ringTipPosition(progress: progress)
        
        return CGPoint(x: shadowPosition.x - circlePosition.x, y: shadowPosition.y - circlePosition.y)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(backgroundCircleColor, lineWidth: CGFloat(backgroundCircleWidth))

            RingShape(progress: progress, thickness: thickness)
                .fill(AngularGradient(gradient: gradient, center: .center, startAngle: .degrees(startAngle), endAngle: .degrees(360 * progress + startAngle)))
//                .shadow(color: Color("Shadowblue").opacity(0.40), radius: 12, x: 0, y: 3)
            
            RingTip(progress: progress, startAngle: startAngle, ringRadius: radius)
                .frame(width: thickness, height: thickness)
                .foregroundColor(progress > 0.96 ? gradient.stops[1].color : Color.clear)
                .shadow(color: progress > 0.96 ? Color.black.opacity(0.15) : Color.clear, radius: 2, x: ringTipShadowOffset.x, y: ringTipShadowOffset.y)
            if dotOnTip {
            RingTip(progress: progress, startAngle: startAngle, ringRadius: radius)
                .frame(width: 6, height: 6)
                .foregroundColor(Color(uiColor: .systemBackground))
            }
//                    .animation(Animation.easeInOut(duration: 1))
         }
        .frame(width: width, height: width, alignment: .center)
        .animation(.easeInOut(duration: 1), value: progress)
    }
    
//    private func getEndCircleShadowOffset(progress: Double) -> CGPoint {
//
//        let shadowLocation = arcEndPosition(progress: progress + 0.01)
//        let circleLocation = arcEndPosition(progress: progress)
//
//        return CGPoint(x: shadowLocation.x - circleLocation.x, y: shadowLocation.y - circleLocation.y)
//    }
    
  
    
    private func ringTipPosition(progress: Double) -> CGPoint {
        let angle = 360 * progress + startAngle
        let angleInRadian = angle * .pi / 180
        
        return CGPoint(x: radius * cos(angleInRadian), y: radius * sin(angleInRadian))
    }
}

struct RingShape: Shape {
    var progress: Double = 0.0
    var thickness: CGFloat = 30.0
    var startAngle: Double = -90.0
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        
        var path = Path()
        
        path.addArc(center: CGPoint(x: rect.width / 2.0, y: rect.height / 2.0),
                    radius: min(rect.width, rect.height) / 2.0,
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(360 * progress + startAngle), clockwise: false)
        
        return path.strokedPath(.init(lineWidth: thickness, lineCap: .round))
    }
}


struct RingTip: Shape {
    var progress: Double = 0.0
    var startAngle: Double = -90.0
    var ringRadius: Double
    
    private var position: CGPoint {
        let angle = 360 * progress + startAngle
        let angleInRadian = angle * .pi / 180
        
        return CGPoint(x: ringRadius * cos(angleInRadian), y: ringRadius * sin(angleInRadian))
    }
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard progress > 0.0 else {
            return path
        }
                
        let frame = CGRect(x: position.x, y: position.y, width: rect.size.width, height: rect.size.height)
        
        path.addRoundedRect(in: frame, cornerSize: frame.size)
        
        return path
    }

}

struct ProgressRingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProgressRingView(progress: .constant(0.75), dotOnTip: false, width: 250, backgroundCircleWidth: 4, backgroundCircleColor: .gray).previewLayout(.fixed(width: 300, height: 300))
            ProgressRingView(progress: .constant(1.25), dotOnTip: true, width: 250, backgroundCircleWidth: 4, backgroundCircleColor: .gray).previewLayout(.fixed(width: 300, height: 300))
            ProgressRingView(progress: .constant(1.0), dotOnTip: false, width: 250, backgroundCircleWidth: 4, backgroundCircleColor: .gray).previewLayout(.fixed(width: 300, height: 300))
        }
    }
}
