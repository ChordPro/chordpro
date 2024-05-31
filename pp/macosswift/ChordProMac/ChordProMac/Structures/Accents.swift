//
//  Accents.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 28/05/2024.
//

import Foundation

/// The accent of a note
public enum Accents: String, CaseIterable, Codable {

    /// Default
    case defaults = "Default"
    /// Sharps
    case sharps = "Sharps"
    /// Flats
    case flats = "Flats"
}
