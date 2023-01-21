//
//  InvokeEvent.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

import Foundation

public struct InvokeEvent: Codable, Sendable {
    public let body: String

    internal func request() throws -> Request {
        let data = Data(body.utf8)
        return try JSONDecoder().decode(Request.self, from: data)
    }
}
