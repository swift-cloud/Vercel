@_exported import AWSLambdaRuntime
@_exported import AWSLambdaEvents
@_exported import Foundation

public struct LambdaInvokeEvent: Codable {
    public let body: String
}

public struct VercelRequest: Codable {
    public let method: HTTPMethod
    public let headers: HTTPHeaders
    public let path: String
    public let body: String?
}

public typealias VercelResponse = APIGatewayV2Response

public protocol VercelRequestHandler: SimpleLambdaHandler {

    func onRequest(_ req: VercelRequest, context: LambdaContext) async throws -> VercelResponse
}

extension VercelRequestHandler {

    public func handle(_ event: LambdaInvokeEvent, context: LambdaContext) async throws -> VercelResponse {
        let data = Data(event.body.utf8)
        let req = try JSONDecoder().decode(VercelRequest.self, from: data)
        return try await onRequest(req, context: context)
    }
}
