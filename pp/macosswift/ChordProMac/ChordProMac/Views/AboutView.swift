//
//  AboutView.swift
//  ChordProMac
//

import SwiftUI

/// SwiftUI `View` with **About** information
@MainActor struct AboutView: View {
    /// The AppDelegate to bring additional Windows into the SwiftUI world
    let appDelegate: AppDelegateModel
    /// The observable state of the application
    @StateObject private var appState = AppStateModel.shared
    /// The body of the `View`
    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSImage(named: "AppIcon")!)
                .resizable()
                .frame(width: 140, height: 140)
            Text("ChordPro")
                .font(.title)
                .bold()
            Text("Version \(appState.chordProInfo?.general.chordpro.version ?? "…")")
            Text(appState.chordProInfo?.general.chordpro.aux ?? "…")
                .font(.caption)
            Text("The reference implementation of the [ChordPro](https://www.chordpro.org) format")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("Copyright 2016,2024 Johan Vromans\n<jvromans@squirrel.nl>")
                .font(.caption)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: true, vertical: true)
        }
        .padding()
        .frame(minWidth: 240)
        .background(.ultraThickMaterial)
        .closeWindowModifier {
            appDelegate.closeAboutWindow()
        }
    }
}
