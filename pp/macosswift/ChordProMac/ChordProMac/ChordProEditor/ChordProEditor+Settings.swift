//
//  ChordProEditor+Settings.swift
//  ChordProMac
//

@preconcurrency import SwiftUI

extension ChordProEditor {

    // MARK: Settings for the editor

    /// Settings for the editor
    struct Settings: Equatable, Codable, Sendable {

        // MARK: Fonts

        /// The range of available font sizes
        static let fontSizeRange: ClosedRange<Double> = 10...24

        /// The size of the font
        var fontSize: Double = 14

        /// The font style of the editor
        var fontStyle: FontStyle = .monospaced

        /// The calculated font for the editor
        var font: NSFont {
            return fontStyle.nsFont(size: fontSize)
        }

        // MARK: Colors (codable with an extension)

        /// The color for brackets
        var bracketColor: Color = .gray
        /// The color for a chord
        var chordColor: Color = .red
        /// The color for a directive
        var directiveColor: Color = .indigo
        /// The color for a directive argument
        var argumentColor: Color = .orange
        /// The color for markup
        var markupColor: Color = .teal
        /// The color for comments
        var commentColor: Color = .gray
    }
}

extension ChordProEditor.Settings {

    /// The editor font-style
    enum FontStyle: String, CaseIterable, Codable, Sendable {
        /// Use a monospaced font
        case monospaced = "Monospaced"
        /// Use a serif font
        case serif = "Serif"
        /// Use a sans-serif font
        case sansSerif = "Sans Serif"
        /// The calculated font for the `EditorView`
        func nsFont(size: Double) -> NSFont {
            var descriptor: NSFontDescriptor?
            switch self {
            case .monospaced:
                descriptor = NSFont.systemFont(ofSize: size).fontDescriptor.addingAttributes().withDesign(.monospaced)
            case .serif:
                descriptor = NSFont.systemFont(ofSize: size).fontDescriptor.addingAttributes().withDesign(.serif)
            case .sansSerif:
                descriptor = NSFont.systemFont(ofSize: size).fontDescriptor.addingAttributes().withDesign(.default)
            }
            if let descriptor, let font = NSFont(descriptor: descriptor, size: size) {
                return font
            }
            return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        }
        /// The calculated font for the `SettingsView`
        func font() -> Font {
            switch self {
            case .monospaced:
                return .system(.body, design: .monospaced)
            case .serif:
                return .system(.body, design: .serif)
            case .sansSerif:
                return .system(.body, design: .default)
            }
        }
    }
}
