//
//  Accidentals.swift
//  ChordProMac
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
