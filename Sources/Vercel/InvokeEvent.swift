//
//  InvokeEvent.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

import Foundation

public struct InvokeEvent: Codable, Sendable {
    public struct Payload: Codable, Sendable {
        public let method: HTTPMethod
        public let headers: HTTPHeaders
        public let path: String
        public let body: String?
    }

    public let body: String
}
