//
//  TextGraph.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/22/21.
//

import SwiftUI

struct TextGraph: View {
    var body: some View {
        VStack {
            HStack {
                HStack {
                    VStack {
                        Spacer()
                        HStack(alignment: .center, spacing: 16) {
                            Text("T")
                                .frame(width: 14, height: 16)
                            Text("F")
                                .frame(width: 14, height: 16)
                            Text("S")
                                .frame(width: 14, height: 16)
                            Text("S")
                                .frame(width: 14, height: 16)
                            Text("M")
                                .frame(width: 14, height: 16)
                            Text("T")
                                .frame(width: 14, height: 16)
                            Text("W")
                                .frame(width: 14, height: 16)
                            Text("T")
                                .frame(width: 14, height: 16)
                            Text("KCAL")
                                .frame(width: 32, height: 16)
                                .padding(.leading, 23)
                        }
                        .font(Font.custom("Inter", size: 12))
                        .foregroundColor(Color.blue)
                        .padding(.bottom, 28)
                        
                    }
                    .padding(.leading, 26)
                    Spacer()
                }
                .frame(width: 345, height: 237)
                Spacer()
            }
            Spacer()
        }
    }
}
struct TextGraph_Previews: PreviewProvider {
    static var previews: some View {
        TextGraph()
    }
}
