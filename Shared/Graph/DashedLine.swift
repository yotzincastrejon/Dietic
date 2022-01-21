//
//  DashedLine.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/22/21.
//

import SwiftUI

struct DashedLine: View {
    var body: some View {
        HStack {
            HStack(spacing: 2) {
                ForEach((0...80), id: \.self) {_ in
                    Capsule()
                        .fill(Color(uiColor: .systemGray3))
                        .frame(width: 2, height: 1)
                }
                Spacer()
                
            }
            .frame(width: 345)
            Spacer()
        }
    }
}

struct DashedLine_Previews: PreviewProvider {
    static var previews: some View {
        DashedLine()
    }
}
