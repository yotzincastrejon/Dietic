//
//  ShadowLevels.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/20/21.
//

import SwiftUI

struct ShadowLevels: View {
    var body: some View {
        ZStack {
            Color(#colorLiteral(red: 0.9764705882, green: 0.9764705882, blue: 0.9803921569, alpha: 1))
                .ignoresSafeArea()
            VStack(spacing: 50) {
            //Level 1
            Rectangle()
                .frame(width: 120, height: 92)
                .foregroundColor(.white)
                .modifier(Shadow(level: 1))
                
                //Level 2
                Rectangle()
                    .frame(width: 120, height: 92)
                    .foregroundColor(.white)
                    .modifier(Shadow(level: 2))
                
                //Level 3
                Rectangle()
                    .frame(width: 120, height: 92)
                    .foregroundColor(.white)
                    .modifier(Shadow(level: 3))
                
                //Level 4
                Rectangle()
                    .frame(width: 120, height: 92)
                    .foregroundColor(.white)
                    .modifier(Shadow(level: 4))
                
                //Level 5
                Rectangle()
                    .frame(width: 120, height: 92)
                    .foregroundColor(.white)
                    .modifier(Shadow(level: 5))
            }
        }
    }
}

struct ShadowLevels_Previews: PreviewProvider {
    static var previews: some View {
        ShadowLevels()
    }
}

struct Shadow: ViewModifier {
    var level: Int
    
    func body(content: Content) -> some View {
        switch level {
        case 1:
            content
                .shadow(color: Color(#colorLiteral(red: 0.4352941176, green: 0.5607843137, blue: 0.9176470588, alpha: 1)).opacity(0.08), radius: 2, x: 0.0, y: 2)
                .shadow(color: Color(#colorLiteral(red: 0.4352941176, green: 0.5607843137, blue: 0.9176470588, alpha: 1)).opacity(0.16), radius: 12, x: 0.0, y: 4)
        case 2:
            content
                .shadow(color: Color(#colorLiteral(red: 0.4352941176, green: 0.5607843137, blue: 0.9176470588, alpha: 1)).opacity(0.06), radius: 6, x: 0.0, y: 2)
                .shadow(color: Color(#colorLiteral(red: 0.4352941176, green: 0.5607843137, blue: 0.9176470588, alpha: 1)).opacity(0.14), radius: 22, x: 0.0, y: 5)
            
            //for some reason there isn't a case 3
        
//        case 3:
//            content
//                .shadow(color: Color(#colorLiteral(red: 0.4352941176, green: 0.5607843137, blue: 0.9176470588, alpha: 1)).opacity(0.06), radius: 6, x: 0.0, y: 2)
//                .shadow(color: Color(#colorLiteral(red: 0.4352941176, green: 0.5607843137, blue: 0.9176470588, alpha: 1)).opacity(0.14), radius: 22, x: 0.0, y: 5)
            
        case 3:
            content
                .shadow(color: Color("B10").opacity(0.10), radius: 16, x: 2, y: 6)
                .shadow(color: Color("B10").opacity(0.16), radius: 48, x: 4, y: 16)
        case 4:
            content
                .shadow(color: Color(#colorLiteral(red: 0.4352941176, green: 0.5607843137, blue: 0.9176470588, alpha: 1)).opacity(0.08), radius: 10, x: 1, y: 4)
                .shadow(color: Color(#colorLiteral(red: 0.4352941176, green: 0.5607843137, blue: 0.9176470588, alpha: 1)).opacity(0.12), radius: 32, x: 2, y: 10)
        case 5:
            content
                .shadow(color: Color(#colorLiteral(red: 0.4352941176, green: 0.5607843137, blue: 0.9176470588, alpha: 1)).opacity(0.08), radius: 20, x: 2, y: 6)
                .shadow(color: Color(#colorLiteral(red: 0.4352941176, green: 0.5607843137, blue: 0.9176470588, alpha: 1)).opacity(0.16), radius: 52, x: 4, y: 16)
        default:
            content
        }
    }
}
