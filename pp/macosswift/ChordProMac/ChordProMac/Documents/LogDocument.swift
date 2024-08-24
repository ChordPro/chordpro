//
//  LogDocument.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 02/06/2024.
//

import SwiftUI
import UniformTypeIdentifiers

/// Define the **ChordPro** log as plain text
struct LogDocument: FileDocument {
    /// The UTType to export
    static var readableContentTypes: [UTType] { [.plainText] }
    /// The log to export
    var log: String
    /// Init the struct
    init(log: String?) {
        self.log = log ?? "Empty Log"
    }
    /// Black magic
    init(configuration: ReadConfiguration) throws {
        guard
            let data = configuration.file.regularFileContents
        else {
            throw AppError.readDocumentError
        }
        log = String(decoding: data, as: UTF8.self)
    }
    /// Save the exported Log
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = log.data(using: .utf8) else {
            throw AppError.writeDocumentError
        }
        return .init(regularFileWithContents: data)
    }
}
