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
    /// A binary error if **ChordPro** is not found in the package
    case binaryNotFound
    /// An error when a custom file is not found
    case customFileNotFound
    /// An error when **ChordPro** did not create a PDF
    case pdfCreationError
    /// An error when **ChordPro** did  create a PDF but gave errors
    case pdfCreatedWithErrors
    /// An error when **ChordPro** did  not complain but the PDF is not created because the song is empty
    case emptySong
    /// Not an error, all is well
    /// - Note: Used for PDF export
    case noErrorOccurred

}

// MARK: Protocol implementations

extension AppError {

    /// The description of the error
    var errorDescription: String? {
        switch self {
        case .emptySong:
            return "The song is empty"
        default:
            return "Something went wrong"
        }
    }

    /// The recovery suggestion
    var recoverySuggestion: String? {
        switch self {
        case .pdfCreationError:
            return "ChordPro was unable to create a PDF"
        case .pdfCreatedWithErrors:
            return "There where warnings when creating the PDF"
        case .emptySong:
            return "You cannot create a PDF when the song does not have content"
        case .noErrorOccurred:
            return "All is well"
        default:
            ///  This should not happen
            return "ChordPro is sorry"
        }
    }
}
