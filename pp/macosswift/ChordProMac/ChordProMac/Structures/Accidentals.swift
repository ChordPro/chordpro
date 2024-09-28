//
//  Accidentals.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 28/05/2024.
//

import Foundation

/// The accidentals for transposing a song
enum Accidentals: String, CaseIterable, Codable {
    /// Default
    case defaults = "Default"
    /// Sharps
    case sharps = "Sharps"
    /// Flats
    case flats = "Flats"
}
