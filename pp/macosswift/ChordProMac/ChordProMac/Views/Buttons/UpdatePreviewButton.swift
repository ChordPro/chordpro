//
//  UpdatePreviewButton.swift
//  ChordProMac
//

import SwiftUI

/// Update the preview of the current document
struct UpdatePreviewButton: View {
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneStateModel
    /// The observable state of the document
    @Binding var document: ChordProDocument
    /// Bool if **ChordPro** is running in the shell
    @State private var isRunning: Bool = false
    /// The body of the `View`
    var body: some View {
        Button {
            Task {
                isRunning = true
                await PreviewPaneView.showPreview(document: document, sceneState: sceneState)
                isRunning = false
            }
        } label: {
            Text("Update Preview")
        }
        .disabled(isRunning)
        .padding(8)
        .background(Color(nsColor: .textColor).opacity(0.04).cornerRadius(10))
        .background(
            Color(nsColor: .textBackgroundColor)
                .cornerRadius(10)
                .shadow(
                    color: .secondary.opacity(0.1),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
        .padding()
        ProgressView()
            .opacity(isRunning ? 1 : 0)
    }
}
