//
//  LogView.swift
//  ChordProMac
//

import SwiftUI
import OSLog

/// SwiftUI `View to show the latest log`
struct LogView: View {
    /// The observable state of the application
    @EnvironmentObject private var appState: AppStateModel
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneStateModel
    /// The body of the `View`
    var body: some View {
        ScrollView {
            ScrollViewReader { value in
                VStack(spacing: 0) {
                    ForEach(sceneState.logMessages) { log in
                        HStack(alignment: .top) {
                            Image(systemName: "exclamationmark.bubble")
                                .foregroundStyle(log.type.color)
                            Text(log.time.formatted(.dateTime))
                            Text(":")
                            if let lineNumber = log.lineNumber {
                                Text("**Line \(lineNumber):**")
                            }
                            Text(.init(log.message))
                        }
                        .padding(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    /// Just use this as anchor point to keep the scrollview at the bottom
                    Divider()
                        .opacity(0)
                        .id(1)
                        .task {
                            value.scrollTo(1)
                        }
                        .onChange(of: sceneState.logMessages) { _ in
                            value.scrollTo(1)
                        }
                }
            }
        }
        .font(.monospaced(.body)())
        .background(Color(nsColor: .textBackgroundColor))
        .border(Color.secondary.opacity(0.5))
        .contextMenu {
            LogButtons(buttons: [.clear, .export], exportLabel: "Save the Messages to a File")
        }
        .padding(6)
    }
}
