//
//  TextTest.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 3/8/22.
//

import SwiftUI

struct TextTest: View {
    var body: some View {
        GeometryReader { g in
            VStack {
                VStack {
                    Text("Hello World")
                        .font(.system(size: g.size.width))
                        .lineLimit(1)
                        .minimumScaleFactor(0.005)
                    Text("Hello")
                        .font(.title)
                    Text("Hello")
                        .font(.title3)
                }
                .frame(width: 50)
                .background(.blue)
                
                
            }
            .frame(width: g.size.width, height: g.size.height)
        }
    }
}

struct TextTest_Previews: PreviewProvider {
    static var previews: some View {
        TextTest()
    }
}
