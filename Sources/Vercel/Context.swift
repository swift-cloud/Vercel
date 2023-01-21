//
//  Context.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

import AWSLambdaRuntime
import Logging

public struct Context: Sendable {

    internal let context: LambdaContext

    internal init(_ context: LambdaContext) {
        self.context = context
    }
}

extension Context {

    public var requestID: String {
        context.requestID
    }

    public var traceID: String {
        context.traceID
    }

    public var deadline: DispatchWallTime {
        context.deadline
    }

    public var logger: Logger {
        context.logger
    }
}
