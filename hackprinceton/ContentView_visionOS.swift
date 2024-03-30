//
//  ContentView_visionOS.swift
//  hackprinceton
//
//  Created by Anthony Li on 3/30/24.
//

import SwiftUI
import RealityKit

#if os(visionOS)
@MainActor struct ContentView_visionOS: View {
    @State var githubAPI = GitHubAPI(repositoryURL: "https://github.com/joyliu-q/hackprinceton")!
    @State var arViewModel = ARViewModel()
    
    var tapGesture: some Gesture {
        TapGesture()
            .targetedToAnyEntity()
            .onEnded { entity in
                print(entity)
            }
    }
    
    var pinchGesture: some Gesture {
        MagnifyGesture()
            .targetedToAnyEntity()
            .onChanged { gesture in
                arViewModel.handleScaleGestureChange(magnification: gesture.magnification)
            }
            .onEnded { gesture in
                arViewModel.handleScaleGestureChange(magnification: gesture.magnification)
                arViewModel.handleScaleGestureEnd()
            }
    }
    
    var body: some View {
        RealityView { content in
            arViewModel.setup(repository: githubAPI.repository)
            arViewModel.rootEntity.position = SIMD3(x: 0, y: -0.3, z: 0.45)
            content.add(arViewModel.rootEntity)
        } update: { _ in
            arViewModel.update(repository: githubAPI.repository)
        }
        .gesture(tapGesture)
        .gesture(pinchGesture)
        .task {
            do {
                try await githubAPI.populate()
            } catch {
                logger.error("Failed to populate repo! \(error)")
            }
        }
    }
}
#endif
