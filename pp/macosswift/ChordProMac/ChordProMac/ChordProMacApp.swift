//
//  ChordProMacApp.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI

/// SwiftUI `Scene` for **ChordProMac**
@main struct ChordProMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    /// The observable state of the application
    @StateObject private var appState = AppState()
    /// The body of the `Scene`
    var body: some Scene {
        DocumentGroup(newDocument: ChordProDocument()) { file in
            ContentView(file: file.fileURL)
                .frame(minWidth: 680, minHeight: 480)
                .environmentObject(appState)
            /// Give the scene access to the document.
                .focusedSceneValue(\.document, file)
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button("About ChordPro") {
                    appDelegate.showAboutWindow()
                }
            }
#if DEBUG
            CommandGroup(after: .appInfo) {
                Divider()
                ResetApplicationButtonView()
            }
#endif
            CommandGroup(after: .importExport) {
                ExportSongView(label: "Export as PDF…")
                    .environmentObject(appState)
                Divider()
                PrintPDFView(label: "Print…")
                    .environmentObject(appState)
            }
            CommandMenu("Tasks") {
                TaskMenuView()
            }
            CommandGroup(replacing: .help) {
                HelpButtonsView()
                    .environmentObject(appState)
            }
        }
        Settings {
            SettingsView()
                .frame(width: 300, height: 440)
                .environmentObject(appState)
        }
    }
}

/// SwiftUI `View` with a `Button` to reset the application
public struct ResetApplicationButtonView: View {
    /// Init the `View`
    public init() {}
    /// The body of the `View`
    public var body: some View {
        Button(
            action: {
                /// Remove user defaults
                if let bundleID = Bundle.main.bundleIdentifier {
                    UserDefaults.standard.removePersistentDomain(forName: bundleID)
                }
                /// Delete the cache
                let manager = FileManager.default
                if let cacheFolderURL = manager.urls(
                    for: .cachesDirectory,
                    in: .userDomainMask
                ).first {
                    try? manager.removeItem(at: cacheFolderURL)
                    try? manager.createDirectory(
                        at: cacheFolderURL,
                        withIntermediateDirectories: false,
                        attributes: nil
                    )
                }
                /// Terminate the application
                NSApp.terminate(nil)
            },
            label: {
                Text("Reset Application")
            }
        )
    }
}
