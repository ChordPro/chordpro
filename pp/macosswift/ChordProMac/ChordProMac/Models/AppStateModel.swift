//
//  AppStateModel.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 27/05/2024.
//

import Foundation
import OSLog

/// The observable state of the application
/// - Note: Every open song window shares this state
final class AppStateModel: ObservableObject {

    static let shared = AppStateModel()

    /// All the settings for the application
    @Published var settings: AppSettings {
        didSet {
            try? AppSettings.save(settings: settings)
        }
    }
    /// The standard content for a new document
    var standardDocumentContent: String
    /// The actual content for a new song
    /// - Note: This will be different thah the standard when opened from the ``WelcomeView``
    var newDocumentContent: String
    /// The **ChordPro** information
    @Published var chordProInfo: ChordProInfo?
    /// The list of known directives
    @Published var directives: [ChordProDirective] = []
    /// The list with recent files
    @Published var recentFiles: [URL] = []

    /// Init the class; get application settings
    private init() {
        /// Get the application settings from the cache
        let settings = AppSettings.load()
        self.settings = settings
        /// Set the content of a new song
        self.standardDocumentContent = ChordProDocument.getSongTemplateContent(settings: settings)
        self.newDocumentContent = self.standardDocumentContent
//        /// Set the Custom Content if selected
//        if settings.application.useCustomSongTemplate {
//            newDocumentContent = ChordProDocument.getSongTemplateContent()
//        }.a
        /// Get the **ChordPro** info
        Task { @MainActor in
            chordProInfo = try? await Terminal.getChordProInfo()
            directives = Directive.getChordProDirectives(chordProInfo: chordProInfo)
        }
    }
    /// Add the user settings as arguments to **ChordPro** for the Terminal action
    /// - Parameter settings: The ``AppSettings``
    /// - Returns: An array with arguments
    ///
    /// There are more settings but they need sandbox help...
    static func getUserSettings(settings: AppSettings) -> [String] {
        /// Start with an empty array
        var arguments: [String] = []
        /// Add the optional  transcode
        if settings.chordPro.transcode {
            arguments.append("--transcode=\(settings.chordPro.transcodeNotation)")
        }
        /// Add the optional transpose value
        if settings.chordPro.transpose, let transpose = settings.chordPro.transposeValue {
            arguments.append("--transpose=\(transpose)")
        }
        /// Optional show only the lyrics
        if settings.chordPro.lyricsOnly {
            arguments.append("--lyrics-only")
        }
        /// Optional suppress all chords
        if settings.chordPro.noChordGrids {
            arguments.append("--no-chord-grids")
        }
        /// Optional eliminate capo settings by transposing the song
        if settings.chordPro.deCapo {
            arguments.append("--decapo")
        }
        /// Optional not use default configurations
        if settings.chordPro.noDefaultConfigs {
            arguments.append("--nodefaultconfigs")
        }
        /// Optional add debug info to the PDF
        if settings.chordPro.debug {
            arguments.append("--debug")
        }
        /// Add selected built-in presets
        for preset in settings.chordPro.systemConfigs {
            arguments.append("--config=\(preset.fileName)")
        }
        /// Return the basic settings
        return arguments
    }
}
