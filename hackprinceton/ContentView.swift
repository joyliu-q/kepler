//
//  ContentView.swift
//  hackprinceton
//
//  Created by Joy Liu on 3/29/24.
//

import SwiftUI
import RealityKit


struct ContentView : View {
    @State var githubAPI = GitHubAPI(repositoryURL: "https://github.com/torvalds/linux")!
    @State var commit: Commit? = nil
    
    var body: some View {
        ARViewContainer(repository: githubAPI.repository)
            .edgesIgnoringSafeArea(.all)
        .sheet(item: $commit) { commit in
            CommitDetailView(commit: commit)
            .presentationDetents([.fraction(0.4), .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
                .presentationBackground(.regularMaterial)
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

struct ARViewContainer: UIViewRepresentable {
    var repository: Repository
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)

        // Create horizontal plane anchor for the content
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))

        // Set up the scene
        setupScene(repository: repository, rootEntity: context.coordinator)
        anchor.children.append(context.coordinator)
        
        // Add the horizontal plane anchor to the scene
        arView.scene.anchors.append(anchor)

        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        updateScene(repository: repository, rootEntity: context.coordinator)
    }
    
    // returns our root entity lmao
    func makeCoordinator() -> Entity {
        return Entity()
    }
}

#Preview {
    ContentView()
}
