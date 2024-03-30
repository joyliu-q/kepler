//
//  ContentView_visionOS.swift
//  hackprinceton
//
//  Created by Anthony Li on 3/30/24.
//

import SwiftUI
import RealityKit

#if os(visionOS)
struct ContentView_visionOS: View {
    @State var githubAPI = GitHubAPI(repositoryURL: "https://github.com/joyliu-q/hackprinceton")!
    @State var arViewModel = ARViewModel()
    
    var body: some View {
        RealityView { content in
            arViewModel.setup(repository: githubAPI.repository)
            arViewModel.rootEntity.position = SIMD3(x: 0, y: 0, z: 0.45)
            content.add(arViewModel.rootEntity)
        } update: { _ in
            arViewModel.update(repository: githubAPI.repository)
        }
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
