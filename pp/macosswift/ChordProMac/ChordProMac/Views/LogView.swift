//
//  LogView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 01/06/2024.
//

import SwiftUI

/// SwiftUI `View to show the latest log`
struct LogView: View {
    /// The observable state of the application
    @EnvironmentObject private var appState: AppStateModel
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneStateModel
    /// Get the latest log
    var logItems: [LogItem] {
        do {
            let log = try String(contentsOf: sceneState.logFileURL, encoding: .utf8)
            /// Since the document is created in the temporarily directory, it has a very long path and name so strip it
            let strippedLog = log
                .replacingOccurrences(of: "\(sceneState.sourceURL.path)", with: "SONG")
                .components(separatedBy: .newlines)
            /// Return the log in its mapped ``LogItem`` array
            return strippedLog.map { strippedLog -> LogItem in
                LogItem(line: strippedLog)
            }
        } catch {
            /// There is no log (this should not happen)
            return [LogItem(line: "There is no log available")]
        }
    }
    /// The body of the `View`
    var body: some View {
        VStack {
            Text("Log")
                .font(.title)
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(logItems) { log in
                        /// Skip empty lines
                        if !log.line.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.bubble")
                                Divider()
                                Text(log.line)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
            }
            .border(Color.accentColor)
            HStack {
                /// - Note: We can't set a default button in SwiftUI for macOS 12 and want to keep the code simple
                ExportLogButton(label: "Save Log")
                Button("Close") {
                    sceneState.showLog = false
                }
            }
        }
        .frame(
            minWidth: 300,
            idealWidth: 400,
            maxWidth: 500,
            minHeight: 200,
            idealHeight: 300,
            maxHeight: 800
        )
        .padding()
    }
}
