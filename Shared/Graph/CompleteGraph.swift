//
//  CompleteGraph.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/22/21.
//

import SwiftUI

struct CompleteGraph: View {
    
    var body: some View {
        ZStack {
            BarGraphBackground()
            BarGraph()
            TextGraph()
        }
    }
}

struct CompleteGraph_Previews: PreviewProvider {
    static var previews: some View {
        CompleteGraph()
    }
}
