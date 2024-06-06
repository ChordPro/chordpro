//
//  StatusView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 28/05/2024.
//

import SwiftUI

/// SwiftUI `View` wit the status of the scene
struct StatusView: View {
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneState
    /// The body of the `View`
    var body: some View {
        HStack {
            Text("**Configuration:** \(appState.settings.configLabel)")
            if appState.settings.transpose {
                // swiftlint:disable:next line_length
                Text("**Transpose:** from \(appState.settings.transposeFrom.rawValue) to \(appState.settings.transposeTo.rawValue)")
            }
            if appState.settings.transcode {
                Text("**Transcode:** \(appState.settings.transcodeNotation)")
            }
            Spacer()
            HStack {
                Text(sceneState.exportStatus.recoverySuggestion ?? "")
                    .font(.caption)
                /// - Note: Just show it with the accent color because the PDF *is* created.
                    .foregroundColor(.accentColor)
                Button("View Log") {
                    sceneState.showLog = true
                }
            }
            /// - Note: Just hide the log-stuff like this to get a nice animation
            .opacity(sceneState.exportStatus == .noErrorOccurred ? 0 : 1)
        }
        .font(.callout)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
        .animation(.default, value: appState.settings)
        .animation(.default, value: sceneState.exportStatus)
    }
}
