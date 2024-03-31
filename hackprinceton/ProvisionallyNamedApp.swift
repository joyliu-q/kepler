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
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    #endif
    
    
    init() {
        CommitComponent.registerComponent()
    }
    
    var body: some Scene {
        #if os(iOS)
        WindowGroup {
            ContentView_iOS()
        }
        #else
        WindowGroup {
            OnboardView(githubAPI: $githubAPI) {
                Task {
                    await openImmersiveSpace(id: "Graph")
                }
            }
            .frame(width: 400)
            .onChange(of: githubAPI.repositoryURL) {
                Task {
                    await openImmersiveSpace(id: "Graph")
                }
            }
        }
        .windowResizability(.contentSize)
        
        ImmersiveSpace(id: "Graph") {
            ContentView_visionOS(githubAPI: githubAPI)
        }
        #endif
    }
}

let logger = Logger(subsystem: "dev.joyliu.hackprinceton", category: "HackPrinceton")
