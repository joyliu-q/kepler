//
//  OpenAIAPI.swift
//  hackprinceton
//
//  Created by Joy Liu on 3/30/24.
//

import Foundation

struct OpenAIRequest: Codable {
    let prompt: String
    let maxTokens: Int
    let temperature: Double
}

struct OpenAIResponse: Codable {
    let id: String
    let choices: [Choice]
}

struct Choice: Codable {
    let text: String
}

class OpenAIAPI {
    let encoder = JSONEncoder()
    
    func generateStory(repository: Repository,  completion: @escaping (Result<String, Error>) -> Void) {
        let requestBody = OpenAIRequest(
            prompt: createPrompt(from: repository),
            maxTokens: 1000,
            temperature: 0.5
        )

        guard let url = URL(string: "https://api.openai.com/v1/engines/davinci-codex/completions") else {
            completion(.failure(URLRequestError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(requestBody)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(URLRequestError.noData))
                return
            }
            do {
                let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                if let story = response.choices.first?.text {
                    completion(.success(story))
                } else {
                    completion(.failure(URLRequestError.decodingError))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }

    private func createPrompt(from repository: Repository) -> String {
        var prompt = "Create a story about the Git repository. Highlight the development journey, key events, and patterns. Details:\n"

        prompt += "- Repository URL: \(repository.url)\n"
        
        prompt += "- Include arcs about major feature developments, bug fixes, and team collaborations.\n"
        
        prompt += "- Give the names of the key contributors. For each key contributor, summarize their commit patterns either in time, frequency, commit messages, etc."
        
//        let repoJson = try encoder.encode(repository.commits)
//        guard let repoStr = String(data: repoJson, encoding: .utf8) else {
//            return nil
//        }
//        prompt += repoStr
        

        return prompt
    }
    

    enum URLRequestError: Error {
        case invalidURL
        case noData
        case decodingError
    }
}

