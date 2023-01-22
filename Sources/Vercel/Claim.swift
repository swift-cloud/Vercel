//
//  Claim.swift
//  
//
//  Created by Andrew Barba on 1/22/23.
//

public struct Claim: Sendable {

    /// Raw claim value.
    internal let value: Sendable?

    internal init(_ value: Sendable?) {
        self.value = value
    }

    /// Original claim value.
    public var rawValue: Sendable? {
        return self.value
    }

    /// Value of the claim as `String`.
    public var string: String? {
        return self.value as? String
    }

    /// Value of the claim as `Bool`.
    public var boolean: Bool? {
        return self.value as? Bool
    }

    /// Value of the claim as `Double`.
    public var double: Double? {
        var double: Double?
        if let string = self.string {
            double = Double(string)
        } else if self.boolean == nil {
            double = self.value as? Double
        }
        return double
    }

    /// Value of the claim as `Int`.
    public var integer: Int? {
        var integer: Int?
        if let string = self.string {
            integer = Int(string)
        } else if let double = self.double {
            integer = Int(double)
        } else if self.boolean == nil {
            integer = self.value as? Int
        }
        return integer
    }

    /// Value of the claim as `Date`.
    public var date: Date? {
        guard let timestamp: TimeInterval = self.double else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    /// Value of the claim as `[String]`.
    public var array: [String]? {
        if let array = self.value as? [String] {
            return array
        }
        if let value = self.string {
            return [value]
        }
        return nil
    }

    /// Value of the claim as `[String: Any]`.
    public var dictionary: [String: Sendable]? {
        if let dict = self.value as? [String: Sendable] {
            return dict
        }
        return nil
    }

    /// Special subscript syntax for chaining
    public subscript(_ key: String) -> Claim {
        return .init(self.dictionary?[key])
    }
}
