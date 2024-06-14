//
//  AppState.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 27/05/2024.
//

import Foundation

/// The observable state of the application
/// - Note: Every open song window shares this state
final class AppState: ObservableObject {
    /// All the settings for the application
    @Published var settings: AppSettings {
        didSet {
            try? AppSettings.save(settings: settings)
        }
    }
    /// Init the class; get application settings
    init() {
        self.settings = AppSettings.load()
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
        if settings.transcode {
            arguments.append("--transcode=\(settings.transcodeNotation)")
        }
        /// Add the optional transpose value
        if settings.transpose, let transpose = settings.transposeValue {
            arguments.append("--transpose=\(transpose)")
        }
        /// Optional show only the lyrics
        if settings.lyricsOnly {
            arguments.append("--lyrics-only")
        }
        /// Optional suppress all chords
        if settings.noChordGrids {
            arguments.append("--no-chord-grids")
        }
        /// Optional eliminate capo settings by transposing the song
        if settings.deCapo {
            arguments.append("--decapo")
        }
        /// Optional not use default configurations
        if settings.noDefaultConfigs {
            arguments.append("--nodefaultconfigs")
        }
        /// Optional add debug info to the PDF
        if settings.debug {
            arguments.append("--debug")
        }
        /// Return the basic settings
        return arguments
    }
}
