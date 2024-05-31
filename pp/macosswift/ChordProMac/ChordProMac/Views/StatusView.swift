//
//  StatusView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 28/05/2024.
//

import SwiftUI

struct StatusView: View {
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The body of the `View`
    var body: some View {
        HStack {
            Text("**Template:** \(appState.settings.template)")
            if appState.settings.transpose {
                Text("**Transpose:** from \(appState.settings.transposeFrom.rawValue) to \(appState.settings.transposeTo.rawValue)")
            }
            if appState.settings.transcode {
                Text("**Transcode:** \(appState.settings.transcodeNotation)")
            }
        }
        .font(.callout)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
        .animation(.smooth, value: appState.settings)
    }
}
