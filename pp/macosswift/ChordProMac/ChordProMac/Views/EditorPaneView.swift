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
    @EnvironmentObject private var appState: AppStateModel
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneStateModel
    /// The observable state of the document
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
    /// The body of the `View`
    var body: some View {
        if sceneState.showEditor, let document {
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
            /// - Note: Make sure we have an up-to-date list of directives
            .id(appState.directives.map(\.directive))
        }
    }
}
