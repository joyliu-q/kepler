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
struct ProvisionallyNamedApp: App {
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
            ContentView_visionOS()
        }
        .windowStyle(.volumetric)
        .defaultSize(Size3D(width: 1, height: 1, depth: 2), in: .meters)
        #endif
    }
}

let logger = Logger(subsystem: "dev.joyliu.hackprinceton", category: "HackPrinceton")
