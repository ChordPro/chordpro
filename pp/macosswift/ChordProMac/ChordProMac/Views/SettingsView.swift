//
//  SettingsView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 27/05/2024.
//

import SwiftUI
import UniformTypeIdentifiers
import OSLog

/// SwiftUI `View` with the application settings
struct SettingsView: View {
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The configurations we found in the official **ChordPro** source
    @State var systemConfigurations: [Template] = []
    /// The notations we found in the official **ChordPro** source
    @State var notations: [Notation] = []
    /// The body of the `View`
    var body: some View {
        TabView {
            editor
                .tabItem {
                    Label("Editor", systemImage: "pencil")
                }
            templates
                .tabItem {
                    Label("Templates", systemImage: "doc.plaintext")
                }
            options
                .tabItem {
                    Label("Options", systemImage: "music.quarternote.3")
                }
        }
        .animation(.default, value: appState.settings)
        /// Get all system templates and notations
        .task {
            var templates: [Template] = []
            var notations: [Notation] = []
            guard
                let templateFolder = Bundle.main.url(forResource: "lib/ChordPro/res/config", withExtension: nil),
                let items = FileManager.default.enumerator(at: templateFolder, includingPropertiesForKeys: nil)
            else {
                return
            }
            while let item = items.nextObject() as? URL {
                /// Check if it is a JSON file
                if item.pathExtension == UTType.json.preferredFilenameExtension ?? ".json" {
                    if item.absoluteString.contains("notes") {
                        /// It is a notation
                        notations.append(Notation(url: item))
                    } else {
                        /// It is a template
                        templates.append(Template(url: item))
                    }
                }
            }
            Logger.application.info("Found \(templates.count) system templates")
            self.systemConfigurations = templates
            self.notations = notations
        }
    }
}

extension SettingsView {
    /// SwiftUI `View` with editor settings
    var editor: some View {
        ScrollView {
            VStack {
                Toggle("Use a custom template", isOn: $appState.settings.useCustomSongTemplate)
                FileButtonView(
                    bookmark: CustomFile.customSongTemplate
                ) {}
                .disabled(!appState.settings.useCustomSongTemplate)
                Text("You can use your own **ChordPro** file as a starting point when you create a new song")
                    .font(.caption)
            }
            .wrapSection(title: "Template for a New Song")
            VStack {
                Picker("Size of the font:", selection: $appState.settings.fontSize) {
                    ForEach(12...24, id: \.self) { value in
                        Text("\(value)px")
                            .tag(Double(value))
                    }
                }
                /// Give it a random ID to avoid random crashes on macOS Monterey
                .id(UUID())
                Picker("The font style of the editor", selection: $appState.settings.fontStyle) {
                    ForEach(FontStyle.allCases, id: \.self) { font in
                        Text("\(font.rawValue)")
                            .font(font.font(size: appState.settings.fontSize))
                    }
                }
                /// Give it a random ID to avoid random crashes on macOS Monterey
                .id(UUID())
                .pickerStyle(.radioGroup)
                .labelsHidden()
                .padding()
            }
            .wrapSection(title: "Editor Font")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

extension SettingsView {
    /// SwiftUI `View` with templates settings
    var templates: some View {
        ScrollView {
            VStack {
                Picker("Build-in:", selection: $appState.settings.systemConfig) {
                    ForEach(systemConfigurations) { template in
                        Text(template.label)
                            .tag(template.fileName)
                    }
                }
                .disabled(appState.settings.useCustomConfig)
                Toggle("Use a custom configuration", isOn: $appState.settings.useCustomConfig)
                FileButtonView(
                    bookmark: CustomFile.customConfig
                ) {
                    appState.settings.customConfig = try? FileBookmark.getBookmarkURL(CustomFile.customConfig)
                }
                .disabled(!appState.settings.useCustomConfig)
                Toggle("Ignore default configurations", isOn: $appState.settings.noDefaultConfigs)
                // swiftlint:disable:next line_length
                Text("This prevents **ChordPro** from using system wide, user specific and song specific configurations. Checking this will make sure that **ChordPro** only uses the configuration as set in the _application_.")
                    .font(.caption)
            }
            .wrapSection(title: "Configuration Template")
            VStack {
                Toggle("Add a custom library", isOn: $appState.settings.useAdditionalLibrary)
                FileButtonView(
                    bookmark: CustomFile.customLibrary
                ) {}
                    .disabled(!appState.settings.useAdditionalLibrary)
                // swiftlint:disable:next line_length
                Text("**ChordPro** has a built-in library with configs and other data. With *custom library* you can add an additional location where to look for data.")
                    .font(.caption)
            }
            .wrapSection(title: "Custom Library")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

extension SettingsView {
    /// SwiftUI `View` with options settings
    var options: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Toggle("Show only lyrics", isOn: $appState.settings.lyricsOnly)
                Text("This option will hide all chords, ABC and LilyPonds")
                    .font(.caption)
                Toggle("Suppress chord diagrams", isOn: $appState.settings.noChordGrids)
                Text("This hide diagrams but still shows inline chords")
                    .font(.caption)
                Toggle("Eliminate capo settings", isOn: $appState.settings.deCapo)
                Text("This will be done by transposing the song")
                    .font(.caption)
            }
            .wrapSection(title: "General")
            VStack {
                Toggle("Transpose the song", isOn: $appState.settings.transpose)
                if appState.settings.transpose {
                    VStack {
                        HStack {
                            Picker("From:", selection: $appState.settings.transposeFrom) {
                                ForEach(Note.allCases, id: \.self) { note in
                                    Text(note.rawValue)
                                }
                            }
                            /// Give it a random ID to avoid random crashes on macOS Monterey
                            .id(UUID())
                            Picker("To:", selection: $appState.settings.transposeTo) {
                                ForEach(Note.allCases, id: \.self) { note in
                                    Text(note.rawValue)
                                }
                            }
                            /// Give it a random ID to avoid random crashes on macOS Monterey
                            .id(UUID())
                        }
                        Picker("Accents:", selection: $appState.settings.transposeAccents) {
                            ForEach(Accents.allCases, id: \.self) { accents in
                                Text(accents.rawValue)
                            }
                        }
                        /// Give it a random ID to avoid random crashes on macOS Monterey
                        .id(UUID())
                    }
                    .padding(.top)
                }
            }
            .wrapSection(title: "Transpose")
            VStack {
                Toggle("Transcode the notation", isOn: $appState.settings.transcode)
                if appState.settings.transcode {
                    Picker("Transcode to:", selection: $appState.settings.transcodeNotation) {
                        ForEach(notations) { notation in
                            Text("\(notation.label.capitalized): \(notation.description)")
                                .tag(notation.label)
                        }
                    }
                    /// Give it a random ID to avoid random crashes on macOS Monterey
                    .id(UUID())
                    .padding(.top)
                }
            }
            .wrapSection(title: "Transcode")
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

extension SettingsView {

    struct WrapSection: ViewModifier {
        let title: String
        func body(content: Content) -> some View {
            VStack(alignment: .center) {
                Text(title)
                    .font(.headline)
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

    func wrapSection(title: String) -> some View {
        modifier(SettingsView.WrapSection(title: title))
    }
}
