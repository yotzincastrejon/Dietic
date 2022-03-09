//
//  BarcodeButton.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 3/9/22.
//

import SwiftUI

struct BarcodeButton: View {
    @State var themeColor: [Color]
    @Binding var isActive: Bool
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    // Do action
                    isActive = true
                }) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: themeColor, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 56, height: 56)
                        Image(systemName: "barcode.viewfinder")
                        .resizable()
                        .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    }
                }
                .padding(30)
                
            }
        }
    }
}

struct BarcodeButton_Previews: PreviewProvider {
    static var previews: some View {
        BarcodeButton(themeColor: [Color("B10"), Color("B00")], isActive: Binding.constant(true))
    }
}
