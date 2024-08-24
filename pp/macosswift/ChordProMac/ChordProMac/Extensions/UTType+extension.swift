//
//  UTType+extension.swift
//  Chord Provider
//
//  © 2024 Nick Berendsen
//

import Foundation
import UniformTypeIdentifiers

public extension UTType {

    // MARK: The `UTType` for a `ChordPro` song

    /// The `UTType` for a ChordPro song
    static let chordProSong =
    UTType(importedAs: "org.chordpro")
}
