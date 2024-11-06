//
//  MainView.swift
//  ChordProMac
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
    @Binding var document: ChordProDocument
    /// The body of the `View`
    var body: some View {
        VStack(spacing: 0) {
            panes
            StatusView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.default, value: sceneState.showLog)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    PanesButtons(document: $document)
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
                sceneState.panes = .editorOnly
            } else {
                /// Create the preview unless we show only the editor
                if appState.settings.application.openSongAction != .editorOnly {
                    sceneState.file = file
                    do {
                        let pdf = try await sceneState.exportToPDF(text: document.text)
                        /// Show the preview
                        sceneState.preview.data = pdf.data
                    } catch {
                        /// Something went wrong
                        Logger.pdfBuild.error("\(error.localizedDescription, privacy: .public)")
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
    /// The panes of the `View`
    @ViewBuilder var panes: some View {
        switch sceneState.panes {
        case .editorOnly:
            EditorPaneView(document: $document)
        case .editorAndPreview:
            HStack(spacing: 0) {
                EditorPaneView(document: $document)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                PreviewPaneView(document: $document)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        case .previewOnly:
            PreviewPaneView(document: $document)
        }
    }
}
