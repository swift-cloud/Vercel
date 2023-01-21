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
        try vercelOutput.prepare()
        try vercelOutput.build()
        try vercelOutput.deploy()
    }
}
