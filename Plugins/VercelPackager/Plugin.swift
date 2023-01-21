//
//  Plugin.swift
//  
//
//  Created by Andrew Barba on 1/20/23.
//

import Foundation
import PackagePlugin

@main
struct VercelPackager: CommandPlugin {

    func performCommand(context: PackagePlugin.PluginContext, arguments: [String]) async throws {
        print("Packaging...")
    }
}
