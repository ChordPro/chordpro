//
//  SceneStateModel.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI

/// The observable state of the scene
/// - Note: Every open song window has its own `SceneStateModel` class
final class SceneStateModel: ObservableObject {
    /// The optional file location
    var file: URL?
    /// The default name for a new song
    var defaultSongName: String
    /// An error that can happen
    @Published var alertError: Error?
    /// Bool if we want to show the log
    @Published var showLog: Bool = false
    /// Status of the last **ChordPro** export
    @Published var exportStatus: AppError = .noErrorOccurred
    /// The temporary directory URL for processing files
    /// - Note: In its own directory so easier to debug
    let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        .appendingPathComponent("ChordProTMP", isDirectory: true)
    /// The calculated file name of the song
    var songFileName: String {
        if let file {
            return file.deletingPathExtension().lastPathComponent
        } else {
            return defaultSongName
        }
    }
    /// The URL of the source file
    var sourceURL: URL {
        return temporaryDirectoryURL.appendingPathComponent(songFileName, conformingTo: .chordProSong)
    }
    /// The URL of the export file
    var exportURL: URL {
        temporaryDirectoryURL.appendingPathComponent(songFileName, conformingTo: .pdf)
    }
    /// The URL of the log file
    var logFileURL: URL {
        temporaryDirectoryURL.appendingPathComponent(songFileName, conformingTo: .plainText)
    }
    /// The URL of the file list with songs
    var fileListURL: URL {
        temporaryDirectoryURL.appendingPathComponent("filelist", conformingTo: .plainText)
    }
    /// The optional local configuration (a config with the same base-name next to a song)
    var localConfigURL: URL? {
        if let file {
            let localConfig = file.deletingPathExtension().appendingPathExtension("json")
            let haveConfig = FileManager.default.fileExists(atPath: localConfig.path)
            return haveConfig ? localConfig : nil
        }
        return nil
    }
    /// The optional custom task to run
    @Published var customTask: CustomTask?
    /// Preview variables
    @Published var preview = PreviewState()
    /// The internals of the **ChordPro** editor
    @Published var editorInternals = ChordProEditor.Internals()
    /// Bool to show the editor
    @Published var showEditor: Bool = false
    /// Bool to show the preview
    @Published var showPreview: Bool = false
    /// Init the class
    init() {
        self.defaultSongName = "New Song \(Date().formatted(date: .abbreviated, time: .standard))"
        try? FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true)
    }
}

extension SceneStateModel {

    /// Export a document or folder with the **ChordPro** binary to a PDF
    /// - Parameters:
    ///   - text: The current text of the document
    ///   - replace: Bool if the PDF should be replaced with a fresh version
    ///   - fileList: Bool if the PDF should contain a file list instead of a single song
    ///   - title: The title of the export (for a songbook)
    ///   - subtitle: The subtitle of the export (for a songbook)
    /// - Returns: The PDF as `Data` and the status as ``AppError``
    @MainActor func exportToPDF(
        text: String,
        replace: Bool = false,
        fileList: Bool = false,
        title: String = "",
        subtitle: String = ""
    ) async throws -> (data: Data, status: AppError) {
        /// If the preview is open than that is what we are going to return
        if let data = preview.data, !replace {
            return (data, exportStatus)
        } else {
            do {
                let pdf = try await Terminal.exportPDF(
                    text: text,
                    settings: AppSettings.load(),
                    sceneState: self,
                    fileList: fileList,
                    title: title,
                    subtitle: subtitle
                )
                if !fileList {
                    /// The PDF is not outdated
                    preview.outdated = false
                    /// Update the preview if open
                    if preview.active {
                        preview.data = pdf.data
                    }
                }
                /// Set the status
                exportStatus = pdf.status
                /// Remove the task (if any)
                customTask = nil
                /// Return the PDF data and its status
                return pdf
            } catch {
                /// Show an error
                alertError = error
                /// Set the status
                exportStatus = .pdfCreationError
                /// Remove the task (if any)
                customTask = nil
                /// Open the editor
                showEditor = true
                /// Hide the preview
                showPreview = false
                /// Trow the error
                throw error
            }
        }
    }
}

/// The `FocusedValueKey` for the current scene
struct SceneFocusedValueKey: FocusedValueKey {
    /// The `typealias` for the key
    typealias Value = SceneStateModel
}

extension FocusedValues {
    /// The value of the scene key
    var sceneState: SceneFocusedValueKey.Value? {
        get {
            self[SceneFocusedValueKey.self]
        }
        set {
            self[SceneFocusedValueKey.self] = newValue
        }
    }
}
