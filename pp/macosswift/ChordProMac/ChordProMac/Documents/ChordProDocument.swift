//
//  ChordProDocument.swift
//  ChordProMac
//

import SwiftUI
import UniformTypeIdentifiers

/// Define the  **ChordPro** document
struct ChordProDocument: FileDocument {
    /// The UTType of the song
    static var readableContentTypes: [UTType] { [.chordProSong] }
    /// The file extensions **ChordPro** can open
    static let fileExtension: [String] = ["chordpro", "cho", "crd", "chopro", "chord", "pro"]
    /// The document text for a new song
    static let newText: String = "{title: New Song}\n"
    /// A warning for a line in the source; defined as a directive
    static let warningDirective = Directive(
        directive: "Warning",
        group: .metadata,
        icon: "exclamationmark.triangle",
        editable: false,
        help: "A warning is found"
    )
    /// The text of the song
    var text: String
    /// Init the song
    init(text: String = ChordProDocument.newText) {
        self.text = text
    }
    /// Init the configuration
    init(configuration: ReadConfiguration) throws {
        guard
            let data = configuration.file.regularFileContents,
            let text = String(data: data, encoding: .utf8)
        else {
            throw AppError.readDocumentError
        }
        /// Replace any Windows line endings
        self.text = text.replacingOccurrences(of: "\r\n", with: "\n")
    }
    /// Save the song
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = text.data(using: .utf8) else {
            throw AppError.writeDocumentError
        }
        return .init(regularFileWithContents: data)
    }
}

extension ChordProDocument {

    static func getSongTemplateContent(settings: AppSettings) -> String {
        if
            settings.application.useCustomSongTemplate,
            let persistentURL = UserFileBookmark.getBookmarkURL(UserFileItem.customSongTemplate) {
            /// Get access to the URL
            _ = persistentURL.startAccessingSecurityScopedResource()
            let data = try? String(contentsOf: persistentURL, encoding: .utf8)
            /// Stop access to the URL
            persistentURL.stopAccessingSecurityScopedResource()
            return data ?? ChordProDocument.newText
        } else {
            return ChordProDocument.newText
        }
    }
}

/// The `FocusedValueKey` for the current document
struct DocumentFocusedValueKey: FocusedValueKey {
    /// The `typealias` for the key
    typealias Value = FileDocumentConfiguration<ChordProDocument>
}

extension FocusedValues {
    /// The value of the document key
    var document: DocumentFocusedValueKey.Value? {
        get {
            self[DocumentFocusedValueKey.self]
        }
        set {
            self[DocumentFocusedValueKey.self] = newValue
        }
    }
}
