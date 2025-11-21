//
//  String+Utils.swift
//  VersionFilePlugin
//
//  Created by Mathew Gacy on 11/23/22.
//

import Foundation

/// Easily throw generic errors with a text description.
extension String: LocalizedError {
    public var errorDescription: String? {
        return self
    }
}

extension String {
    /// Returns an array of strings matching the given regular expression.
    ///
    /// Adapted from: https://stackoverflow.com/a/27880748
    ///
    /// - Parameter regEx: The regular expression to match against.
    /// - Returns: An array of strings that match the regular expression.
    func matches(for regEx: NSRegularExpression) -> [String] {
        let results = regEx.matches(
            in: self,
            range: NSRange(startIndex..., in: self))

        return results.map {
            String(self[Range($0.range, in: self)!])
        }
    }
}
