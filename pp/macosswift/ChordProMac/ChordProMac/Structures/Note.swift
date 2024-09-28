//
//  Note.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 28/05/2024.
//

import Foundation

/// All musical notes
enum Note: String, CaseIterable, Codable {

    // swiftlint:disable identifier_name

    /// C
    case c = "C"
    /// C sharp
    case cSharp = "C#"
    /// D
    case d = "D"
    /// D sharp
    case dSharp = "D#"
    /// D flat
    case dFlat = "Db"
    /// E
    case e = "E"
    /// E flat
    case eFlat = "Eb"
    /// F
    case f = "F"
    /// F sharp
    case fSharp = "F#"
    /// G
    case g = "G"
    /// G sharp
    case gSharp = "G#"
    /// G flat
    case gFlat = "Gb"
    /// A
    case a = "A"
    /// A sharp
    case aSharp = "A#"
    /// A flat
    case aFlat = "Ab"
    /// B
    case b = "B"
    /// B flat
    case bFlat = "Bb"
    // swiftlint:enable identifier_name

    /// The note to value dictionary
    static var noteValueDict: [Note: Int] {
        [
            Note.c: 0,
            Note.cSharp: 1,
            Note.dFlat: 1,
            Note.d: 2,
            Note.dSharp: 3,
            Note.eFlat: 3,
            Note.e: 4,
            Note.f: 5,
            Note.fSharp: 6,
            Note.gFlat: 6,
            Note.g: 7,
            Note.gSharp: 8,
            Note.aFlat: 8,
            Note.a: 9,
            Note.aSharp: 10,
            Note.bFlat: 10,
            Note.b: 11
        ]
    }
}
