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
    @State var graphNodes = [CommitGraphNode]()
    @State var commit: Commit? = nil
    
    var body: some View {
        ZStack {
            /* ARViewContainer()
                .edgesIgnoringSafeArea(.all) */
            
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(graphNodes) { node in
                        let commit = githubAPI.repository.commits[node.sha]!
                        
                        Button {
                            self.commit = commit
                        } label: {
                            HStack {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 10, height: 10)
                                Text(commit.title)
                            }
                            .padding(.leading, CGFloat(20 * node.x))
                            .multilineTextAlignment(.leading)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(item: $commit) { commit in
            CommitDetailView(commit: commit)
            .presentationDetents([.fraction(0.4), .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
                .presentationBackground(.regularMaterial)
        }
        .task {
            try? await githubAPI.populate()
        }
        .onChange(of: githubAPI.repository) { repo in
            graphNodes = computeGraph(from: repo)
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)

        // Create a cube model
        let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
        let material = SimpleMaterial(color: .gray, roughness: 0.15, isMetallic: true)
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.transform.translation.y = 0.05

        // Create horizontal plane anchor for the content
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
        anchor.children.append(model)

        // Add the horizontal plane anchor to the scene
        arView.scene.anchors.append(anchor)

        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}

#Preview {
    ContentView()
}
