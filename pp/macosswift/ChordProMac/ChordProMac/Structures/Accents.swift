//
//  Accents.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 28/05/2024.
//

import Foundation

/// The accents for transposing a song
public enum Accents: String, CaseIterable, Codable {
    /// Default
    case defaults = "Default"
    /// Sharps
    case sharps = "Sharps"
    /// Flats
    case flats = "Flats"
}
