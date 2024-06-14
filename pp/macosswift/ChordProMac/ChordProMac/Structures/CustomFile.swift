//
//  CustomFile.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 01/06/2024.
//

import Foundation
import UniformTypeIdentifiers

/// All files that can be chosen in the ``SettingsView`` to override **ChordPro** defaults
enum CustomFile: String {
    /// A custom configuration
    case customConfig
    /// A custom library
    case customLibrary
    /// A custom song template
    case customSongTemplate
    /// The `UTType` of the file
    /// - Note: Used to restrict the selection in the ``FileButtonView``
    var utType: UTType {
        switch self {
        case .customConfig:
            return UTType.json
        case .customLibrary:
            return UTType.folder
        case .customSongTemplate:
            return UTType.chordProSong
        }
    }
    /// The optional calculated label of the file
    /// - Note: Used in the buttons of the ``SettingsView``
    var label: String? {
        return try? FileBookmark.getBookmarkURL(self)?.deletingPathExtension().lastPathComponent
    }
    /// The SF icon of the file
    /// - Note: Used in the buttons of the ``SettingsView``
    var icon: String {
        switch self {
        case .customConfig:
            return "gear"
        case .customLibrary:
            return "building.columns"
        case .customSongTemplate:
            return "music.note.list"
        }
    }
}
