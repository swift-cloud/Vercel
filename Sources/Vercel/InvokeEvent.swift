//
//  InvokeEvent.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

import Foundation
import HTTPTypes
import HTTPTypesFoundation

public struct InvokeEvent: Codable, Sendable {
    public struct Payload: Codable, Sendable {
        public let method: HTTPRequest.Method
        public let headers: [String: String]
        public let path: String
        public let body: String?
        public let encoding: String?
    }

    public let body: String
}

public struct InvokeResponse: Codable, Sendable {
    public enum Encoding: String, Codable, Sendable {
        case base64
    }

    public var statusCode: Int
    public var headers: [String: String]?
    public var body: String?
    public var encoding: Encoding?
    public var cookies: [String]?
}

extension HTTPRequest.Method: Codable {}
