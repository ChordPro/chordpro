//
//  PlainTextDocument.swift
//  ChordProMac
//

import SwiftUI
import UniformTypeIdentifiers

/// Define a **ChordPro** plain text file like Log or Songbook
struct PlainTextDocument: FileDocument {
    /// The UTType to export
    static var readableContentTypes: [UTType] { [.plainText] }
    /// The text to export
    var text: String
    /// Init the struct
    init(text: String?) {
        self.text = text ?? "Empty Text"
    }
    /// Init the configuration
    init(configuration: ReadConfiguration) throws {
        guard
            let data = configuration.file.regularFileContents,
            let text = String(data: data, encoding: .utf8)
        else {
            throw AppError.readDocumentError
        }
        self.text = text
    }
    /// Save the exported text
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = text.data(using: .utf8) else {
            throw AppError.writeDocumentError
        }
        return .init(regularFileWithContents: data)
    }
}
