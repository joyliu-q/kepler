//
//  OpenAIAPI.swift
//  hackprinceton
//
//  Created by Joy Liu on 3/30/24.
//

import Foundation
import OpenAI

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
    
    func generateStory(repository: Repository,  completion: @escaping (Result<String, Error>) -> Void) async {
        var prompt = "Create a story about the given Git repository. Highlight the development journey, key events, and patterns. Details:\n"
        
        prompt += "- Include arcs about major feature developments, bug fixes, and team collaborations.\n"
        
        prompt += "- Give the names of the key contributors. For each key contributor, summarize their commit patterns either in time, frequency, commit messages, etc. Also look based on commit to see if each of the key contributors on any specific role in the project, such as backend work, frontend work, databases, etc."

        let query = ChatQuery(model: .gpt3_5Turbo,
                              messages: [.init(role: .system, content: prompt),
                                         .init(role: .user, content: createPrompt(from: repository))],
                              temperature: 0.5,
                              user: "testUser")
        do {
            enum Error: Swift.Error {
                case missingKey, invalidValue
            }
            guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_APIKEY") else {
                throw Error.missingKey
            }
            if let openai_api = apiKey as? String {
                print(openai_api)
                let openAI = OpenAI(apiToken: openai_api)
                let result = try await openAI.chats(query: query)
                for choice in result.choices {
                    print(choice.message.content ?? "o")
                }
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }

    private func createPrompt(from repository: Repository) -> String {
        // TODO: analyze issues and comments
        var prompt = "Repository URL: \(repository.url)\n"
        
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

