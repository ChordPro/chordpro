//
//  AboutView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 13/06/2024.
//

import SwiftUI

/// SwiftUI `View` with **About** information
struct AboutView: View {
    /// Bool to show the sheet with additional info
    @State private var showMoreInfo: Bool = false
    /// The **ChordPro** information
    @State private var chordProInfo: ChordProInfo?
    /// The body of the `View`
    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSImage(named: "AppIcon")!)
                .resizable()
                .frame(width: 80, height: 80)
            Text("ChordPro")
                .font(.system(size: 20, weight: .bold))
            Text("ChordPro \(chordProInfo?.general.chordpro.version ?? "…")")
            Text(chordProInfo?.general.chordpro.aux ?? "…")
                .font(.caption)
            Text("The reference implementation of the **ChordPro** format")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("More Info…") {
                Task {
                    /// Update the info because settings might have changed
                    chordProInfo = await getInfo()
                    showMoreInfo = true
                }
            }
            .disabled(chordProInfo == nil)
            Text("Copyright 2016,2024 Johan Vromans\n<jvromans@squirrel.nl>")
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(minWidth: 280, minHeight: 330)
        .sheet(isPresented: $showMoreInfo) {
            if let chordProInfo {
                MoreInfoView(chordProInfo: chordProInfo, showMoreInfo: $showMoreInfo)
            }
        }
        .animation(.default, value: chordProInfo)
        .task {
            chordProInfo = await getInfo()
        }
    }

    /// Get the **ChordPro** information
    /// - Returns: The information as ``ChordProInfo``
    private func getInfo() async -> ChordProInfo? {
        return try? await Terminal.getChordProInfo()
    }
}

extension AboutView {

    /// SwiftUI `View` with additional information
    struct MoreInfoView: View {
        let chordProInfo: ChordProInfo
        @Binding var showMoreInfo: Bool
        var body: some View {
            VStack {
                Text("ChordPro \(chordProInfo.general.chordpro.version)")
                    .font(.title)
                Text(chordProInfo.general.chordpro.aux)
                    .font(.caption)
                ScrollView {
                    VStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Perl")
                                    .bold()
                                Text(chordProInfo.general.perl.version)
                            }
                            Text("ABC Support")
                                .bold()
                            Text(chordProInfo.general.abc)
                            Text("Resource Path")
                                .bold()
                            ForEach(chordProInfo.resources, id: \.self) { resource in
                                HStack {
                                    Text(resource.path)
                                }
                            }
                        }
                        .wrapInfoSection(title: "General")
                        VStack(alignment: .leading) {
                            if let library = chordProInfo.general.library.first {
                                Text(library.path)
                            } else {
                                Text("You have not selected a Custom Library")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .wrapInfoSection(title: "Custom Library")
                    }
                    VStack(alignment: .leading) {
                        ForEach(chordProInfo.modules, id: \.self) { module in
                            HStack {
                                Text(module.name)
                                Text("・")
                                Text("Version \(module.version)")
                            }
                        }
                    }
                    .wrapInfoSection(title: "Perl Modules")
                    .padding(.bottom)
                }
                .border(Color.accentColor)
                Button {
                    showMoreInfo = false
                } label: {
                    Text("Close")
                }
            }
            .padding()
            .frame(width: 500, height: 400)
        }
    }
}

// MARK: Helpers

extension AboutView {

    struct WrapInfoSection: ViewModifier {
        let title: String
        func body(content: Content) -> some View {
            HStack(alignment: .top) {
                Text(title)
                    .padding(.top)
                    .font(.headline)
                    .frame(width: 100, alignment: .trailing)
                VStack {
                    content
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.primary.opacity(0.04).cornerRadius(8))
            }
            .padding([.top, .horizontal])
            .frame(maxWidth: .infinity)
        }
    }
}

extension View {

    func wrapInfoSection(title: String) -> some View {
        modifier(AboutView.WrapInfoSection(title: title))
    }
}