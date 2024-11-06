//
//  UserFileItem.swift
//  ChordProMac
//

import Foundation
import UniformTypeIdentifiers

/// All files that can be chosen in the ``SettingsView`` to override **ChordPro** defaults
enum UserFileItem: String, UserFile {

    /// A custom configuration
    case customConfig
    /// A custom library
    case customLibrary
    /// A custom song template
    case customSongTemplate
    /// An export folder
    case exportFolder
    /// A songbook cover
    case songbookCover
    /// A songbook list
    case songbookList
    /// The ID of the file item
    var id: String {
        return self.rawValue
    }
    /// The `UTType` of the file
    /// - Note: Used to restrict the selection in the ``UserFileButton``
    var utTypes: [UTType] {
        switch self {
        case .customConfig:
            return [UTType.json]
        case .customLibrary:
            return [UTType.folder]
        case .customSongTemplate:
            return [UTType.chordProSong]
        case .exportFolder:
            return [UTType.folder]
        case .songbookCover:
            return [UTType.pdf]
        case .songbookList:
            return [UTType.plainText]
        }
    }
    /// The optional calculated label of the file
    /// - Note: Used in the buttons of the ``SettingsView``
    var label: String? {
        return UserFileBookmark.getBookmarkURL(self)?.deletingPathExtension().lastPathComponent
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
        case .exportFolder:
            return "square.and.arrow.up"
        case .songbookCover:
            return "doc.richtext"
        case .songbookList:
            return "music.note.list"
        }
    }
    /// Protocol requirement; not supported with macOS 12
    var message: String {
        switch self {
        case .customConfig:
            return "Select your custom configuration"
        case .customLibrary:
            return "Select the folder with your custom library"
        case .customSongTemplate:
            return "Select your custom template"
        case .exportFolder:
            return "Select a folder with your songs"
        case .songbookCover:
            return "Select a PDF as cover for the songbook"
        case .songbookList:
            return "Select a file with your list of songs"
        }
    }
}
