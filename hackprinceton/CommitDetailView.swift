//
//  CommitDetailView.swift
//  hackprinceton
//
//  Created by Anthony Li on 3/29/24.
//

import SwiftUI
#if os(iOS)
import CodeViewer
#endif

extension PresentationDetent {
    static let customMedium = PresentationDetent.fraction(0.4)
}

struct CommitDetailView: View {
    @State var commit: Commit
    @State var githubAPI: GitHubAPI
    
    @State var diff: [String]?
    // TODO: request gpt
    @State var gptResult: String?
    @State private var currentPresentationDetent = PresentationDetent.customMedium

    static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter
        }()
    
    
    var body: some View {
        
        VStack {
            Text(CommitDetailView.dateFormatter.string(from: commit.date)).monospaced().font(.subheadline).foregroundColor(.primary)
            
            if (currentPresentationDetent == PresentationDetent.large) {
                VStack {
                    
                
                VStack(alignment: .leading) {
                    TabView {
                        
#if os(iOS)
                        if diff != nil {
                            CommitDiffView(diff: diff!, commit: commit).tabItem {
                                Text("View Diff")
                            }
                        }
#endif
                        
                        if gptResult != nil {
                            CommitGptView(gpt: gptResult!, commit: commit).tabItem {
                                Text("GPT Analyze")
                            }
                        }
                    }.tabViewStyle(.page)
                }}} else { 
                    VStack() {
                        Spacer()
                        CommitMetadataView(commit: commit)
                        Spacer()
                        Button(action: {
                            currentPresentationDetent = currentPresentationDetent == PresentationDetent.large ? PresentationDetent.customMedium : PresentationDetent.large
                        }) {
                            Text("Expand to View Details")
                        }
                    }
                }
        }
        .task({
            if commit.diff != nil {
                diff = commit.diff
            } else {
                do {
                    if let diffStr = try await githubAPI.getDiff(sha: commit.sha) {
                        diff = [diffStr]
                        commit.diff = diff
                    }
                    
                } catch {
                    logger.error("Failed to populate repo! \(error)")
                }
            }
        })
        .padding(.horizontal)
        .presentationDetents([.customMedium, .large], selection: $currentPresentationDetent)
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled)
        .presentationBackground(.regularMaterial)
    }
}

/// View for seeing all Commit Metadata
struct CommitMetadataView: View {
    var commit: Commit
    var hideDescription = false
    
    var body: some View {
        
        HStack(alignment: .top) {
                Group {
                    if let avatarURL = commit.avatar_url {
                        AsyncImage(url: URL(string: avatarURL)) {
                            phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image.resizable()
                                     .aspectRatio(contentMode: .fill)
                                     .clipShape(Circle())
                            case .failure:
                                Image(systemName: "photo")
                            @unknown default:
                                // Since the AsyncImagePhase enum isn't frozen,
                                // we need to add this currently unused fallback
                                // to handle any new cases that might be added
                                // in the future:
                                EmptyView()
                            }
                        }
                            
                    } else {
                        Circle().fill(.white)
                    }
                }
                .frame(width: 64, height: 64)
                
                
                VStack(alignment: .leading, spacing: 16) {
                    
                    VStack(alignment: .leading) {
                        Text(commit.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .lineLimit(3)
                        
                        
                        HStack() {
                            
                            Text(commit.author)
                            
                            Spacer()
                            
                            HStack() {
                                Image(systemName: "arrow.triangle.branch")
                                    .font(.system(size: 20, weight: .light))
                                
                                Text(commit.sha.prefix(6))
                            }
                            
                        }.monospaced().font(.subheadline)
                    }
                    
                    if commit.description != nil && !hideDescription {
                        
                        Text(commit.description!).lineLimit(3)
                    }
                    
                }
            }
        

        
        
    }
}

// TODO: this is very bad code
extension String: Identifiable {
    public var id: String {
        self
    }
}

#if os(iOS)
/// View for a Diff commits are associated with
struct CommitDiffView: View {
    var diff: [String]
    var commit: Commit
    
    var body: some View {
        VStack() {
            CommitMetadataView(commit: commit, hideDescription: true)
            
            VStack(spacing: 16) {
                ForEach(diff) { d in
                    CodeViewer(
                        content: .constant(d),
                        mode: .json,
                        darkTheme: .solarized_dark,
                        lightTheme: .solarized_light,
                        isReadOnly: true,
                        fontSize: 24
                    )
                }
            }.padding(24)
        }
    }
    
}
#endif

struct CommitGptView: View {
    var gpt: String
    var commit: Commit

    var body: some View {
        VStack() {
            CommitMetadataView(commit: commit, hideDescription: true)
            
            VStack(spacing: 16) {
                Text(gpt)
            }.padding(24)
        }
    }
    
}


#Preview {
    CommitDetailView(commit: .dummy, githubAPI: GitHubAPI(repositoryURL: "https://github.com/joyliu-q/hackprinceton")!)
}
