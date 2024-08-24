//
//  ExportSongView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI
import OSLog

/// SwiftUI `View` for an export button
/// - Note: This button is also in the App Menu to it needs focused values for the document and the scene
struct ExportSongView: View {
    /// The label for the button
    let label: String
    /// The document in the environment
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The scene in the environment
    @FocusedValue(\.sceneState) private var sceneState: SceneState?
    /// Present an export dialog
    @State private var exportSongDialog = false
    /// The song as PDF
    @State private var pdf: Data?
    /// The body of the `View`
    var body: some View {
        Button(
            action: {
                if let document, let sceneState {
                    Task {
                        do {
                            /// Create the PDF with **ChordPro**
                            let pdf = try await Terminal.exportDocument(
                                text: document.document.text,
                                settings: appState.settings,
                                sceneState: sceneState
                            )
                            /// Set the PDF as Data
                            self.pdf = pdf.data
                            /// Show the export dialog
                            exportSongDialog = true
                            /// The PDF is not outdated
                            sceneState.preview.outdated = false
                            /// Set the status
                            sceneState.exportStatus = pdf.status
                        } catch {
                            /// Show an error
                            sceneState.alertError = error
                            /// Set the status
                            sceneState.exportStatus = .pdfCreationError
                        }
                    }
                }
            },
            label: {
                Label(label, systemImage: "square.and.arrow.up.on.square")
            }
        )
        /// Disable the button when there is no document window in focus and no scene state available
        .disabled(document == nil || sceneState == nil)
        .fileExporter(
            isPresented: $exportSongDialog,
            document: ExportDocument(pdf: pdf),
            contentType: .pdf,
            // swiftlint:disable:next line_length
            defaultFilename: document?.fileURL?.deletingPathExtension().lastPathComponent ?? sceneState?.songFileName ??  "Export"
        ) { _ in
            Logger.pdfBuild.notice("Export completed")
        }
    }
}
