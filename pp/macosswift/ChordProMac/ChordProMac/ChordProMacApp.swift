//
//  ChordProMacApp.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI

/// SwiftUI `Scene` for **ChordProMac**
@main struct ChordProMacApp: App {
    /// The observable state of the application
    @StateObject private var appState = AppState()
    /// The body of the `Scene`
    var body: some Scene {
        DocumentGroup(newDocument: ChordProDocument()) { file in
            ContentView(document: file.$document)
                /// Below does not seem to work... I think it is because of the editor...
                .frame(
                    minWidth: 400,
                    idealWidth: 400,
                    maxWidth: .infinity,
                    minHeight: 400,
                    idealHeight: 600,
                    maxHeight: .infinity
                )
                .environmentObject(appState)
            /// Give the scene access to the document.
                .focusedSceneValue(\.document, file)
        }
        .commands {
            CommandGroup(after: .importExport) {
                ExportSongView(label: "Export as PDF…")
                    .environmentObject(appState)
            }
            CommandMenu("Tasks") {
                TaskMenuView()
            }
            CommandGroup(replacing: .help) {
                HelpButtonsView()
            }
        }
        Settings {
            SettingsView()
                .frame(width: 300, height: 420)
                .environmentObject(appState)
        }
    }
}
