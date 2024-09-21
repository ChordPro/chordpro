//
//  ExportLogButton.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 02/06/2024.
//

import SwiftUI
import OSLog

/// SwiftUI `View` for an export log button
struct ExportLogButton: View {
    /// The label for the button
    let label: String
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneStateModel
    /// Present an export dialog
    @State private var exportLogDialog = false
    /// The log as String
    @State private var log: String?
    /// The body of the `View`
    var body: some View {
        Button(
            action: {
                    Task {
                        do {
                            log = try String(contentsOf: sceneState.logFileURL, encoding: .utf8)
                            exportLogDialog = true
                        } catch {
                            /// Show an error
                            sceneState.alertError = error
                        }
                    }
            },
            label: {
                Text(label)
            }
        )
        .fileExporter(
            isPresented: $exportLogDialog,
            document: LogDocument(log: log),
            contentType: .plainText,
            defaultFilename: "ChordPro Log Export"
        ) { _ in
            Logger.pdfBuild.notice("Export log completed")
        }
    }
}
