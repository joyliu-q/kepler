//
//  AppDelegate.swift
//  hackprinceton
//
//  Created by Joy Liu on 3/29/24.
//

import UIKit
import SwiftUI
import OSLog

@main
@MainActor struct ProvisionallyNamedApp: App {
    #if os(visionOS)
    @State var githubAPI = GitHubAPI(repositoryURL: "https://github.com/pennlabs/penn-mobile-ios")!
    @StateObject var arViewModel = ARViewModel()
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissWindow) var dismissWindow
    #endif

    
    init() {
        CommitComponent.registerComponent()
        ExpansionComponent.registerComponent()
        ExpansionSystem.registerSystem()
    }
    
    var body: some Scene {
        #if os(iOS)
        WindowGroup {
            ContentView_iOS()
        }
        #else
        WindowGroup {
            VStack(spacing: 0) {
                OnboardView(githubAPI: $githubAPI) {
                    Task {
                        await openImmersiveSpace(id: "Graph")
                        dismissWindow(id: "Commit")
                        arViewModel.shrink()
                    }
                }
                
                if githubAPI.repository != .dummy {
                    VisionOSAIView(githubAPI: githubAPI)
                }
            }
            .frame(width: 400)
        }
        .windowResizability(.contentSize)
        
        ImmersiveSpace(id: "Graph") {
            ContentView_visionOS(githubAPI: githubAPI)
                .environmentObject(arViewModel)
        }
        
        WindowGroup(id: "Commit") {
            if let commit = arViewModel.selectedCommit {
                CommitDetailView(commit: commit, githubAPI: githubAPI, currentPresentationDetent: .large)
                    .environmentObject(arViewModel)
                    .onAppear {
                        arViewModel.expand()
                    }
                    .onDisappear {
                        arViewModel.shrink()
                    }
            } else {
                Text("No commit")
                    .padding()
            }
        }
        .defaultSize(width: 400, height: 600)
        #endif
    }
}

let logger = Logger(subsystem: "dev.joyliu.hackprinceton", category: "HackPrinceton")
