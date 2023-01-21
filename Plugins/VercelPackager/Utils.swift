//
//  Utils.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

import Foundation

public struct Utils {

    public static var isAmazonLinux: Bool {
        if let data = FileManager.default.contents(atPath: "/etc/system-release"), let release = String(data: data, encoding: .utf8) {
            return release.hasPrefix("Amazon Linux")
        } else {
            return false
        }
    }
}
