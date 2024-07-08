//
//  ShareButtonView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 01/07/2024.
//

import SwiftUI

/// SwiftUI `View` with the 'share' button'
struct ShareButtonView: View {
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneState
    /// The document in the environment
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
    /// Bool to show the share picker
    @State private var showSharePicker: Bool = false
    /// The export URL
    @State private var exportURL: URL?
    /// The body of the `View`
    var body: some View {
        Button(
            action: {
                if let document {
                    Task {
                        do {
                            _ = try await Terminal.exportDocument(
                                text: document.document.text,
                                settings: appState.settings,
                                sceneState: sceneState
                            )
                            exportURL = sceneState.exportURL
                            showSharePicker = true
                        } catch {
                            /// Show an `Alert`
                            sceneState.alertError = error
                        }
                    }
                }
            },
            label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        )
        .help("Share the PDF")
        .background(
            AppKitUtils.SharingServiceRepresentedView(
                isPresented: $showSharePicker,
                url: $exportURL
            )
        )
    }
}
