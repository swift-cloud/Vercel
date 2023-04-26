//
//  Utils.swift
//
//
//  Created by Andrew Barba on 1/21/23.
//

import Foundation
import PackagePlugin

public enum Architecture: String {
    case arm64 = "arm64"
    case x86 = "x86_64"
}

public struct Utils {

    public static var isAmazonLinux: Bool {
        if let data = FileManager.default.contents(atPath: "/etc/system-release"), let release = String(data: data, encoding: .utf8) {
            return release.hasPrefix("Amazon Linux")
        } else {
            return false
        }
    }

    public static var currentArchitecture: Architecture? {
        #if arch(arm64)
            return .arm64
        #elseif arch(x86_64)
            return .x86
        #else
            return nil
        #endif
    }
}

extension ToolsVersion {

    internal var versionString: String {
        "\(major).\(minor).\(patch)"
    }
}
