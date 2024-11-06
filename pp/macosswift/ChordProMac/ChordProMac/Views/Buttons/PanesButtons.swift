//
//  PanesButtons.swift
//  ChordProMac
//

import SwiftUI
import OSLog

/// SwiftUI `View` with a button for a PDF preview
struct PanesButtons: View {
    /// Bool if we have to replace the current preview
    var replacePreview: Bool = false
    /// The observable state of the application
    @EnvironmentObject private var appState: AppStateModel
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneStateModel
    /// The observable state of the document
    @Binding var document: ChordProDocument
    /// The body of the `View`
    var body: some View {
        Picker("Options", selection: $sceneState.panes) {
            ForEach(SceneStateModel.Panes.allCases, id: \.self) { option in
                Text("\(option.rawValue)")
            }
        }
        .pickerStyle(.segmented)
        .task(id: sceneState.customTask) {
            if sceneState.customTask != nil {
                /// Clear the data
                sceneState.preview.data = nil
                /// Show a preview with the task
                await PreviewPaneView.showPreview(document: document, sceneState: sceneState)
            }
        }
        .onChange(of: appState.settings.chordPro) { _ in
            if sceneState.panes != .editorOnly {
                /// Show a preview with the new settings
                Task {
                    await PreviewPaneView.showPreview(document: document, sceneState: sceneState)
                }
            }
        }
        .onChange(of: sceneState.panes) { [oldValue = sceneState.panes] _ in
            /// Clear previous data
            if oldValue == .editorOnly {
                sceneState.preview.data = nil
                Task {
                    await PreviewPaneView.showPreview(document: document, sceneState: sceneState)
                }
            }
        }
    }
}
