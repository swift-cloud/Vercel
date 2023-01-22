# Vercel

A Swift runtime and SDK for Vercel Serverless Functions.

[swift-cloud/vercel-starter-kit](https://github.com/swift-cloud/vercel-starter-kit)

## Usage

### Request Handler

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
