//
//  Model.swift
//  hackprinceton
//
//  Created by Joy Liu on 3/29/24.
//

import Foundation

typealias Sha = String

struct Commit: Equatable, Hashable {
    var sha: Sha
    
    // TODO: do not support co-authors right now
    var author: String // Have an Author struct
    var title: String // If null its just "", we assume always has title
    var description: String?
    
    // Displays
    //    var diff: String? // For now, potentially not possible
    
    // Optional metadata fields
    //    var verified: Bool
    
}

struct Branch: Hashable {
    var head: Sha
    var name: String
}

struct Repository {
    var url: String
    var branches: [Branch]
    var commits: Dictionary<Sha, Commit>
    
    var main: String = "main"
    
    /// Get HEAD commit from the main branch
    func getHeadCommit() -> Commit? {
        for branch in self.branches {
            if branch.name == self.main {
                return self.commits[branch.head]
            }
        }
        return nil
    }
}


