//
//  AppStateModel.swift
//  ChordProMac
//

import Foundation

/// The observable state of the application
/// - Note: Every open song window shares this state
final class AppStateModel: ObservableObject {
    /// The shared AppStateModel
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

extension AppStateModel {

    /// Export the log together with the runtimw info
    /// - Parameter messages: All the messages crteated by the **ChordPro** CLI
    /// - Returns: A formatted string
    func exportMessages(messages: [ChordProEditor.LogItem]) -> String {
        let log = messages.map { item -> String in
            return "\(item.time): \(item.message)"
        } .joined(separator: "\n")
        return log + runtimeInfo
    }

    /// The **ChordPro** runtime info
    var runtimeInfo: String {
        if let chordProInfo = chordProInfo {
            var text =
"""

-----------------------------------------------
ChordPro Preview Editor version \(chordProInfo.general.chordpro.version)
https://www.chordpro.org
Copyright 2016,2024 Johan Vromans <jvromans@squirrel.nl>

Mac GUI written in SwiftUI

**Run-time information:**
 ChordProCore:
    \(chordProInfo.general.chordpro.version) (\(chordProInfo.general.chordpro.aux))
  Perl:
    \(chordProInfo.general.abc) (\(chordProInfo.general.perl.path))
  Resource path:

"""
            for resource in chordProInfo.resources {
                text += "    \(resource.path)\n"
            }

            text +=
"""
  ABC support:
    \(chordProInfo.general.abc)

**Modules and libraries:**

"""
            for module in chordProInfo.modules {
                text += "    \(module.name)"
                text += String(repeating: " ", count: 22 - module.name.count)
                text += "\(module.version)\n"
            }
            text += "-----------------------------------------------"
            return text
        } else {
            /// This should not happen
            return "Runtime Information not available"
        }
    }
}
