//
//  PreviewPaneView.swift
//  ChordProMac
//

import SwiftUI
import OSLog

/// SwiftUI `View` with the preview pane
struct PreviewPaneView: View {
    /// The observable state of the application
    @EnvironmentObject private var appState: AppStateModel
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneStateModel
    /// The observable state of the document
    @Binding var document: ChordProDocument
    /// Optional annotations in the PDF
    @State private var annotations: [(userName: String, contents: String)] = []
    /// The body of the `View`
    var body: some View {
        if let data = sceneState.preview.data {
            AppKitUtils.PDFKitRepresentedView(data: data, annotations: $annotations)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .top) {
                    if sceneState.preview.outdated {
                        UpdatePreviewButton(document: $document)
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
                        .background(.ultraThinMaterial.opacity(0.8))
                    }
                }
                .onChange(of: document.text) { _ in
                    sceneState.preview.outdated = true
                }
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

extension PreviewPaneView {

    /// Show a PDF preview
    @MainActor static func showPreview(
        document: ChordProDocument?,
        sceneState: SceneStateModel
    ) async {
        if let document {
            do {
                let pdf = try await sceneState.exportToPDF(text: document.text, replace: true)
                /// Make sure the preview pane is open
                sceneState.panes = sceneState.panes.showPreview
                /// Show the preview
                sceneState.preview.data = pdf.data
            } catch {
                Logger.pdfBuild.error("\(error.localizedDescription, privacy: .public)")
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
                Text(annotation.userName.replacingOccurrences(of: "ChordPro", with: ""))
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
