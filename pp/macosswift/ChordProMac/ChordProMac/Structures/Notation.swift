//
//  Notation.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 28/05/2024.
//

import Foundation

/// A notation we found in the **ChordPro** source
struct Notation: Identifiable {
    /// The calculated ID of the notation
    var id: URL {
        url
    }
    /// The `URL` of the notation
    let url: URL
    /// The calculated label of the notation
    var label: String {
        let label = self.url.deletingPathExtension()
        return label.lastPathComponent
    }
    /// The description of the notation
    /// - Note: Hard-coded because we cannot get this from the source
    var description: String {
        switch label {
        case "common":
            return "C, D, E, F, G, A, B"
        case "dutch":
            return "C, D, E, F, G, A, B"
        case "german":
            return "C, ... A, Ais/B, H"
        case "latin":
            return "Do, Re, Mi, Fa, Sol, ..."
        case "scandinavian":
            return "C, ... A, A#/Bb, H"
        case "solfege":
            return "Do, Re, Mi, Fa, So, ..."
        case "solfège":
            return "Do, Re, Mi, Fa, So, ..."
        case "nashville":
            return "1, 2, 3, ..."
        case "roman":
            return "I, II, III, ..."
        default:
            return "Unknown notation"
        }
    }
}
