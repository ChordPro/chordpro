//
//  FontSizeButtons.swift
//  ChordProMac
//

import SwiftUI

/// SwiftUI `View` with buttons to resize the editor font
/// - Note: This can't be in the main menu; macOS Monterey can't handle dynamic buttons
struct FontSizeButtons: View {
    /// The observable state of the application
    @EnvironmentObject private var appState: AppStateModel
    /// The range of font sizes
    private let fontSizeRange = ChordProEditor.Settings.fontSizeRange
    /// The body of the `View`
    var body: some View {
        HStack {
            Button {
                appState.settings.editor.fontSize -= 1
            } label: {
                Label("Smaller", systemImage: "textformat.size.smaller")
            }
            .keyboardShortcut("-")
            .disabled(appState.settings.editor.fontSize == fontSizeRange.lowerBound)
            Button {
                appState.settings.editor.fontSize += 1
            } label: {
                Label("Bigger", systemImage: "textformat.size.larger")
            }
            .keyboardShortcut("+")
            .disabled(appState.settings.editor.fontSize == fontSizeRange.upperBound)
        }
    }
}
