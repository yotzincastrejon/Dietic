//
//  MatchedView.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 2/17/22.
//

import SwiftUI

struct MatchedView: View {
    @ObservedObject var fastingManager: FastingManager
    var namespace: Namespace.ID
    @Binding var show: Bool
    @Binding var showStatusBar: Bool
    @State var appear = [false, false, false]
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color("OGT"), Color("OGB")], startPoint: .topLeading, endPoint: .bottomTrailing)
                .mask(RoundedCorners(color: [.blue], tl: 8, tr: 100, bl: 8, br: 8))
                .ignoresSafeArea()
                .matchedGeometryEffect(id: "background", in: namespace)
                button
                            VStack {
                HStack {
                    
                    ZStack {
                        Circle()
                            .fill(.white).opacity(0.2)
                            .matchedGeometryEffect(id: "circle", in: namespace)
                            .frame(width: 88,height: 88)
                        Image("bread")
                            .matchedGeometryEffect(id: "image", in: namespace)
                            .frame(width: 64, height: 64)
                            .shadow(color: Color("EggSandwichShadow").opacity(0.3), radius: 16, x: 6, y: 10)
                    }
                    Spacer()
                }
                Spacer()
                
            }
            .padding()
            
            VStack {
                    Text("Breakfast")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 47)
                    .matchedGeometryEffect(id: "title", in: namespace)
                Spacer()
                Text(fastingManager.theSamples.filter { $0.mealPeriod == "Breakfast" }.map { $0.foodName }.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundColor(.white)
//                        .padding(.bottom, 15)
//                        .fixedSize(horizontal: false, vertical: true)
                    .matchedGeometryEffect(id: "text", in: namespace)
            }
            
        }
        .frame(height: 300)
        .cornerRadius(20)
        .padding(.horizontal)
        .onAppear {
            fadeIn()
        }
        .onChange(of: show) { newValue in
            fadeOut()
        }
        
    }
    
    var button: some View {
        Button {
            withAnimation(.closeCard) {
                show.toggle()
            }
        } label: {
            Image(systemName: "xmark")
                .font(.body.weight(.bold))
                .foregroundColor(.secondary)
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(20)
        .ignoresSafeArea()
    }
    
    func fadeIn() {
        withAnimation(.easeOut.delay(0.3)) {
            appear[0] = true
        }
        withAnimation(.easeOut.delay(0.4)) {
            appear[1] = true
        }
        withAnimation(.easeOut.delay(0.5)) {
            appear[2] = true
        }
    }
    
    func fadeOut() {
        appear[0] = false
        appear[1] = false
        appear[2] = false
    }
}

struct MatchedView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        MatchedView(fastingManager: FastingManager(), namespace: namespace, show: .constant(true), showStatusBar: .constant(true))
    }
}
