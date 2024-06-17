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
            if !appState.settings.chordPro.configLabel.isEmpty {
                Text("**Configuration:** \(appState.settings.chordPro.configLabel)")
            }
            if appState.settings.chordPro.transpose && appState.settings.chordPro.transposeMakesSense {
                Text("**Transpose:** \(appState.settings.chordPro.transposeLabel)")
            }
            if appState.settings.chordPro.transcode {
                Text("**Transcode:** \(appState.settings.chordPro.transcodeNotation.capitalized)")
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
