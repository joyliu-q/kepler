//
//  ContentView.swift
//  hackprinceton
//
//  Created by Joy Liu on 3/29/24.
//

import SwiftUI
import RealityKit


struct ContentView : View {
    @State var githubAPI = GitHubAPI(repositoryURL: "https://github.com/joyliu-q/hackprinceton")!
    @State var commit: Commit? = nil
    @State var arViewModel = ARViewModel()
    @State var feedbackGenerator = UISelectionFeedbackGenerator()
    
    var body: some View {
        ARViewContainer(repository: githubAPI.repository)
            .environment(arViewModel)
            .onTapGesture { event in
                if let selectedCommit = arViewModel.lookupCommit(at: event) {
                    commit = selectedCommit
                }
            }
            .ignoresSafeArea()
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
            .onChange(of: commit) {
                if let commit {
                    feedbackGenerator.selectionChanged()
                }
            }
    }
}

struct ARViewContainer: UIViewRepresentable {
    var repository: Repository
    @Environment(ARViewModel.self) var arViewModel
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)

        // Create horizontal plane anchor for the content
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))

        // Set up the scene
        arViewModel.setup(repository: repository, arView: arView)
        anchor.children.append(arViewModel.rootEntity)
        
        // Add the horizontal plane anchor to the scene
        arView.scene.anchors.append(anchor)

        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        arViewModel.update(repository: repository)
    }
}

#Preview {
    ContentView()
}
