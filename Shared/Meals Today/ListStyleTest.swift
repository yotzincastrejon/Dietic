//
//  ListStyleTest.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 3/24/22.
//

import SwiftUI

struct ListStyleTest: View {

    private struct NamedFont: Identifiable {
        let name: String
        let font: Font
        var id: String { name }
    }
    
    private let namedFonts: [NamedFont] = [
        NamedFont(name: "Large Title", font: .largeTitle),
        NamedFont(name: "Title", font: .title),
        NamedFont(name: "Headline", font: .headline),
        NamedFont(name: "Body", font: .body),
        NamedFont(name: "Caption", font: .caption)
    ]
    
    @State var isTapped = false
    var body: some View {
        VStack {
            List {
                Section("History") {
                    ForEach(namedFonts) { namedFont in
                        ZStack {
                            Button(action: {
                                //Add Action
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("No Name")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            
                                        Text("No brand")
                                            .font(.caption2)
                                            .foregroundColor(Color(uiColor: .secondaryLabel))
                                    }
                                    Spacer()
                                    Text("20 kcal")
                                        .font(.subheadline)
                                        .foregroundColor(Color("B10"))
                                }
                                .padding(.leading)
                                .padding(.trailing, 60)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(Color.white)
                            }
                            
//                            PlusToCheckMark()
                        }
                        
                    }
                    .onDelete(perform: delete)
                    .cornerRadius(10)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.blue)
                    .buttonStyle(BorderlessButtonStyle())
                    
                }
                
            }
            .listStyle(.plain)
            
            
            
            
        }
    }
    func delete(offsets: IndexSet) {
        
    }
}

struct ListStyleTest_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ListStyleTest()
        ListStyleTest()
            .preferredColorScheme(.dark)
        }
    }
}


