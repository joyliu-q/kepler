//
//  Multipart.swift
//  Code derived from https://github.com/pennlabs/penn-mobile-ios/blob/1e4db571237b40a6beb3dd500c7035da95153c58/PennMobileShared/Networking%20%2B%20Analytics/Multipart.swift#L37
//
//
// The MIT License (MIT)
//
// Copyright (c) 2018 Penn Labs
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

public extension Data {
   mutating func append(_ string: String) {
      if let data = string.data(using: .utf8) {
         append(data)
      }
   }
}

public struct MultipartContent {
    public var type: String
    public var name: String
    public var filename: String?
    public var data: Data
    
    public init(type: String, name: String, filename: String? = nil, data: Data) {
        self.type = type
        self.name = name
        self.filename = filename
        self.data = data
    }
    
    public init(type: String, name: String, filename: String? = nil, data: () -> Data) {
        self.init(type: type, name: name, filename: filename, data: data())
    }
    
    public init(name: String, content: String) throws {
        let converted = content.split(separator: /\r|\n|\r\n/).joined(separator: "\r\n")
        guard let data = converted.data(using: .utf8) else {
            throw MultipartError.stringEncodingError
        }
        
        self.init(type: "text/plain", name: name, data: data)
    }
}

@resultBuilder
public struct MultipartBuilder {
    public static func buildExpression(_ expression: MultipartContent) -> [MultipartContent] {
        [expression]
    }
    
    public static func buildBlock(_ components: [MultipartContent]...) -> [MultipartContent] {
        Array(components.joined())
    }
    
    public static func buildOptional(_ component: [MultipartContent]?) -> [MultipartContent] {
        component ?? []
    }
    
    public static func buildEither(first component: [MultipartContent]) -> [MultipartContent] {
        component
    }
    
    public static func buildEither(second component: [MultipartContent]) -> [MultipartContent] {
        component
    }
    
    public static func buildArray(_ components: [[MultipartContent]]) -> [MultipartContent] {
        Array(components.joined())
    }
    
    public static func buildLimitedAvailability(_ component: [MultipartContent]) -> [MultipartContent] {
        component
    }
}

public enum MultipartError: Error {
    case invalidBoundaryLength
    case invalidBoundaryCharacter
    case invalidContentType
    case invalidName
    case invalidFilename
    case stringEncodingError
}

public struct MultipartBody {
    public static func generateBoundary() -> String {
        UUID().uuidString
    }
    
    public static func escape(string: String) -> String {
        let replaced = string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(replaced)\""
    }
    
    public static let validCharacters = CharacterSet(charactersIn: "-_'").union(.alphanumerics)
    
    public var boundary: String
    public var content: [MultipartContent]
    
    public init(boundary: String = generateBoundary(), content: [MultipartContent]) throws {
        if !(27...70).contains(boundary.count) {
            throw MultipartError.invalidBoundaryLength
        }
        
        if !boundary.unicodeScalars.allSatisfy({ Self.validCharacters.contains($0) }) {
            throw MultipartError.invalidBoundaryCharacter
        }
        
        self.boundary = boundary
        self.content = content
    }
    
    public init(boundary: String = generateBoundary(), @MultipartBuilder _ content: () throws -> [MultipartContent]) throws {
        try self.init(boundary: boundary, content: content())
    }
    
    public var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }
    
    public func assembleData() throws -> Data {
        var data = Data()
        let crlf = "\r\n"
        
        for part in content {
            data.append("--\(boundary)\(crlf)")
            
            if part.type.contains(crlf) {
                throw MultipartError.invalidContentType
            }
            
            if part.name.contains(crlf) {
                throw MultipartError.invalidName
            }
            
            if let filename = part.filename, filename.contains(crlf) {
                throw MultipartError.invalidFilename
            }
            
            var headers = "Content-Disposition: form-data; name=\(Self.escape(string: part.name))"
            if let filename = part.filename {
                headers += "; filename=\(Self.escape(string: filename))"
            }
            headers += "\(crlf)\(crlf)"
            data.append(headers)
            data.append(part.data)
            data.append(crlf)
        }
        
        data.append("--\(boundary)--\(crlf)")
        return data
    }
}
