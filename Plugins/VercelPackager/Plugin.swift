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
        let vercelOutput = VercelOutput(packageManager: packageManager, context: context, arguments: arguments)
        if vercelOutput.isDev {
            try await dev(vercelOutput)
        } else {
            try await build(vercelOutput)
        }
    }

    private func build(_ vercelOutput: VercelOutput) async throws {
        try await vercelOutput.prepare()
        try await vercelOutput.build()
        if vercelOutput.isDeploy {
            try await vercelOutput.deploy()
            return
        }
    }

    private func dev(_ vercelOutput: VercelOutput) async throws {
        try await vercelOutput.dev()
    }
}
