//
//  UTType+extension.swift
//  ChordProMac
//

import Foundation
import UniformTypeIdentifiers

extension UTType {

    // MARK: The `UTType` for a `ChordPro` song

    /// The `UTType` for a ChordPro song
    static let chordProSong =
    UTType(importedAs: "org.chordpro")
}
