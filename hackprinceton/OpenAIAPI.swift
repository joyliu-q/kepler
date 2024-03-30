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
    
    func testQuery() async {
        let query = ChatQuery(model: .gpt3_5Turbo,
                              messages: [
                                         .init(role: .user, content: "What is the capital of France")],
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
    
    func generateStory(repository: Repository) async {
        var prompt = "Create a story about the given Git repository. Highlight the development journey, key events, and patterns. Details:\n"
        
        prompt += "- Include arcs about major feature developments, bug fixes, and team collaborations.\n"
        
        prompt += "- Give the names of the key contributors. For each key contributor, summarize their commit patterns either in time, frequency, commit messages, etc. Also look based on commit to see if each of the key contributors on any specific role in the project, such as backend work, frontend work, databases, etc.\n"
        
        prompt += "- Get overall patterns and insights drawn from all the commits (such as pace of commits, timeline insights, overall patterns. If there were a lot of really fast commits before, and then the pace slowed down, then flag that. You can also look at how often people come and go. Also time in between commits could be useful, and how fast it takes for people to push too.) Keep these concise but encompassing.\n"
        prompt += "The format of your response should include Arcs, a comma-separated list of the story arcs; keyContributors, with the key contributors and the patterns you found in the following format ['Author': ['Some Pattern']]; overallPatterns, a short description of the overall patterns/insights. Arcs, keyContributors, and overallPatterns should be separated by new lines. Don't be repetitive."

        let query = ChatQuery(model: "gpt-3.5-turbo-0613",
                              messages: [.init(role: .system, content: prompt),
                                         .init(role: .user, content: await createPrompt(from: repository))],
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

    func createPrompt(from repository: Repository) async -> String {
        // TODO: analyze issues and comments
        var prompt = "Repository URL: \(repository.url)\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        let sortedCommits = repository.commits.values.sorted { $0.date < $1.date }
        if let firstCommitDate = sortedCommits.first?.date, let lastCommitDate = sortedCommits.last?.date {
            prompt += "Development Journey: From \(dateFormatter.string(from: firstCommitDate)) to \(dateFormatter.string(from: lastCommitDate)).\n"
        }
        let contributorsFrequency = Dictionary(grouping: sortedCommits, by: { $0.author }).mapValues { $0.count }
        let sortedContributors = contributorsFrequency.sorted { $0.value > $1.value }.prefix(5)
        prompt += "Key Contributors: " + sortedContributors.map { "\($0.key) (\($0.value) commits)" }.joined(separator: ", ") + ".\n"
        
            
        prompt += "Commit History:\n"
            
        for commit in repository.commits.values.sorted(by: { $0.date < $1.date }) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let dateString = dateFormatter.string(from: commit.date)
            
            let title = commit.title
            let description = commit.description ?? "No description provided."
            
            prompt += "  Author: \(commit.author)\n"
            prompt += "  Date: \(dateString)\n"
            prompt += "  Title: \(title)\n"
            prompt += "  Description: \(description)\n"
            
            // Add a separator for readability
            prompt += "\n"
        }
        
        // Final message to wrap up the prompt, if needed
        prompt += "End of Commit History.\n"
        print(prompt)
        
        return prompt
    }
    

    enum URLRequestError: Error {
        case invalidURL
        case noData
        case decodingError
    }
}

