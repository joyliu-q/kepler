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
        WindowGroup {
            ContentView()
        }
    }
}

let logger = Logger(subsystem: "dev.joyliu.hackprinceton", category: "HackPrinceton")
