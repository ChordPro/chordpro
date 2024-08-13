//
//  PreviewPDFView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI

/// SwiftUI `View` for a PDF preview
struct PreviewPDFButtonView: View {
    /// The label for the button
    let label: String
    /// Bool if we have to replace the current preview
    var replacePreview: Bool = false
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneState
    /// The document in the environment
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
    /// The body of the `View`
    var body: some View {
        Button(
            action: {
                if sceneState.preview.data == nil || replacePreview {
                    showPreview()
                } else {
                    sceneState.preview.data = nil
                }
            },
            label: {
                Label(label, systemImage: sceneState.preview.data == nil ? "eye" : "eye.fill")
            }
        )
        .help("Preview the PDF")
        .task(id: sceneState.customTask) {
            if sceneState.customTask != nil {
                /// Show a preview with the task
                showPreview()
            }
        }
        .onChange(of: appState.settings.chordPro) { _ in
            if sceneState.preview.data != nil {
                /// Show a preview with the new settings
                showPreview()
            }
        }
    }
    /// Show a preview of the PDF
    @MainActor func showPreview() {
        if let document {
            Task {
                do {
                    let pdf = try await Terminal.exportDocument(
                        text: document.document.text,
                        settings: appState.settings,
                        sceneState: sceneState
                    )
                    /// Set the status
                    sceneState.exportStatus = pdf.status
                    /// The preview is not outdated
                    sceneState.preview.outdated = false
                    /// Show the preview
                    sceneState.preview.data = pdf.data
                } catch {
                    /// Show an `Alert`
                    sceneState.alertError = error
                    /// Set the status
                    sceneState.exportStatus = .pdfCreationError
                }
                /// Remove the task (if any)
                sceneState.customTask = nil
            }
        }
    }
}

extension PreviewPDFButtonView {

    /// Update the preview of the current document
    struct UpdatePreview: View {
        /// The body of the `View`
        var body: some View {
            PreviewPDFButtonView(
                label: "Update Preview",
                replacePreview: true
            )
            .labelStyle(.titleOnly)
            .padding(8)
            .background(Color(nsColor: .textColor).opacity(0.04).cornerRadius(10))
            .background(
                Color(nsColor: .textBackgroundColor)
                    .cornerRadius(10)
                    .shadow(
                        color: .secondary.opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
            .padding()
        }
    }
}
