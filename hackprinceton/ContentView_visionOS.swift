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
    @State var githubAPI = GitHubAPI(repositoryURL: "https://github.com/pennlabs/penn-mobile-ios")!
    @StateObject var arViewModel = ARViewModel()
    
    var tapGesture: some Gesture {
        TapGesture()
            .targetedToEntity(where: .has(CommitComponent.self))
            .onEnded { result in
                let commit = result.entity.components[CommitComponent.self]?.commit
                if arViewModel.selectedCommit == commit {
                    arViewModel.selectedCommit = nil
                } else {
                    arViewModel.selectedCommit = commit
                }
            }
    }
    
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
        RealityView { content, attachments in
            arViewModel.attachment = attachments.entity(for: "selectedCommit")
            arViewModel.setup(repository: githubAPI.repository)
            // arViewModel.rootEntity.position = SIMD3(x: 0, y: -0.3, z: 0.75)
            arViewModel.rootEntity.position = SIMD3(x: 0, y: 1.5, z: -0.2)
            content.add(arViewModel.rootEntity)
        } update: { _, attachments in
            arViewModel.attachment = attachments.entity(for: "selectedCommit")
            arViewModel.update(repository: githubAPI.repository)
        } attachments: {
            Attachment(id: "selectedCommit") {
                if let commit = arViewModel.selectedCommit {
                    CommitAttachmentView(commit: commit)
                } else {
                    Rectangle().fill(.clear).frame(width: 1, height: 1)
                        .allowsHitTesting(false)
                }
            }
        }
        .environmentObject(arViewModel)
        .gesture(tapGesture)
        .gesture(pinchGesture)
        .task(id: githubAPI.repositoryURL) {
            do {
                logger.warning("Fetching repo!")
                try await githubAPI.populate()
            } catch {
                logger.error("Failed to populate repo! \(error)")
            }
        }
    }
}

struct CommitAttachmentView: View {
    var commit: Commit
    @State var appeared = false
    @EnvironmentObject var arViewModel: ARViewModel
    
    var body: some View {
        Group {
            if appeared {
                VStack {
                    HStack {
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                appeared = false
                            } completion: {
                                if arViewModel.selectedCommit == commit {
                                    arViewModel.selectedCommit = nil
                                }
                            }
                        } label: {
                            Label("Close", systemImage: "xmark")
                                .labelStyle(.iconOnly)
                        }
                        
                        Text("\(CommitDetailView.dateFormatter.string(from: commit.date))")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.tertiary)
                        
                        Button {
                            
                        } label: {
                            Label("Expand", systemImage: "rectangle.expand.vertical")
                                .labelStyle(.titleAndIcon)
                        }
                    }
                    
                    CommitMetadataView(commit: commit)
                        .navigationTitle("Commit")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .frame(width: 480)
                .padding(.top, 16)
                .padding([.horizontal, .bottom])
                .glassBackgroundEffect(in: .rect(cornerRadius: 32))
                .frame(height: 240, alignment: .bottom)
                .transition(.asymmetric(insertion: .push(from: .bottom), removal: .push(from: .top)))
            } else {
                Rectangle().fill(.clear).frame(width: 1, height: 1)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.15)) {
                appeared = true
            }
        }
        .onChange(of: arViewModel.selectedCommit) {
            appeared = false
            withAnimation(.spring(duration: 0.15)) {
                appeared = true
            }
        }
    }
}
#endif
