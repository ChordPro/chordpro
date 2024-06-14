//
//  SceneState.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import Foundation

/// The observable state of the scene
/// - Note: Every open song window has its own `SceneState` class
final class SceneState: ObservableObject {
    /// An error that can happen
    @Published var alertError: Error?
    /// Bool if we want to show the log
    @Published var showLog: Bool = false
    /// Status of the last **ChordPro** export
    @Published var exportStatus: AppError = .noErrorOccurred
    /// The unique ID of the scene
    let sceneID: String
    /// The URL of the source file
    let sourceURL: URL
    /// The URL of the export file
    let exportURL: URL
    /// The URL of the log file
    let logFileURL: URL
    /// The optional custom task to run
    @Published var customTask: CustomTask?
    /// The optional URL for the QuickView
    @Published var quickLookURL: URL?
    /// The random ID of the preview
    @Published var quickLookID = UUID()
    /// Bool if the quick look is outdated
    @Published var quickLookOutdated: Bool = false
    /// Init the class
    init() {
        /// Give it an unique ID
        sceneID = UUID().uuidString
        /// Create URLs
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        /// Create a source URL
        sourceURL = temporaryDirectoryURL.appendingPathComponent(sceneID, conformingTo: .chordProSong)
        /// Create an export URL
        exportURL = temporaryDirectoryURL.appendingPathComponent(sceneID, conformingTo: .pdf)
        /// Create a log URL
        logFileURL = temporaryDirectoryURL.appendingPathComponent(sceneID, conformingTo: .plainText)
    }
}
