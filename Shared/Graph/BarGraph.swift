//
//  BarGraph.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/22/21.
//

import SwiftUI

struct BarGraph: View {
    @State var position: Int = 7
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    HStack(spacing: 24) {
                        
                        VStack {
                            Spacer()
                            Bar(height: 127)
                        }
                        .padding(.bottom, 53)
                        .padding(.leading, 30)
                        .onTapGesture {
                            position = 0
                        }
                        
                        VStack {
                            Spacer()
                            Bar(height: 115)
                        }
                        .padding(.bottom, 53)
                        .onTapGesture {
                            position = 1
                        }
                        
                        
                        VStack {
                            Spacer()
                            Bar(height: 102)
                        }
                        .padding(.bottom, 53)
                        .onTapGesture {
                            position = 2
                        }
                        
                        VStack {
                            Spacer()
                            Bar(height: 120)
                        }
                        .padding(.bottom, 53)
                        .onTapGesture {
                            position = 3
                        }
                        
                        VStack {
                            Spacer()
                            Bar(height: 115)
                        }
                        .padding(.bottom, 53)
                        .onTapGesture {
                            position = 4
                        }
                        
                        VStack {
                            Spacer()
                            Bar(height: 153)
                        }
                        .padding(.bottom, 53)
                        .onTapGesture {
                            position = 5
                        }
                        
                        VStack {
                            Spacer()
                            Bar(height: 141)
                        }
                        .padding(.bottom, 53)
                        .onTapGesture {
                            position = 6
                        }
                        
                        VStack {
                            Spacer()
                            Bar(height: 77)
                        }
                        .padding(.bottom, 53)
                        .onTapGesture {
                            position = 7
                        }
                        
                        Spacer()
                    }.frame(width: 345, height: 237)
                    Spacer()
                }
                Spacer()
            }
            
            ArrowViewGraph(position: $position)
        }
    }
}

struct BarGraph_Previews: PreviewProvider {
    static var previews: some View {
        BarGraph()
    }
}
