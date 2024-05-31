//
//  AppSettings.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 27/05/2024.
//

import Foundation

struct AppSettings: Codable, Equatable {
    /// The font size of the editor
    var fontSize: Double = 14
    /// The template to use
    var template: String = "guitar"

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
    /// The transpose accents
    var transposeAccents: Accents = .defaults
    /// The calculated optional transpose value
    var transposeValue: Int? {
        guard
            let from = Note.noteValueDict[transposeFrom],
            let to = Note.noteValueDict[transposeTo]
        else {
            return nil
        }
        var transpose: Int = to - from
        transpose += transpose < 0 ? 12 : 0
        switch transposeAccents {
        case .defaults:
            break
        case .sharps:
            transpose += 12
        case .flats:
            transpose -= 12
        }
        return transpose == 0 ? nil : transpose
    }
}

extension AppSettings {

    /// Load the application settings
    /// - Returns: The ``ChordProMacSettings``
    static func load() -> AppSettings {
        if let settings = try? Cache.get(key: "ChordProMacSettings", as: AppSettings.self) {
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
