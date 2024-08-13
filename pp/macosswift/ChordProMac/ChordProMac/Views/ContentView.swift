//
//  ContentView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI

/// SwiftUI `View` for the main content
struct ContentView: View {
    /// The optional file location
    let file: URL?
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The observable state of the scene
    @StateObject private var sceneState = SceneState()
    /// The body of the `View`
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                EditorPaneView()
                PreviewPaneView()
            }
            StatusView()
                .padding(.horizontal)
        }
        .animation(.default, value: sceneState.preview)
        .errorAlert(error: $sceneState.alertError, log: $sceneState.showLog)
        .toolbar {
            FontSizeButtonsView()
            ExportSongView(label: "Export as PDF")
            Group {
                PreviewPDFButtonView(label: "Show Preview")
                ShareButtonView()
            }
            .labelStyle(.iconOnly)
        }
        .labelStyle(.titleAndIcon)
        .sheet(isPresented: $sceneState.showLog) {
            LogView()
        }
        /// Store the filename in the scene
        .task(id: file) {
            sceneState.file = file
        }
        .environmentObject(sceneState)
        /// Give the application access to the scene.
        .focusedSceneValue(\.sceneState, sceneState)
    }
}
