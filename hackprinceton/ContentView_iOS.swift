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
    @State var githubAPI: GitHubAPI = GitHubAPI(repository: Repository.dummy)
    
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
            
            if (githubAPI.repository == Repository.dummy) {
                OnboardView(githubAPI: $githubAPI)
                    .background(.regularMaterial)
                    .clipShape(.rect(cornerRadius: 16))
                    .shadow(radius: 10)
                    .frame(width: 400)
            }
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
        .task(id: githubAPI.repositoryURL) {
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
        
        let textAnchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
        
        textAnchor.addChild(textGen(textString: Project.title))
        arView.scene.addAnchor(textAnchor)

        return arView
    }
    
    
    func textGen(textString: String) -> ModelEntity {
        let materialVar = SimpleMaterial(color: .white, roughness: 0, isMetallic: true)
        
        let depthVar: Float = 0.001
        let fontVar = UIFont.systemFont(ofSize: 0.01)
        let containerFrameVar = CGRect(x: -0.05, y: -0.1, width: 0.1, height: 0.1)
        let alignmentVar: CTTextAlignment = .center
        let lineBreakModeVar : CTLineBreakMode = .byWordWrapping
        
        let textMeshResource : MeshResource = .generateText(
            textString,
           extrusionDepth: depthVar,
           font: fontVar,
           containerFrame: containerFrameVar,
           alignment: alignmentVar,
           lineBreakMode: lineBreakModeVar
        )
        
        let textEntity = ModelEntity(mesh: textMeshResource, materials: [materialVar])
        
        return textEntity
    }

    
    
    func updateUIView(_ uiView: ARView, context: Context) {
        arViewModel.update(repository: repository)
    }
}

#Preview {
    ContentView_iOS()
}
#endif
