//
//  HelpButtons.swift
//  ChordProMac
//

import SwiftUI

/// SwiftUI buttons for the main `help` menu
struct HelpButtons: View {
    /// The observable state of the application
    @EnvironmentObject private var appState: AppStateModel
    /// The observable state of the document
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
    /// The body of the `View`
    var body: some View {
        if let url = URL(string: "https://www.chordpro.org/chordpro/") {
            Link(destination: url) {
                Text("ChordPro File Format")
            }
        }
        if let url = URL(string: "https://groups.io/g/ChordPro") {
            Link(destination: url) {
                Text("ChordPro Community")
            }
        }
        if let sampleSong = Bundle.main.url(forResource: "lib/ChordPro/res/examples/swinglow.cho", withExtension: nil) {
            Divider()
            Button("Insert a Song Example") {
                if
                    let document,
                    let content = try? String(contentsOf: sampleSong, encoding: .utf8) {
                    document.document.text = content
                }
            }
            .disabled(document == nil)
        }
        if let url = URL(string: "https://chordpro.org/chordpro/trouble-shooting/") {
            Divider()
            Toggle(isOn: $appState.settings.chordPro.debug) {
                Text("Enable Debug Info in the PDF")
            }
            Link(destination: url) {
                Text("Trouble Shooting Help")
            }
            Divider()
        }
        if let url = URL(string: "https://github.com/ChordPro/chordpro") {
            Link(destination: url) {
                Text("ChordPro on GitHub")
            }
        }
    }
}
