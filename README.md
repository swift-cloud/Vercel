# Vercel

A Swift runtime and SDK for Vercel Serverless Functions.

[Vercel Starter Kit](https://github.com/swift-cloud/vercel-starter-kit)

### How does this work?

There's two important pieces to this package that make everything work:

1. An SDK that wraps the [AWSLambdaRuntime](https://github.com/swift-server/swift-aws-lambda-runtime) and provides access to Vercel specific API like `EdgeConfig`
2. A Swift Package Plugin which builds your code and produces a directory structure compliant with Vercel's [Build Output API](https://vercel.com/docs/build-output-api/v3)

## Usage

### Request Handler

```swift
import Vercel

@main
struct App: RequestHandler {

    func onRequest(_ req: Request, context: Context) async throws -> Response {
        let greeting = EdgeConfig.default.get("greeting").string!
        return .status(.ok).send("Hello, \(greeting)")
    }
}
```

### Express Handler

```swift
import Vercel

@main
struct App: ExpressHandler {

    static let router = Router()
        .get("/") { req, res in
            res.status(.ok).send("Hello, Swift")
        }
        .get("/api/me") { req, res in
            try res.cors().send(["name": "Andrew"])
        }
        .get("/hello/:name") { req, res in
            res.send("Hello, " + req.pathParams["name"]!)
        }
}
```

### Data Fetching

You can use any popular library to fetch data such as Alamofire of async-http-client but we also provide a convenient `fetch()` method directly in this package:

```swift
let obj = try await fetch("https://httpbin.org/json").json()
```

### Edge Config

This package provides full access to Vercel's [Edge Config](https://vercel.com/docs/concepts/edge-network/edge-config) API. You can access the default edge config store or any additinoal store assigned to your project:

```swift
// Default edge config
let str = EdgeConfig.default.get("some-string-key").string

// Edge config assigned to an environment variable
let num = EdgeConfig("EDGE_CONFIG_2").get("some-int-key").integer
```

### Static Files

You can add a top level `public` folder that will be deployed statically to Vercel's CDN.

## Deploy

### Locally

To deploy your project locally you need to install Docker and the Vercel CLI. Once installed you can you must link your Vercel project:

```bash
vercel link
```

After linking your project you can deploy it via Swift package manager:

```bash
swift package --disable-sandbox vercel
```

### GitHub Actions

Use the following GitHub actions workflow to continuiously deploy your project to Vercel:

```yaml
name: Vercel

on:
  push:
    branches:
      - main

env:
  VERCEL_ORG_ID: ${{ secrets.VERCEL_ORG_ID }}
  VERCEL_PROJECT_ID: ${{ secrets.VERCEL_PROJECT_ID }}
  VERCEL_TOKEN: ${{ secrets.VERCEL_TOKEN }}

jobs:
  deploy:
    runs-on: ubuntu-latest
    container: swift:5.7-amazonlinux2

    steps:
      - uses: actions/checkout@v3

      - uses: actions/cache@v3
        with:
          path: .build
          key: ${{ runner.os }}-spm-${{ hashFiles('Package.resolved') }}
          restore-keys: |
            ${{ runner.os }}-spm-

      - uses: actions/setup-node@v3
        with:
          node-version: 16

      - name: Install
        run: npm install -g vercel@latest

      - name: Deploy
        run: swift package --disable-sandbox vercel --prod
```
