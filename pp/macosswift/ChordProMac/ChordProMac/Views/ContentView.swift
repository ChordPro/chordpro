//
//  ContentView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI

/// SwiftUI `View` for the main content
struct ContentView: View {
    /// Binding to the current document
    @Binding var document: ChordProDocument
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The body of the `View`
    var body: some View {
        VStack {
            TextEditor(text: $document.text)
                .font(.system(size: appState.settings.fontSize, weight: .regular, design: .monospaced))
                .padding([.top, .horizontal])
            StatusView()
                .padding([.horizontal])
        }
        .toolbar {
            ExportSongView(label: "Export")
            QuickLookView()
        }
    }
}
