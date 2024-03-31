//
//  CommitDetailView.swift
//  hackprinceton
//
//  Created by Anthony Li on 3/29/24.
//

import SwiftUI
import CodeViewer

extension PresentationDetent {
    static let customMedium = PresentationDetent.fraction(0.4)
}

struct CommitDetailView: View {
    var commit: Commit
    @State var githubAPI: GitHubAPI
    @State var isLoading = false
    
    // TODO: request gpt
    @State var gptResult: String?
    @State var currentPresentationDetent = PresentationDetent.customMedium
        
    @Environment(\.openURL) private var openURL

    static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter
        }()
    
    
    @Environment(\.dismissWindow) var dismissWindow
    
    var body: some View {
        
        VStack {
            HStack(spacing: 24) {
                Spacer()
                #if os(visionOS)
                Button {
                    dismissWindow(id: "Commit")
                } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                }
                .help("Exit View")
                #endif
                Text(CommitDetailView.dateFormatter.string(from: commit.date)).monospaced().font(.subheadline).foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                Button(action: {
                    Task {
                        do {
                            let commitUrl = "\(githubAPI.repository.url)/commit/\(commit.sha)"
                            isLoading = true
                            let response = try await mintRepository(commitUrl: commitUrl)
                            isLoading = false
                            // Handle the response
                            print(response)
                        } catch {
                            // Handle error
                            print(error)
                        }
                    }
                }) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.green)
                }
                .help("Mint NFT")
                Spacer()
            }
                if (isLoading) {
                    ProgressView()
                }
                if (currentPresentationDetent == PresentationDetent.large) {
                    VStack {
                        VStack(alignment: .leading) {
                            TabView {
                                CommitDiffView(commit: commit, githubAPI: githubAPI).tabItem {
                                    Text("View Diff")
                                }
                                
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
        .padding()
        .presentationDetents([.customMedium, .large], selection: $currentPresentationDetent)
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled)
        .presentationBackground(.regularMaterial)
    }
    
    func mintRepository(commitUrl: String) async throws {
        guard let verbwire_api_key = Bundle.main.object(forInfoDictionaryKey:"VERBWIRE_API") else {
            fatalError("Missing key")
        }

        let content = try MultipartBody {
            try MultipartContent(name: "allowPlatformToOperateToken", content: "true")
            try MultipartContent(name: "chain", content: "sepolia")
            try MultipartContent(name: "metadataUrl", content: commitUrl)
        }
        
        let headers = [
          "accept": "application/json",
          "content-type": content.contentType,
          "X-API-Key": verbwire_api_key as! String
        ]

        let request = NSMutableURLRequest(url: NSURL(string: "https://api.verbwire.com/v1/nft/mint/quickMintFromMetadataUrl")! as URL,
                                                cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = try content.assembleData()
        request.timeoutInterval = 60

        let session = URLSession.shared
        let (urlResponse, _) = try await URLSession.shared.data(for: request as URLRequest)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601  // Handling ISO 8601 formatted dates
            
        let result = try decoder.decode(MintResponse.self, from: urlResponse)
        openURL(URL(string: result.quick_mint.blockExplorer)!)
    }
}


struct MintResponse: Decodable  {
    struct QuickMintResponse: Decodable {
        let blockExplorer: String
        let transactionID: String
        let transactionHash: String
        let status: String
    }
    let quick_mint: QuickMintResponse
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
//                        Text(commit.title)
                        EmojiTextView(commit.title)
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

/// View for a Diff commits are associated with
struct CommitDiffView: View {
    @State var diff: [String]?
    var commit: Commit
    var githubAPI: GitHubAPI
    
    var body: some View {
        VStack() {
            CommitMetadataView(commit: commit, hideDescription: true)
            
            VStack(spacing: 32) {
                if let diff {
                    ForEach(diff) { d in
                        CodeViewer(
                            content: .constant(d),
                            mode: .json,
                            darkTheme: .solarized_dark,
                            lightTheme: .solarized_light,
                            isReadOnly: true,
                            fontSize: 24
                        )
                        .clipShape(.rect(cornerRadius: 16))
                    }
                } else {
                    ProgressView("Loading diff...")
                        .frame(maxHeight: .infinity)
                        .controlSize(.large)
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
                        // TODO: Cache diffs
                    }
                } catch {
                    logger.error("Failed to populate repo! \(error)")
                }
            }
        })
    }
    
}

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
