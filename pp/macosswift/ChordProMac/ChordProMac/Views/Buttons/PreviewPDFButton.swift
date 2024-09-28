//
//  PreviewPDFButton.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI
import OSLog

/// SwiftUI `View` with a button for a PDF preview
struct PreviewPDFButton: View {
    /// The label for the button
    let label: String
    /// Bool if we have to replace the current preview
    var replacePreview: Bool = false
    /// The observable state of the application
    @EnvironmentObject private var appState: AppStateModel
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneStateModel
    /// The observable state of the document
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
    /// The body of the `View`
    var body: some View {
        Button(
            action: {
                if sceneState.preview.data == nil || replacePreview {
                    showPreview()
                } else {
                    sceneState.showPreview = false
                    sceneState.preview.data = nil
                }
            },
            label: {
                Label(label, systemImage: sceneState.showPreview ? "eye.fill" : "eye")
            }
        )
        .help("Preview the PDF")
        .disabled(!sceneState.showEditor)
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
                    let pdf = try await sceneState.exportToPDF(text: document.document.text, replace: true)
                    /// Show the preview
                    sceneState.preview.data = pdf.data
                    sceneState.showPreview = true
                } catch {
                    Logger.pdfBuild.error("\(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }
}

extension PreviewPDFButton {

    /// Update the preview of the current document
    struct UpdatePreview: View {
        /// The body of the `View`
        var body: some View {
            PreviewPDFButton(
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
