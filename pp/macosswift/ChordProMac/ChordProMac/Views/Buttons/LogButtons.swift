//
//  LogButtons.swift
//  ChordProMac
//

import SwiftUI
import OSLog

/// SwiftUI `View` with log buttons
@MainActor struct LogButtons: View {
    /// The buttons to show
    let buttons: [ButtonType]
    /// The label for the export button
    var exportLabel: String = "Save Messages"
    /// The observable state of the application
    @EnvironmentObject private var appState: AppStateModel
    /// The observable state of the scene
    @FocusedValue(\.sceneState) private var sceneState: SceneStateModel?
    /// The body of the `View`
    var body: some View {
        Group {
            ForEach(buttons, id: \.self) { button in
                switch button {
                case .export:
                    export
                case .clear:
                    clear
                }
            }
        }
        .disabled(sceneState == nil)
    }
    var export: some View {
        Button(
            action: {
                /// Show the export dialog
                sceneState?.exportLogDialog = true
            },
            label: {
                Text(exportLabel)
            }
        )
    }
    var clear: some View {
        Button(
            action: {
                sceneState?.logMessages = [.init()]
            },
            label: {
                Text("Clear the Message Area")
            }
        )
    }
}

extension LogButtons {

    /// The button type for the log
    enum ButtonType {
        /// Export log button
        case export
        /// Clear log button
        case clear
    }
}
