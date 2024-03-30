//
//  Request.swift
//  hackprinceton
//
//  Created by Joy Liu on 3/29/24.
//

import Foundation

// Using class here because when one GitHub repo changes, all changes
@Observable class GitHubAPI {
    let baseURL = "https://api.github.com/repos/"
    let repositoryURL: String
    var repository: Repository

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
        self.repository.commits = commits.reduce(into: [:]) { (result, commitResponse) in
            let sha = commitResponse.sha
            let parents = commitResponse.parents.map { $0.sha }
            let author = commitResponse.commit.author.name
            let title = commitResponse.commit.title
            let description = commitResponse.commit.description
            let date = commitResponse.commit.author.date
            let avatar_url = commitResponse.author?.avatar_url
            result[sha] = Commit(sha: sha, parent: parents, author: author, avatar_url: avatar_url, title: title, description: description, date: date)
        }
        
        self.repository.branches = branches.map { branchResponse in
            Branch(name: branchResponse.name, head: branchResponse.commit.sha)
        }
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
        let urlString = "\(repository.url)/commits"
        return try await performRequest(urlString: urlString)
    }

    // Function to fetch all branches
    func fetchAllBranches() async throws -> [BranchResponse] {
        let urlString = "\(repository.url)/branches"
        return try await  performRequest(urlString: urlString)
    }

    // Function to fetch a commit for a particular SHA
    func fetchCommit(for sha: String) async throws -> CommitResponse? {
        let urlString = "\(repository.url)/commits/\(sha)"
        return try await performRequest(urlString: urlString)
    }

    // General purpose request function
    private func performRequest<T: Decodable>(urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601  // Handling ISO 8601 formatted dates
            
        return try decoder.decode(T.self, from: data)
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
    let sha: String
    let commit: CommitDetail
    let parents: [Parent]
    let author: AuthorDeets?
}

struct CommitDetail: Decodable {
    let author: Author
    let message: String
    
    var title: String {
        message.components(separatedBy: "\n").first ?? ""
    }
    
    var description: String {
        let components = message.components(separatedBy: "\n")
        guard components.count > 1 else { return "" }
        return components.dropFirst().joined(separator: "\n")
    }
}

struct AuthorDeets: Decodable {
    let avatar_url: String
}

struct Author: Decodable {
    let name: String
    let date: Date
}

struct Parent: Decodable {
    let sha: String
}


struct BranchResponse: Decodable {
    // Define properties based on GitHub API JSON structure for branches
    let name: String
    let commit: BranchCommit
}

struct BranchCommit: Decodable {
    let sha: String
}

