//
//  Request.swift
//  hackprinceton
//
//  Created by Joy Liu on 3/29/24.
//

import Foundation

// Using class here because when one GitHub repo changes, all changes
class GitHubAPI {
    let baseURL = "https://api.github.com/repos/"
    let repositoryURL: String
    let repository: Repository

    init?(repositoryURL: String) {
        self.repositoryURL = repositoryURL
        
        // TODO: auth

        // Extract the repository path from the URL
        if let repoPath = GitHubAPI.extractRepoPath(from: repositoryURL) {
            self.repository = Repository(url: "\(baseURL)\(repoPath)", branches: [], commits: [:])
        } else {
            // Handle the error case where the URL is not valid
            print("Invalid repository URL")
            return nil  // Initialize as nil to indicate failure
        }
    }
    
    func populate() async throws {
        let commits = try await fetchAllCommits()
        let branches = try await fetchAllBranches()
//        self.repository.commits = commits.map({commit in
//            // TODO:
//        })
//        self.repository.branches = branches.map({branchResponse in
//            // TODO
//        })
    }
        
    private static func extractRepoPath(from url: String) -> String? {
        // Assuming URL format is 'https://github.com/[username]/[repository]'
        let components = url.split(separator: "/")
        guard components.count >= 4 else { return nil }

        let username = components[components.count - 2]
        let repositoryName = components[components.count - 1]
        return "\(username)/\(repositoryName)"
    }

    // Function to fetch all commits
    func fetchAllCommits() async throws -> [CommitResponse] {
        let urlString = "\(baseURL)\(repository)/commits"
        return try await performRequest(urlString: urlString)
    }

    // Function to fetch all branches
    func fetchAllBranches() async throws -> [BranchResponse] {
        let urlString = "\(baseURL)\(repository)/branches"
        return try await  performRequest(urlString: urlString)
    }

    // Function to fetch a commit for a particular SHA
    func fetchCommit(for sha: String) async throws -> CommitResponse? {
        let urlString = "\(baseURL)\(repository)/commits/\(sha)"
        return try await performRequest(urlString: urlString)
    }

    // General purpose request function
    private func performRequest<T: Decodable>(urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// Custom Errors
enum NetworkError: Error {
    case invalidURL
    case noData
}

// Decodable structs for parsing JSON
struct CommitResponse: Decodable {
    // Define properties based on GitHub API JSON structure for commits
}

struct BranchResponse: Decodable {
    // Define properties based on GitHub API JSON structure for branches
}

