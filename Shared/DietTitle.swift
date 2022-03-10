//
//  DietTitle.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/20/21.
//

import SwiftUI

/// Diet Title for the Diet Card View
struct DietTitle: View {
    let title: String
    let view: AnyView
    let imageStringText: String
    let imageSystemName: String
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            NavigationLink(destination: view) {
                Text(imageStringText)
                Image(systemName: imageSystemName)
            }
            .font(.subheadline)
        }
    }
}

//struct DietTitle_Previews: PreviewProvider {
//    static var previews: some View {
//        DietTitle()
//    }
//}
