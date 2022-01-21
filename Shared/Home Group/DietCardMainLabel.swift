//
//  DietCardMainLabel.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/20/21.
//

import SwiftUI

struct DietCardMainLabel: View {
    let barColor: Color
    let text: String
    let image: String
    @Binding var amount: Double
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .frame(width: 2, height: 42)
                .foregroundColor(barColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Image(image)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding(.trailing, 8)
                    Text(String(format: "%0.0f", amount))
                        .font(.title2)
                    Text("kcal")
                        .font(.caption2)
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .padding(.leading, 2)
                }
            }
        }
    }
}

struct DietCardMainLabel_Previews: PreviewProvider {
    static var previews: some View {
        DietCardMainLabel(barColor: .blue, text: "Eaten", image: "Eaten", amount: Binding.constant(0.45))
    }
}
