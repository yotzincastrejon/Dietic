//
//  MacroLabel.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/20/21.
//

import SwiftUI

struct MacroLabel: View {
    let text: String
    var backgroundColor: Color
    var foregroundGradient: [Color]
    var percentage: Double
    var remaining: Int
    var body: some View {
        
        VStack(alignment: .leading, spacing: 5) {
            Text(text)
                .font(.subheadline)
            ZStack {
                Capsule()
                    .fill(backgroundColor)
                    .frame(width: 56, height: 4)
                Capsule()
                    .fill(LinearGradient(colors: foregroundGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 4)
                    .offset(x: -56 * (1 - maxPercent(percent: percentage)))
                    .clipShape(Capsule())
                    .animation(.easeInOut(duration: 1), value: maxPercent(percent: percentage))
            }
            if percentage < 1 {
            Text("\(remaining)g left")
                    .font(.caption2)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            } else {
                Text("Goal Met!")
                    .font(.caption2)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
        }.frame(width: 56)
        
     
    }
    
    func maxPercent(percent: Double) -> Double {
        guard percent > 0 else { return 0.0 }
        guard percent <= 1 else { return 1.0 }
        return percent
    }
}

//struct MacroLabel_Previews: PreviewProvider {
//    static var previews: some View {
//        MacroLabel()
//    }
//}
