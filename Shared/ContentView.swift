//
//  ContentView.swift
//  Shared
//
//  Created by Yotzin Castrejon on 10/18/21.
//

import SwiftUI


struct ContentView: View {
    @StateObject var fastingManager = FastingManager()
    var body: some View {
        Home(fastingManager: fastingManager)
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
