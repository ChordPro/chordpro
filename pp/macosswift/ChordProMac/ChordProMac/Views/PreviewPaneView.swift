//
//  PreviewPaneView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 05/07/2024.
//

import SwiftUI

/// SwiftUI `View` with the preview pane
struct PreviewPaneView: View {
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneState
    /// The document in the environment
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
    /// Optional annotations in the PDF
    @State private var annotations: [(userName: String, contents: String)] = []
    /// The body of the `View`
    var body: some View {
        if let data = sceneState.preview.data {
            Divider()
            AppKitUtils.PDFKitRepresentedView(data: data, annotations: $annotations)
                .overlay(alignment: .top) {
                    if sceneState.preview.outdated {
                        PreviewPDFButtonView.UpdatePreview()
                    }
                }
                .overlay(alignment: .bottom) {
                    if appState.settings.chordPro.debug, !annotations.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                Text("Debug:")
                                    .font(.headline)
                                ForEach(annotations, id: \.userName) { annotation in
                                    DebugInfoView(annotation: annotation)
                                }
                            }
                            .padding()
                        }
                        .background(Color(nsColor: .textBackgroundColor.withAlphaComponent(0.9)))
                        .border(.secondary)
                        .padding()
                    }
                }
                .onChange(of: document?.document.text) { _ in
                    sceneState.preview.outdated = true
                }
        }
    }
}

extension PreviewPaneView {

    /// Show buttons with debug-popovers
    struct DebugInfoView: View {
        /// The annotation from the PDF
        let annotation: (userName: String, contents: String)
        /// Bool to show a popover with details
        @State private var showPopover: Bool = false
        /// The body of the `View`
        var body: some View {
            Button(action: {
                showPopover = true

            }, label: {
                Text(annotation.userName)
            })
            .popover(isPresented: $showPopover) {
                ScrollView {
                    Text(annotation.contents)
                        .padding()
                }
                .frame(maxWidth: 600)
            }
        }
    }
}
