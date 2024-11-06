//
//  WelcomeView.swift
//  ChordProMac
//

import SwiftUI
import OSLog

/// SwiftUI `View` for a welcome window
struct WelcomeView: View {
    /// The observable state of the application
    @StateObject private var appState = AppStateModel.shared
    /// The AppDelegate to bring additional Windows into the SwiftUI world
    let appDelegate: AppDelegateModel
    /// The selected tab
    @State private var selectedTab: NewTabs = .create
    /// The ID of the Window
    let windowID: AppDelegateModel.WindowID
    /// The body of the `View`
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                Text("ChordPro")
                    .font(.title)
                    .bold()
                Image("ChordProLogo")
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
            .padding()
            .padding(.bottom)
            .frame(maxHeight: .infinity)
            .frame(width: 260)
            .background(.ultraThickMaterial)
            VStack(spacing: 0) {
                Picker("Tabs", selection: $selectedTab) {
                    ForEach(NewTabs.allCases) { tab in
                        Text(tab.rawValue)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.bottom)
                VStack(spacing: 0) {
                    switch selectedTab {
                    case .create:
                        Button(
                            action: {
                                /// Make sure the new text is different from the default or else the welcome view will show again
                                appState.newDocumentContent = appState.standardDocumentContent + "\n"
                                NSDocumentController.shared.newDocument(nil)
                            },
                            label: {
                                Label("Create a New Song", systemImage: "doc")
                            }
                        )
                        Button(
                            action: {
                                Task {
                                    if let urls = await NSDocumentController.shared.beginOpenPanel() {
                                        for url in urls {
                                            do {
                                                try await NSDocumentController.shared.openDocument(withContentsOf: url, display: true)
                                            } catch {
                                                Logger.application.error("Error opening URL: \(error.localizedDescription, privacy: .public)")
                                            }
                                        }
                                    }
                                }
                            },
                            label: {
                                Label("Open an Existing Song", systemImage: "doc.badge.ellipsis")
                            }
                        )
                        Button(
                            action: {
                                appDelegate.closeWelcomeWindow()
                                appDelegate.showExportSongbookWindow()
                            },
                            label: {
                                Label("Create a Songbook", systemImage: "doc.on.doc")
                            }
                        )
                        Button(
                            action: {
                                if let sampleSong = Bundle.main.url(forResource: "lib/ChordPro/res/examples/swinglow.cho", withExtension: nil) {
                                    let content = try? String(contentsOf: sampleSong, encoding: .utf8)
                                    appState.newDocumentContent = content ?? ChordProDocument.newText
                                    NSDocumentController.shared.newDocument(nil)
                                }
                            },
                            label: {
                                Label("Open an Example Song", systemImage: "doc.text")
                            }
                        )
                        Divider()
                            .frame(width: 240)
                            .padding([.horizontal, .bottom])
                        if let url = URL(string: "https://www.chordpro.org/") {
                            Link(destination: url) {
                                Label("Visit the **ChordPro** Site", systemImage: "globe")
                            }
                        }
                        if let url = URL(string: "https://www.chordpro.org/chordpro") {
                            Link(destination: url) {
                                Label("Read the Documentation", systemImage: "book")
                            }
                        }
                    case .recent:
                        if appState.recentFiles.isEmpty {
                            Text("You have no recent songs")
                                .frame(maxHeight: .infinity)
                        } else {
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(appState.recentFiles, id: \.self) { url in
                                        Button(
                                            action: {
                                                Task {
                                                    do {
                                                        try await NSDocumentController.shared.openDocument(withContentsOf: url, display: true)
                                                    } catch {
                                                        Logger.application.error("Error opening URL: \(error.localizedDescription, privacy: .public)")
                                                    }
                                                }
                                            },
                                            label: {
                                                Label(url.deletingPathExtension().lastPathComponent, systemImage: "doc.text")
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                if windowID == .welcomeView {
                    Toggle("Show this window when creating a new document", isOn: $appState.settings.application.showWelcomeWindow)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .controlSize(.small)
                        .padding(.bottom, 6)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .textBackgroundColor))
        }
        .animation(.default, value: selectedTab)
        .labelStyle(ButtonLabelStyle())
        .buttonStyle(.plain)
        .frame(width: 580)
    }
}

extension WelcomeView {
    enum NewTabs: String, CaseIterable, Identifiable {
        var id: String {
            self.rawValue
        }
        case create = "Create"
        case recent = "Recent"
    }
}

extension WelcomeView {

    /// The style of a label on the Welcome View
    struct ButtonLabelStyle: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack {
                configuration.icon
                    .foregroundColor(.secondary)
                    .imageScale(.large)
                configuration.title
                    .padding(.trailing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 40, alignment: .leading)
            }
            .padding(.leading)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            .cornerRadius(6)
            .padding(.bottom)
        }
    }
}
