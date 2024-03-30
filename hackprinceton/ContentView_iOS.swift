//
//  ContentView.swift
//  hackprinceton
//
//  Created by Joy Liu on 3/29/24.
//

import SwiftUI
import RealityKit

#if os(iOS)
struct ContentView_iOS : View {
    @State var githubAPI = GitHubAPI(repositoryURL: "https://github.com/joyliu-q/hackprinceton")!
    @State var commit: Commit? = nil
    @State var arViewModel = ARViewModel()
    @State var feedbackGenerator = UISelectionFeedbackGenerator()
    
    var body: some View {
        ZStack {
            ARViewContainer(repository: githubAPI.repository)
            CoachingView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .environment(arViewModel)
        .onTapGesture { event in
            if let selectedCommit = arViewModel.lookupCommit(at: event) {
                if selectedCommit == commit {
                    playSound(sound: "whoosh",
                              type: "mp3", numLoops: 1)
                }
                commit = selectedCommit
            }
        }
        .ignoresSafeArea()
        .sheet(item: $commit) { commit in
            CommitDetailView(commit: commit, githubAPI: githubAPI)
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
            if commit != nil {
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
        arViewModel.setup(repository: repository)
        arViewModel.attach(to: arView)
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
    ContentView_iOS()
}
#endif
