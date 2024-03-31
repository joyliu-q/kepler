//
//  OnboardView.swift
//  hackprinceton
//
//  Created by Joy Liu on 3/30/24.
//

import SwiftUI


let COMMON_URLS = [
    "https://github.com/joyliu-q/hackprinceton",
    "https://github.com/pennlabs/infrastructure",
    "https://github.com/pennlabs/penn-mobile",
]

struct OnboardView: View {
    
    @Binding var githubAPI: GitHubAPI
    @State var repositoryURL: String = ""
    var onSubmit: () -> Void = {}
    
    var body: some View {
        VStack() {
            VStack() {
                VStack(alignment: .leading) {
                    Text ("GitGraph").font(.title).bold()
                    
                    Text ("GitHub Repository").font(.headline)
                    TextField("", text: $repositoryURL, prompt: Text("Enter Repository URL")).onSubmit {
                        if let res = GitHubAPI(repositoryURL: repositoryURL) {
                            githubAPI = res
                            onSubmit()
                        }
                    }
                }
                VStack(spacing: 8) {
                    ForEach(COMMON_URLS, content: {url in
                        Button(action: {
                            repositoryURL = url
                            if let res = GitHubAPI(repositoryURL: repositoryURL) {
                                githubAPI = res
                            }
                        }) {
                            Text(removeHttps(urlString: url))
                        }.buttonStyle(.bordered)
                    })
                }
            }.padding(24)
        }
    }
    
    private func removeHttps(urlString: String) -> String {
        return urlString
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "https://", with: "")
    }
}

#Preview {
    OnboardView(githubAPI: .constant(
        GitHubAPI(repositoryURL: "https://github.com/joyliu-q/hackprinceton")!), repositoryURL: "https://github.com/joyliu-q/hackprinceton")
}
