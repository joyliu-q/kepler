//
//  CoachingView.swift
//  hackprinceton
//
//  Created by Anthony Li on 3/30/24.
//

import SwiftUI
import ARKit

#if os(iOS)
struct CoachingView: UIViewRepresentable {
    @Environment(ARViewModel.self) var arViewModel
    
    func makeUIView(context: Context) -> ARCoachingOverlayView {
        let view = ARCoachingOverlayView()
        view.goal = .horizontalPlane
        view.session = arViewModel.session
        return view
    }
    
    func updateUIView(_ uiView: ARCoachingOverlayView, context: Context) {
        uiView.session = arViewModel.session
    }
}
#endif
