//
//  BarGraphBackground.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/22/21.
//

import SwiftUI

struct BarGraphBackground: View {
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    RoundedCorners(color: [Color(uiColor: .secondarySystemGroupedBackground)], tl: 0, tr: 8, bl: 0, br: 8)
                        .frame(width: 345, height: 237)
//                        .modifier(Shadow(level: 3))
                    Spacer()
                }
                Spacer()
            }
            VStack {
                
                VStack(spacing: 23) {
                    ForEach((1...6), id: \.self) { _ in
                        DashedLine()
                    }
                    HStack {
                        Capsule()
                            .fill(Color(uiColor: .systemGray3))
                        .frame(width: 322, height: 1)
                        Spacer()
                    }
                }
                .padding(.top, 40)
                Spacer()
            }
            
            HStack {
                HStack {
                    Spacer()
                    VStack {
                        VStack(alignment: .trailing,spacing: 0) {
                            ForEach((0...6).reversed(), id: \.self) {i in
                                Text("\(i * 500)")
                                    .font(.caption2)
                                    .foregroundColor(Color.blue)
                                    .padding(.bottom, 9.4)
                            }
                        }.padding(.top, 24)
                        Spacer()
                    }
                    .padding(.trailing, 2)
                    
                }
                .frame(width: 322)
                Spacer()
            }
        }
    }
}

struct BarGraphBackground_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            BarGraphBackground()
        }
        BarGraphBackground()
            .preferredColorScheme(.dark)
    }
}

