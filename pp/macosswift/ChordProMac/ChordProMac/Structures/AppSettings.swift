//
//  AppSettings.swift
//  ChordProMac
//

import Foundation

/// All the settings for the application
struct AppSettings: Codable, Equatable {
    /// Settings that will change the behaviour of the application
    var application = Application()
    /// The options for the ``ChordProEditor``
    var editor: ChordProEditor.Settings = .init()
    /// Settings that will change the behaviour of the **ChordPro** binary
    var chordPro = ChordPro()
}

extension AppSettings {

    /// Load the application settings
    /// - Returns: The ``AppSettings``
    static func load() -> AppSettings {
        if let settings = try? Cache.get(key: "ChordProMacSettings", struct: AppSettings.self) {
            return settings
        }
        /// No settings found; return defaults
        return AppSettings()
    }

    /// Save the application settings to the cache
    /// - Parameter settings: The ``AppSettings``
    static func save(settings: AppSettings) throws {
        do {
            try Cache.set(key: "ChordProMacSettings", object: settings)
        } catch {
            throw AppError.saveSettingsError
        }
    }
}

extension AppSettings {

    /// Settings that will change the behaviour of the application
    struct Application: Codable, Equatable {

        /// Bool to show the Welcome window when creating a new document
        var showWelcomeWindow: Bool = true
        /// Action when opening an existing song
        var openSongAction: SceneStateModel.Panes = .editorAndPreview
        /// Bool to use a custom song template
        var useCustomSongTemplate: Bool = false

        // MARK: Songbook

        /// The title of the songbook
        var songbookTitle: String = "My Songs"
        /// The optional subtitle of the songbook
        var songbookSubtitle: String = "ChordPro"
        /// Bool to auto-generate a cover
        var songbookGenerateCover: Bool = true
        /// Bool to use a custom cover
        var songbookUseCustomCover: Bool = false
        /// Bool to look recursive into the songs folder
        var recursiveFileList: Bool = true
        /// The current filelist
        var fileList: [FileListItem] = []
    }

    /// Settings that will change the behaviour of the **ChordPro** binary
    struct ChordPro: Codable, Equatable {

        // MARK: Templates

        /// Bool to use an additional library
        var useAdditionalLibrary: Bool = false
        /// Bool to use a custom config instead of system
        var useCustomConfig: Bool = false
        /// The selected custom config
        var customConfigURL: URL?
        /// The system configs to use
        var systemConfigs: [Template] = []
        /// The label to show in the ``StatusView``
        var configLabel: String {
            var config = systemConfigs.map {$0.label.replacingOccurrences(of: "_", with: " ").capitalized}
            if useCustomConfig, let url = UserFileBookmark.getBookmarkURL(UserFileItem.customConfig) {
                config.append(url.deletingPathExtension().lastPathComponent)
            }
            return config.joined(separator: "・")
        }

        /// Bool not to use default configurations
        var noDefaultConfigs: Bool = false

        // MARK: Transpose

        /// Bool if the song should be transcoded
        var transcode: Bool = false
        /// The optional transcode to use
        var transcodeNotation: String = "common"

        // MARK: Transpose

        /// Bool if the song should be transposed
        var transpose: Bool = false
        /// The note to transpose from
        var transposeFrom: Note = .c
        /// The note to transpose to
        var transposeTo: Note = .c
        /// The transpose accidentals
        var transposeAccidentals: Accidentals = .defaults
        /// The calculated optional transpose value
        var transposeValue: Int? {
            guard
                let fromNote = Note.noteValueDict[transposeFrom],
                let toNote = Note.noteValueDict[transposeTo]
            else {
                return nil
            }
            var transpose: Int = toNote - fromNote
            transpose += transpose < 0 ? 12 : 0
            switch transposeAccidentals {
            case .defaults:
                break
            case .sharps:
                transpose += 12
            case .flats:
                transpose -= 12
            }
            return transpose == 0 || !transposeMakesSense ? nil : transpose
        }
        /// Check if the transpose settings makes sense
        /// - Note: If 'from' and 'to' are the same and the 'accidentals' is default, there is nothing to transpose
        var transposeMakesSense: Bool {
            return (transposeFrom != transposeTo) || transposeAccidentals != .defaults
        }
        var transposeLabel: String {
            var label: [String] = []
            if transposeFrom != transposeTo {
                label.append("from \(transposeFrom.rawValue) to \(transposeTo.rawValue)")
            }
            if transposeAccidentals != .defaults {
                label.append("with \(transposeAccidentals)")
            }
            return label.joined(separator: " ")
        }

        // MARK: Other

        /// Show only lyrics
        var lyricsOnly: Bool = false
        /// Suppress chord diagrams
        var noChordGrids: Bool = false
        /// Eliminate capo settings by transposing the song
        var deCapo: Bool = false
        /// Enable debug info in the PDF
        var debug: Bool = false
    }
}
