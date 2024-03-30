//
//  CommitDetailView.swift
//  hackprinceton
//
//  Created by Anthony Li on 3/29/24.
//

import SwiftUI
import CodeViewer

struct CommitDetailView: View {
    var commit: Commit
    
    @State var diff: [String]?

    

    private let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter
        }()
    
    
    var body: some View {
        
        VStack(alignment: .trailing) {
            
            Text(dateFormatter.string(from: commit.date)).monospaced().font(.subheadline).foregroundColor(.primary)
            
            VStack(alignment: .leading) {
                TabView {
                    
                    CommitMetadataView(commit: commit)
                        .tabItem {
                            Text("Metadata")
                        }
                    
                    if diff != nil {
                        CommitDiffView(diff: diff!).tabItem {
                            Text("View Diff")
                        }
                    }
                }.onAppear(perform: {
                    /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Code@*/ /*@END_MENU_TOKEN@*/diff = ["""
                {
                "hello": "world"
                }
                """]
                }).tabViewStyle(.page)
                
            }
            .background(.black.opacity(0.2))
            .clipShape(.rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.black)
            }
            
        }
    }
}

/// View for seeing all Commit Metadata
struct CommitMetadataView: View {
//    @State var thing = false
    var commit: Commit
    
    var body: some View {
        
            HStack {
                Group {
                    if let avatarURL = commit.avatar_url {
                        AsyncImage(url: URL(string: avatarURL))
                    } else {
                        Rectangle().fill(.green)
                    }
                }
                .frame(width: 64, height: 64)
                .padding(20)
                .background(Color.green)
                .clipShape(Circle())
                
                
                VStack(alignment: .leading, spacing: 16) {
                    
                    VStack(alignment: .leading) {
                        Text(commit.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        
                        HStack() {
                            
                            Text(commit.author)
                            
                            Spacer()
                            
                            HStack() {
                                Image(systemName: "arrow.triangle.branch")
                                    .font(.system(size: 20, weight: .light))
                                
                                Text(commit.sha)
                            }
                            
                        }.monospaced().font(.subheadline)
                    }
                    
                    if commit.description != nil {
                        
                        Text(commit.description!).lineLimit(3)
                    }
                    
                }
            }
            .padding()
        

        
        
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
    var diff: [String]
    
    var body: some View {
        VStack() {
            VStack(spacing: 16) {
                ForEach(diff) { d in
                    CodeViewer(
                        content: .constant(d),
                        mode: .json,
                        darkTheme: .solarized_dark,
                        lightTheme: .solarized_light,
                        isReadOnly: true,
                        fontSize: 54
                    )
                }
            }.padding(24)
        }
    }
    
}


#Preview {
    CommitDetailView(commit: .dummy)
}
