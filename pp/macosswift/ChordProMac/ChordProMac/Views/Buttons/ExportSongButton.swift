//
//  ExportSongButton.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI
import OSLog

/// SwiftUI `View` for an export song button
/// - Note: This button is also in the App Menu to it needs focused values for the document and the scene
struct ExportSongButton: View {
    /// The label for the button
    let label: String
    /// The observable state of the document
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
    /// The observable state of the application
    @EnvironmentObject private var appState: AppStateModel
    /// The observable state of the scene
    @FocusedValue(\.sceneState) private var sceneState: SceneStateModel?
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
                            let pdf = try await sceneState.exportToPDF(text: document.document.text)
                            /// Set the PDF as Data
                            self.pdf = pdf.data
                            /// Show the export dialog
                            exportSongDialog = true
                        } catch {
                            Logger.pdfBuild.error("\(error.localizedDescription, privacy: .public)")
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
