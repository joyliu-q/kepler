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
    @StateObject var arViewModel = ARViewModel()
    @State var feedbackGenerator = UISelectionFeedbackGenerator()
    @State private var showAnalysis: Bool = false
    @State private var analysisResult: OpenAIAPI.AnalysisResult?
    
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
    
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { gesture in
                arViewModel.handlePhoneDragGestureChange(location: gesture.location)
            }
            .onEnded { gesture in
                arViewModel.handlePhoneDragGestureChange(location: gesture.location)
                arViewModel.handlePhoneDragGestureEnd()
            }
    }
    
    var body: some View {
        ZStack {
            
            ARViewContainer(repository: githubAPI.repository)
                .gesture(dragGesture)

            CoachingView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
            
            if (githubAPI.repository == Repository.dummy) {
                OnboardView(githubAPI: $githubAPI)
                    .background(.regularMaterial)
                    .clipShape(.rect(cornerRadius: 16))
                    .shadow(radius: 10)
                    .frame(width: 360)
            }
            VStack {
                HStack {
                    Button("Generate Analysis") {
                        Task {
                            let openAI = OpenAIAPI()
                            showAnalysis = true
                            do {
                                analysisResult = try await openAI.generateStory(repository: githubAPI.repository)
                            } catch {
                                print(error)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                .padding(.top, 40)
                Spacer() // Pushes the HStack to the top
            }
            if showAnalysis {
                VStack(spacing: 20) {
                    if let analysisResult = analysisResult {
                        ScrollView {
                            // VStack to display AnalysisResult
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Arcs:")
                                    .fontWeight(.bold)
                                ForEach(analysisResult.arcs, id: \.self) { arc in
                                    Text(arc)
                                }

                                Text("\nKey Contributors:")
                                    .fontWeight(.bold)
                                ForEach(analysisResult.keyContributors.keys.sorted(), id: \.self) { key in
                                    Text("\(key): \(analysisResult.keyContributors[key]?.joined(separator: ", ") ?? "")")
                                }

                                Text("\nOverall Patterns:")
                                    .fontWeight(.bold)
                                ForEach(analysisResult.overallPatterns, id: \.self) { pattern in
                                    Text(pattern)
                                }
                            }
                            .padding()
                        }
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: 300, height: 400) // Adjust the panel size as needed
                .background(Color.black.opacity(0.75)) // A darker background for better contrast
                .foregroundColor(.white) // Text color for better readability
                .cornerRadius(20)
                .shadow(radius: 10)
                .overlay(
                    Button(action: {
                        showAnalysis = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.75))
                            .clipShape(Circle())
                    }
                    .padding(5), // Adds padding around the button itself for a slightly larger tap target
                    alignment: .topTrailing // Places the button in the top-right corner of the overlay
                )
            }
        }
        .ignoresSafeArea()
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
        .sheet(isPresented: Binding {
            arViewModel.selectedCommit != nil
        } set: { value in
            if !value {
                arViewModel.selectedCommit = nil
            }
        }) {
            if let commit = arViewModel.selectedCommit {
                CommitDetailView(commit: commit, githubAPI: githubAPI)
            } else {
                EmptyView()
            }
        }
        .task(id: githubAPI.repositoryURL) {
            do {
                try await githubAPI.populate()
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
