//
//  ChordProDocument.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    /// Define the UTType for a **ChordPro** song
    static var chordProSong: UTType {
        UTType(importedAs: "org.chordpro")
    }
}

/// Define the  **ChordPro** document
struct ChordProDocument: FileDocument {
    /// Give the file an unique ID
    let fileID = UUID().uuidString
    /// The text of the file
    var text: String
    /// Init the text
    init(text: String = "{title: New Song}") {
        self.text = text
    }
    /// The UTType of the file
    static var readableContentTypes: [UTType] { [.chordProSong] }
    /// Black magic
    init(configuration: ReadConfiguration) throws {
        guard
            let data = configuration.file.regularFileContents,
            let string = String(data: data, encoding: .utf8)
        else {
            throw AppError.readDocumentError
        }
        text = string
    }
    /// Save the file
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = text.data(using: .utf8) else {
            throw AppError.writeDocumentError
        }
        return .init(regularFileWithContents: data)
    }
}
