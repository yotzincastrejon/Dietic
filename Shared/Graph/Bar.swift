//
//  Bar.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/22/21.
//

import SwiftUI

struct Bar: View {
    var height: Int
    var body: some View {
        RoundedCorners(color: [Color.mint, Color.blue], tl: 2, tr: 2, bl: 0, br: 0)
            .frame(width: 6, height: CGFloat(height))
            
    }
}

struct Bar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CompleteGraph()
            CompleteGraph()
                .preferredColorScheme(.dark)
        }
    }
}


