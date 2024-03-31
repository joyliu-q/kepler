//
//  Verbwire.swift
//  hackprinceton
//
//  Created by Joy Liu on 3/30/24.
//

import Foundation

struct VerbwireAPI {
    
    func mintRepository(commitUrl: String) async throws -> MintResponse {
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
            
        return try decoder.decode(MintResponse.self, from: urlResponse)
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
