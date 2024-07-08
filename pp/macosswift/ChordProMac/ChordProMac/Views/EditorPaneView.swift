//
//  EditorPaneView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 05/07/2024.
//

import SwiftUI

/// SwiftUI `View` with the editor
struct EditorPaneView: View {
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneState
    /// The document in the environment
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
    /// The body of the `View`
    var body: some View {
        if let document {
            ChordProEditor(
                text: document.$document.text,
                settings: appState.settings.editor,
                directives: appState.directives
            )
            .introspect { editor in
                Task { @MainActor in
                    sceneState.editorInternals = editor
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}
