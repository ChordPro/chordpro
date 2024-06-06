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
    /// The observable state of the scene
    @StateObject private var sceneState = SceneState()
    /// The body of the `View`
    var body: some View {
        VStack {
            /// - Note: `TextEditor` is very (very) limited this is a compromise
            TextEditor(text: $document.text)
                .font(appState.settings.fontStyle.font(size: appState.settings.fontSize))
                .padding(4)
                .background(Color(nsColor: .textBackgroundColor))
            StatusView()
                .padding(.horizontal)
        }
        .quickLookPreview($sceneState.quickLookURL)
        .errorAlert(error: $sceneState.alertError, log: $sceneState.showLog)
        .toolbar {
            ExportSongView(label: "Export as PDF")
            QuickLookView(document: document)
        }
        .sheet(isPresented: $sceneState.showLog) {
            LogView()
        }
        .environmentObject(sceneState)
        /// Give the application access to the scene.
        .focusedSceneValue(\.sceneState, sceneState)
    }
}
