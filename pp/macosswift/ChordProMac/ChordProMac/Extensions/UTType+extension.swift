//
//  UTType+extension.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 02/06/2024.
//

import Foundation
import UniformTypeIdentifiers

extension UTType {

    // MARK: The `UTType` for a `ChordPro` song

    /// The `UTType` for a ChordPro song
    static let chordProSong =
    UTType(importedAs: "org.chordpro")
}
