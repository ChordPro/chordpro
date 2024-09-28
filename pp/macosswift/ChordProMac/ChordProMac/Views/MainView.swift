//
//  MainView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI
import OSLog

/// SwiftUI `View` for the main content
struct MainView: View {
    /// The optional file location
    let file: URL?
    /// The observable state of the application
    @EnvironmentObject private var appState: AppStateModel
    /// The observable state of the scene
    @StateObject private var sceneState = SceneStateModel()
    /// The observable state of the document
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
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
        .animation(.default, value: sceneState.showEditor)
        .animation(.default, value: sceneState.showPreview)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    if sceneState.showEditor {
                        FontSizeButtons()
                            .labelStyle(.iconOnly)
                    }
                    Button {
                        sceneState.showEditor.toggle()
                    } label: {
                        Label("Edit", systemImage: sceneState.showEditor ? "pencil.circle.fill" : "pencil.circle")
                    }
                    .disabled(!sceneState.showPreview)
                    PreviewPDFButton(label: "Preview")
                    ExportSongButton(label: "Export as PDF")
                    ShareButton()
                        .labelStyle(.iconOnly)
                }
            }
        }
        .labelStyle(.titleAndIcon)
        /// Set the default panes
        .task {
            if file == nil {
                sceneState.showEditor = true
                sceneState.showPreview = false
            } else {
                switch appState.settings.application.openSongAction {
                case .editorAndPreview:
                    sceneState.showEditor = true
                    sceneState.showPreview = true
                case .editorOnly:
                    sceneState.showEditor = true
                    sceneState.showPreview = false
                case .previewOnly:
                    sceneState.showEditor = false
                    sceneState.showPreview = true
                }
                /// Create the preview unless we show only the editor
                if appState.settings.application.openSongAction != .editorOnly {
                    do {
                        let pdf = try await sceneState.exportToPDF(text: document?.document.text ?? "error")
                        /// Show the preview
                        sceneState.preview.data = pdf.data
                        sceneState.showPreview = true
                    } catch {
                        /// Hide the preview and show the editor; something went wrong
                        sceneState.showEditor = true
                        sceneState.showPreview = false
                    }
                }
            }
        }
        .task(id: file) {
            sceneState.file = file
        }
        .environmentObject(sceneState)
        /// Give the application access to the scene.
        .focusedSceneValue(\.sceneState, sceneState)
        /// Make sure all directives are up-to-date
        .task {
            appState.chordProInfo = try? await Terminal.getChordProInfo()
            appState.directives = Directive.getChordProDirectives(chordProInfo: appState.chordProInfo)
        }
    }
}
