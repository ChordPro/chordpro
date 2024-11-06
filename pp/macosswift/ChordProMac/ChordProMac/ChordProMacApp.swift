//
//  ChordProMacApp.swift
//  ChordProMac
//

import SwiftUI

/// SwiftUI `Scene` for **ChordProMac**
@main struct ChordProMacApp: App {
    /// The AppDelegate to bring additional Windows into the SwiftUI world
    @NSApplicationDelegateAdaptor(AppDelegateModel.self) var appDelegate
    /// The observable state of the application
    @StateObject private var appState = AppStateModel.shared
    /// The body of the `Scene`
    var body: some Scene {

        // MARK: Song Document View

        DocumentGroup(newDocument: ChordProDocument(text: appState.newDocumentContent)) { file in
            if file.fileURL == nil &&
                file.document.text == appState.standardDocumentContent &&
                appState.settings.application.showWelcomeWindow &&
                !(NSDocumentController.shared.currentDocument?.isDocumentEdited ?? false) {
                ProgressView()
                    .withHostingWindow { window in
                        window?.alphaValue = 0
                        window?.close()
                        appDelegate.showWelcomeWindow()
                    }
            } else {
                MainView(file: file.fileURL, document: file.$document)
                    .frame(minHeight: 680)
                    .environmentObject(appState)
                /// Give the scene access to the document
                    .focusedSceneValue(\.document, file)
                    .task {
                        appDelegate.closeWelcomeWindow()
                        /// Reset the new content
                        appState.newDocumentContent = appState.standardDocumentContent
                    }
            }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About ChordPro") {
                    appDelegate.showAboutWindow()
                }
            }
#if DEBUG
            CommandMenu("Debug") {
                DebugButtons()
            }
#endif
            CommandGroup(after: .importExport) {
                LogButtons(buttons: [.export], exportLabel: "Save Messages…")
                    .environmentObject(appState)
                Divider()
                ExportSongButton(label: "Export as PDF…")
                    .environmentObject(appState)
                Divider()
                PrintPDFButton(label: "Print…")
                    .environmentObject(appState)
            }
            CommandGroup(after: .textEditing) {
                LogButtons(buttons: [.clear])
            }
            CommandMenu("Songbook") {
                Button("Export Folder…") {
                    appDelegate.closeWelcomeWindow()
                    appDelegate.showExportSongbookWindow()
                }
            }
            CommandMenu("Tasks") {
                TaskMenuButtons()
            }
            CommandGroup(replacing: .help) {
                HelpButtons()
                    .environmentObject(appState)
            }
        }

        // MARK: Settings View

        Settings {
            SettingsView()
                .frame(width: 320, height: 440)
                .environmentObject(appState)
        }
    }
}
