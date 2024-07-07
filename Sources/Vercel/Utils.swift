//
//  Utils.swift
//  
//
//  Created by Andrew Barba on 1/22/23.
//

import Foundation

extension CharacterSet {

    public static let javascriptURLAllowed: CharacterSet =
        .alphanumerics.union(.init(charactersIn: "-_.!~*'()")) // as per RFC 3986
}

extension DateFormatter {

    public static let httpDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        return formatter
    }()
}
