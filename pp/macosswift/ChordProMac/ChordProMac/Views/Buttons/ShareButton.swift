//
//  ShareButton.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 01/07/2024.
//

import SwiftUI
import OSLog

/// SwiftUI `View` with the standard 'share' button'
struct ShareButton: View {
    /// The observable state of the application
    @EnvironmentObject private var appState: AppStateModel
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneStateModel
    /// The observable state of the document
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
                            _ = try await sceneState.exportToPDF(text: document.document.text)
                            exportURL = sceneState.exportURL
                            showSharePicker = true
                        } catch {
                            Logger.pdfBuild.error("\(error.localizedDescription, privacy: .public)")
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
