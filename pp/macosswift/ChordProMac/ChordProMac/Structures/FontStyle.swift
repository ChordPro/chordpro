//
//  FontStyle.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 01/06/2024.
//

import SwiftUI

/// Font styles for the `EditorView`
enum FontStyle: String, CaseIterable, Codable {
    /// Use a monospaced font
    case monospaced = "Monospaced"
    /// Use a serif font
    case serif = "Serif"
    /// Use a sans-serif font
    case sansSerif = "Sans Serif"
    /// The calculated font for the `EditorView`
    func font(size: Double) -> Font {
        switch self {
        case .monospaced:
            return .system(size: size, weight: .regular, design: .monospaced)
        case .serif:
            return .system(size: size, weight: .regular, design: .serif)
        case .sansSerif:
            return .system(size: size, weight: .regular, design: .default)
        }
    }
}
