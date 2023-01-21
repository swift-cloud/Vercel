//
//  Request.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

public struct Request: Decodable, Sendable {
    public let method: HTTPMethod
    public let headers: HTTPHeaders
    public let path: String
    public let body: String?
}
