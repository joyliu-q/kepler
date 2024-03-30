//
//  Request.swift
//  hackprinceton
//
//  Created by Joy Liu on 3/29/24.
//

import Foundation


struct GitHubAPI {
    let baseURL = "https://api.github.com/repos/"
    let repository: String

    init(repository: String) {
        self.repository = repository
    }

    // Function to fetch all commits
    func fetchAllCommits(completion: @escaping (Result<[CommitResponse], Error>) -> Void) {
        let urlString = "\(baseURL)\(repository)/commits"
        performRequest(urlString: urlString, completion: completion)
    }

    // Function to fetch all branches
    func fetchAllBranches(completion: @escaping (Result<[BranchResponse], Error>) -> Void) {
        let urlString = "\(baseURL)\(repository)/branches"
        performRequest(urlString: urlString, completion: completion)
    }

    // Function to fetch a commit for a particular SHA
    func fetchCommit(for sha: String, completion: @escaping (Result<CommitResponse, Error>) -> Void) {
        let urlString = "\(baseURL)\(repository)/commits/\(sha)"
        performRequest(urlString: urlString, completion: completion)
    }

    // General purpose request function
    private func performRequest<T: Decodable>(urlString: String, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
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

