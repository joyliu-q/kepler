//
//  Constants.swift
//  hackprinceton
//
//  Created by Joy Liu on 3/30/24.
//

import Foundation
import SwiftUI
import Combine

struct Project {
    static let title: String = "Kepler"
}

func GET_EMOJIS() -> [String: String]  {
    guard let path = Bundle.main.path(forResource: "emojis", ofType: "json") else { fatalError("Cannot find emoji.json") }
    let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
    return try! JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as! Dictionary<String, String>
}

let EMOJIS = GET_EMOJIS()

struct EmojiTextView: View {
    var textWithEmoji: String
    @State var extractedText: String
    @State private var emojiImage: UIImage?
    
    init(_ textWithEmoji: String) {
        self.textWithEmoji = textWithEmoji
        self.extractedText = textWithEmoji
    }
    
    var body: some View {
        HStack {
            if let image = emojiImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            }
            Text(extractedText)
        }
        .task(id: textWithEmoji, {
            emojiImage = nil
            await loadEmoji(commitMessage: textWithEmoji)
        })
    }
    
    func extractEmojiAndText(from string: String) -> (emoji: String?, restOfString: String) {
        let pattern = ":(.*?):"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return (nil, string)
        }
        
        let nsRange = NSRange(string.startIndex..., in: string)
        guard let match = regex.firstMatch(in: string, options: [], range: nsRange) else {
            return (nil, string)
        }
        
        let emojiRange = Range(match.range(at: 1), in: string)
        let fullMatchRange = Range(match.range(at: 0), in: string)
        
        let emoji = emojiRange.flatMap { String(string[$0]) }
        let restOfString = fullMatchRange.flatMap { string.replacingCharacters(in: $0, with: "") }
        
        return (emoji, restOfString ?? string)
    }
    
    func loadEmoji(commitMessage: String) async {
        let (emoji, rest) = extractEmojiAndText(from: commitMessage)
        extractedText = rest
        guard let emoji, let urlString = EMOJIS[emoji] else { return }
        guard let emojiURL = URL(string: urlString) else { return }
        let req = URLRequest(url: emojiURL)
        guard let (data, _) = try? await URLSession.shared.data(for: req) else { return }
        guard let image = UIImage(data: data) else { return }
        self.emojiImage = image
    }
}
