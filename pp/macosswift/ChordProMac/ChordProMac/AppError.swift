//
//  AppError.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import Foundation

/// All errors that can happen in the application
enum AppError: String, LocalizedError {
    /// A read error
    case readDocumentError
    /// A write error
    case writeDocumentError
    /// A settings error
    case saveSettingsError
    /// A binary error if **chordpro** is not found in the package
    case binaryNotFound
}
