//
//  Verbwire.swift
//  hackprinceton
//
//  Created by Joy Liu on 3/30/24.
//

import Foundation

struct VerbwireAPI {
    
    func mintRepository(repositoryUrl: String) async throws -> MintResponse {
        guard let verbwire_api_key = Bundle.main.object(forInfoDictionaryKey:"VERBWIRE_API") else {
            fatalError("Missing key")
        }

        
        let headers = [
          "accept": "application/json",
          "content-type": "multipart/form-data; boundary=---011000010111000001101001",
          "X-API-Key": verbwire_api_key as! String
        ]
        
        let parameters = [
          [
            "name": "allowPlatformToOperateToken",
            "value": "true"
          ],
          [
            "name": "chain",
            "value": "sepolia"
          ],
          [
            "name": "metadataUrl",
            "value": repositoryUrl
          ]
        ]

        let boundary = "---011000010111000001101001"

        var body = ""
        var error: NSError? = nil
        for param in parameters {
          let paramName = param["name"]!
          body += "--\(boundary)\r\n"
          body += "Content-Disposition:form-data; name=\"\(paramName)\""
          if let filename = param["fileName"] {
            let contentType = param["content-type"]!
              let fileContent = try? String(contentsOfFile: filename, encoding: String.Encoding.utf8)
              if error != nil || fileContent == nil {
                print(error as Any)
              }
              body += "; filename=\"\(filename)\"\r\n"
              body += "Content-Type: \(contentType)\r\n\r\n"
              body += fileContent!
          } else if let paramValue = param["value"] {
            body += "\r\n\r\n\(paramValue)"
          }
        }

        let request = NSMutableURLRequest(url: NSURL(string: "https://api.verbwire.com/v1/nft/mint/quickMintFromMetadataUrl")! as URL,
                                                cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = body.data(using: .utf8)

        let session = URLSession.shared
        let (urlResponse, _) = try await session.data(for: request as URLRequest)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601  // Handling ISO 8601 formatted dates
            
        return try decoder.decode(MintResponse.self, from: urlResponse)
    }

}

struct MintResponse: Decodable  {
    struct QuickMintResponse: Decodable {
        let blockExplorer: String
        let transactionID: String
    }
    let quick_mint: QuickMintResponse
}
