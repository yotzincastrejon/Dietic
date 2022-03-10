//
//  BlurView.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 3/10/22.
//

import SwiftUI

struct BlurView: UIViewRepresentable {

    var effect: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        
        let view = UIVisualEffectView(effect: UIBlurEffect(style: effect))
        
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        
    }
}
