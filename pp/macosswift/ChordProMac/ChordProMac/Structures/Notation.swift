//
//  Notation.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 28/05/2024.
//

import Foundation

/// A notation we found in the official **ChordPro** source
struct Notation: Identifiable {
    var id: URL {
        url
    }
    let url: URL
    var label: String {
        let label = self.url.deletingPathExtension()
        return label.lastPathComponent
    }
    var description: String {
        switch label {
        case "common":
            "C, D, E, F, G, A, B"
        case "dutch":
            "C, D, E, F, G, A, B"
        case "german":
            "C, ... A, Ais/B, H"
        case "latin":
            "Do, Re, Mi, Fa, Sol, ..."
        case "scandinavian":
            "C, ... A, A#/Bb, H"
        case "solfege":
            "Do, Re, Mi, Fa, So, ..."
        case "solfège":
            "Do, Re, Mi, Fa, So, ..."
        case "nashville":
            "1, 2, 3, ..."
        case "roman":
            "I, II, III, ..."
        default:
            "Unknown notation"
        }
    }
}
