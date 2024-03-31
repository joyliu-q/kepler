//
//  ContentView.swift
//  hackprinceton
//
//  Created by Joy Liu on 3/29/24.
//

import SwiftUI
import RealityKit

#if os(iOS)
@MainActor struct ContentView_iOS : View {
    @State var githubAPI = GitHubAPI(repositoryURL: "https://github.com/joyliu-q/hackprinceton")!
    @State var arViewModel = ARViewModel()
    @State var feedbackGenerator = UISelectionFeedbackGenerator()
    
    var pinchGesture: some Gesture {
        MagnifyGesture()
            .onChanged { gesture in
                arViewModel.handleScaleGestureChange(magnification: gesture.magnification)
            }
            .onEnded { gesture in
                arViewModel.handleScaleGestureChange(magnification: gesture.magnification)
                arViewModel.handleScaleGestureEnd()
            }
    }
    
    var body: some View {
        ZStack {
            ARViewContainer(repository: githubAPI.repository)
            CoachingView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .environmentObject(arViewModel)
        .onTapGesture { event in
            if let selectedCommit = arViewModel.lookupCommit(at: event) {
                arViewModel.selectedCommit = selectedCommit
            } else {
                arViewModel.selectedCommit = nil
            }
        }
        .gesture(pinchGesture)
        .ignoresSafeArea()
        .sheet(item: $arViewModel.selectedCommit) { commit in
            CommitDetailView(commit: commit, githubAPI: githubAPI)
            .presentationDetents([.fraction(0.3), .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
                .presentationBackground(.regularMaterial)
        }
        .task {
            do {
                try await githubAPI.populate()
                let openAI = OpenAIAPI()
                let story = try await openAI.generateStory(repository: githubAPI.repository)
            } catch {
                logger.error("Failed to populate repo! \(error)")
            }
        }
        .onChange(of: arViewModel.selectedCommit) {
            if arViewModel.selectedCommit != nil {
                feedbackGenerator.selectionChanged()
                playSound(sound: "whoosh",
                          type: "mp3", numLoops: 1)
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    var repository: Repository
    @EnvironmentObject var arViewModel: ARViewModel
    
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
