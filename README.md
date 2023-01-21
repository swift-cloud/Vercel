# Vercel

A Swift runtime and SDK for Vercel Serverless Functions.

## Usage

```swift
import Vercel

@main
struct App: RequestHandler {

    func onRequest(_ req: Request, context: Context) async throws -> Response {
        let greeting = EdgeConfig.default["greeting"]
        return .init(statusCode: .ok, body: "Hello, \(greeting)")
    }
}
```

## Deploy

```sh
swift package vercel
```
