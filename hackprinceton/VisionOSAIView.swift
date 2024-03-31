//
//  VisionOSAIView.swift
//  hackprinceton
//
//  Created by Anthony Li on 3/31/24.
//

import SwiftUI

struct VisionOSAIView: View {
    var githubAPI: GitHubAPI
    @State private var showAnalysis: Bool = false
    @State private var analysisResult: OpenAIAPI.AnalysisResult?
    
    var body: some View {
        Button("Generate Analysis") {
            Task {
                let openAI = OpenAIAPI()
                showAnalysis = true
                do {
                    analysisResult = try await openAI.generateStory(repository: githubAPI.repository)
                } catch {
                    print(error)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .sheet(isPresented: $showAnalysis) {
            NavigationStack {
                Group {
                    if let analysisResult = analysisResult {
                        ScrollView {
                            // VStack to display AnalysisResult
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Arcs:")
                                    .fontWeight(.bold)
                                ForEach(analysisResult.arcs, id: \.self) { arc in
                                    Text(arc)
                                }
                                
                                Text("\nKey Contributors:")
                                    .fontWeight(.bold)
                                ForEach(analysisResult.keyContributors.keys.sorted(), id: \.self) { key in
                                    Text("\(key): \(analysisResult.keyContributors[key]?.joined(separator: ", ") ?? "")")
                                }
                                
                                Text("\nOverall Patterns:")
                                    .fontWeight(.bold)
                                ForEach(analysisResult.overallPatterns, id: \.self) { pattern in
                                    Text(pattern)
                                }
                            }
                            .padding()
                        }
                    } else {
                        ProgressView()
                    }
                }
                .padding()
                .navigationTitle("AI Analysis")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem {
                        Button("Done") {
                            showAnalysis = false
                        }
                    }
                }
            }
            .frame(width: 300, height: 400)
        }
    }
}
