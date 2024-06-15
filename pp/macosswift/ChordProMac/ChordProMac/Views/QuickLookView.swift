//
//  QuickLookView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI
import QuickLook
import Quartz

/// SwiftUI `View` for a quick look button
struct QuickLookView: View {
    /// The label for the button
    let label: String
    /// The current document
    let document: ChordProDocument
    /// Bool if we have to replace the current preview
    var replacePreview: Bool = false
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneState
    /// The body of the `View`
    var body: some View {
        Button(
            action: {
                if sceneState.quickLookURL == nil || replacePreview {
                    showQuickView()
                } else {
                    sceneState.quickLookURL = nil
                }
            },
            label: {
                Label(label, systemImage: sceneState.quickLookURL == nil ? "eye" : "eye.fill")
            }
        )
        .task(id: sceneState.customTask) {
            if sceneState.customTask != nil {
                /// Show a Quick View of the task
                showQuickView()
            }
        }
        .onChange(of: appState.settings.chordPro) { _ in
            if sceneState.quickLookURL != nil {
                /// Show a Quick View with the new settings
                showQuickView()
            }
        }
    }
    /// Show a Quick View of the PDF
    @MainActor func showQuickView() {
        Task {
            do {
                sceneState.quickLookURL = replacePreview ? sceneState.quickLookURL : nil
                let pdf = try await Terminal.exportDocument(
                    text: document.text,
                    settings: appState.settings,
                    sceneState: sceneState
                )
                /// Set the status
                sceneState.exportStatus = pdf.status
                /// It is not outdated
                sceneState.quickLookOutdated = false
                /// Show the Quick Look
                sceneState.quickLookURL = sceneState.exportURL
                /// Give the Quick Look a new ID
                sceneState.quickLookID = UUID()
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

extension QuickLookView {

    /// Create a preview of the current document
    struct Preview: NSViewRepresentable {
        var url: URL
        func makeNSView(context: NSViewRepresentableContext<Preview>) -> QLPreviewView {
            let preview = QLPreviewView(frame: .zero, style: .normal)
            preview?.autostarts = true
            preview?.previewItem = url as QLPreviewItem

            return preview ?? QLPreviewView()
        }

        func updateNSView(_ nsView: QLPreviewView, context: NSViewRepresentableContext<Preview>) {
            nsView.previewItem = url as QLPreviewItem
        }
        // swiftlint:disable:next nesting
        typealias NSViewType = QLPreviewView
    }
}

extension QuickLookView {

    /// Update the preview of the current document
    struct UpdatePreview: View {
        /// The current document
        let document: ChordProDocument
        @Environment(\.colorScheme) var colorScheme
        var body: some View {
                QuickLookView(label: "Update Preview", document: document, replacePreview: true)
                    .labelStyle(.titleOnly)
            .padding(8)
            .background(Color(nsColor: .textColor).opacity(0.04).cornerRadius(10))
            .background(
                Color(nsColor: .textBackgroundColor)
                    .cornerRadius(10)
                    .shadow(
                        color: .secondary
                            .opacity(0.1),
                        radius: 8, x: 0, y: 2)
            )
            .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
            .padding()
        }
    }

}
