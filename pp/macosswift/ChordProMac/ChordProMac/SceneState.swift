//
//  SceneState.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI

/// The observable state of the scene
/// - Note: Every open song window has its own `SceneState` class
final class SceneState: ObservableObject {
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
    /// The temporary directory for processing files
    let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
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
    /// The optional custom task to run
    @Published var customTask: CustomTask?
    /// Preview variables
    @Published var preview = PreviewState()
    /// The internals of the **ChordPro** editor
    @Published var editorInternals = ChordProEditor.Internals()
    /// Init the class
    init() {
        self.defaultSongName = "New Song \(Date().formatted(date: .abbreviated, time: .standard))"
    }
}

/// The `FocusedValueKey` for the current scene
struct SceneFocusedValueKey: FocusedValueKey {
    /// The `typealias` for the key
    typealias Value = SceneState
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
