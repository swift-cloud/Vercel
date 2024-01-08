//
//  Plugin.swift
//
//
//  Created by Andrew Barba on 1/21/23.
//

import Foundation
import PackagePlugin

@main
struct VercelPackager: CommandPlugin {
    func performCommand(context: PackagePlugin.PluginContext, arguments: [String]) async throws {
        Shell.prepare()
        let vercelOutput = VercelOutput(packageManager: packageManager, context: context, arguments: arguments)
        if vercelOutput.isServer {
            try await vercelOutput.proxyServer()
        } else if vercelOutput.isDev {
            try await vercelOutput.dev()
        } else {
            try await build(vercelOutput)
        }
    }

    private func build(_ vercelOutput: VercelOutput) async throws {
        try await vercelOutput.prepare()
        try await vercelOutput.build()
        if vercelOutput.isDeploy {
            try await vercelOutput.deploy()
        }
    }
}
