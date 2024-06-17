//
//  FontSizeButtonsView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 17/06/2024.
//

import SwiftUI

/// SwiftUI `View` for buttons to resize the editor font
/// - Note: This can't be in the main menu; macOS Monterey can't handle dynamic buttons
struct FontSizeButtonsView: View {
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The range of font sizes
    private let fontSizeRange = AppSettings.Application.fontSizeRange
    /// The body of the `View`
    var body: some View {
        Group {
            Button {
                appState.settings.application.fontSize -= 1
            } label: {
                Label("Smaller", systemImage: "textformat.size.smaller")
            }
            .keyboardShortcut("-")
            .disabled(appState.settings.application.fontSize == fontSizeRange.lowerBound)
            Button {
                appState.settings.application.fontSize += 1
            } label: {
                Label("Bigger", systemImage: "textformat.size.larger")
            }
            .keyboardShortcut("+")
            .disabled(appState.settings.application.fontSize == fontSizeRange.upperBound)
        }
        .labelStyle(.titleAndIcon)
    }
}
