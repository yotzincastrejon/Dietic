//
//  ArrowViewGraph.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/22/21.
//

import SwiftUI

struct ArrowViewGraph: View {
    @Binding var position: Int
    var body: some View {
        VStack {
            HStack {
                HStack {
                    VStack {
                        Spacer()
                        HStack {
                            Image("Arrow Up")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Color(uiColor: .systemGray))
                                .frame(width: 16, height: 16)
                                .padding(.leading, (14 + 16) * CGFloat(position))
                            
                        }
                        .padding(.bottom, 12)
                        .animation(.spring(), value: position)
                    }
                    .padding(.leading, 25)
                    Spacer()
                }
                .frame(width: 345, height: 237)
                Spacer()
            }
            Spacer()
        }
    }
}

struct ArrowViewGraph_Previews: PreviewProvider {
    static var previews: some View {
        ArrowViewGraph(position: Binding.constant(7))
    }
}
