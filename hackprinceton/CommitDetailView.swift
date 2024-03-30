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
    @State var diff: String?

    
    var body: some View {
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
                /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Code@*/ /*@END_MENU_TOKEN@*/diff = """
                {
                "hello": "world"
                }
                """
            }).tabViewStyle(.page)
    }
}

struct CommitMetadataView: View {
//    @State var thing = false
    var commit: Commit

    var body: some View {
        HStack {
            Circle()
                .fill(.background)
                .frame(width: 64, height: 64)
            
            VStack(alignment: .leading, spacing: 16) {
                
                VStack() {
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
        .background(.black.opacity(0.2))
        .clipShape(.rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.black)
        }
        
        
    }
}

struct CommitDiffView: View {
    var diff: String
    
    var body: some View {
        
        CodeViewer(
            content: .constant(diff),
            mode: .json,
            darkTheme: .solarized_dark,
            lightTheme: .solarized_light,
            isReadOnly: true,
            fontSize: 54
        )
        .padding(24)
        .background(.black.opacity(0.2))
        .clipShape(.rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.black)
        }
    }
    
}


#Preview {
    CommitDetailView(commit: .dummy)
}
