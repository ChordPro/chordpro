//
//  LocalizedAlertError.swift
//  ChordProMac
//

import SwiftUI

/// A localised wrapper for an `Error`
struct LocalizedAlertError: LocalizedError {
    /// The underlying error
    let underlyingError: LocalizedError
    /// The error description
    var errorDescription: String? {
        underlyingError.errorDescription
    }
    /// The recovery suggestion
    var recoverySuggestion: String? {
        underlyingError.recoverySuggestion
    }
    /// Init the structure
    /// - Parameter error: The `Error`
    init?(error: Error?) {
        guard let localizedError = error as? LocalizedError else { return nil }
        underlyingError = localizedError
    }
}
