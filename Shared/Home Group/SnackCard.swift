//
//  SnackCard.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/20/21.
//

import SwiftUI

struct SnackCard: View {
    
    var body: some View {
        ZStack {
            
            
            LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 1, green: 0.6745098039, blue: 0.7764705882, alpha: 1)), Color(#colorLiteral(red: 1, green: 0.2862745098, blue: 0.5058823529, alpha: 1))]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .mask(RoundedCorners(color: [.blue], tl: 8, tr: 100, bl: 8, br: 8))
                .shadow(color: Color(#colorLiteral(red: 1, green: 0.2862745098, blue: 0.5058823529, alpha: 1)).opacity(0.8), radius: 30, x: 4, y: 12)
                .scaleEffect(0.86)
            
            //Visibile View without shadow.
            LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 1, green: 0.6745098039, blue: 0.7764705882, alpha: 1)), Color(#colorLiteral(red: 1, green: 0.2862745098, blue: 0.5058823529, alpha: 1))]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .mask(RoundedCorners(color: [.blue], tl: 8, tr: 100, bl: 8, br: 8))
            
            
            
            VStack {
                HStack {
                    Circle()
                        .fill(.white).opacity(0.2)
                        .frame(width: 88,height: 88)
                    Spacer()
                }
                Spacer()
            }
            .offset(x: -13, y: -39)
            .mask(RoundedCorners(color: [.blue], tl: 8, tr: 100, bl: 8, br: 8))
            
            
            VStack {
                HStack {
                    Image("melon")
                        .frame(width: 64, height: 64)
                    
                    Spacer()
                }
                .padding(.leading, 4)
                Spacer()
            }
            .offset(x: 0, y: -21)
            .shadow(color: Color(#colorLiteral(red: 0.4980392157, green: 0, blue: 0.2431372549, alpha: 1)).opacity(0.44), radius: 16, x: 6, y: 10)
            
            
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    
                    Text("Snack")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 48)
                    Text("Recommend:")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 6)
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("800 kal")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.top, 3)
                    }
                    
                    Spacer()
                }
                .padding(.leading, 16)
                Spacer()
            }
            
            
        }
        .frame(width: 116, height: 178)
        
    }
}


struct SnackCard_Previews: PreviewProvider {
    static var previews: some View {
        SnackCard()
    }
}
