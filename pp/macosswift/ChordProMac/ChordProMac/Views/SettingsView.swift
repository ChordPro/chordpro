//
//  SettingsView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 27/05/2024.
//

import SwiftUI
import UniformTypeIdentifiers
import OSLog
import AudioToolbox

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
            presets
                .tabItem {
                    Label("Presets", systemImage: "doc.plaintext")
                }
            library
                .tabItem {
                    Label("Library", systemImage: "building.columns")
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
                        /// It is a template; check if it is enabled
                        let name = item.deletingPathExtension().lastPathComponent
                        let enabled = appState.settings.chordPro.systemConfigs.first(where: {$0.fileName == name})
                        templates.append(Template(url: item, enabled: (enabled == nil) ? false : true))
                    }
                }
            }
            Logger.application.info("Found \(templates.count) system templates")
            self.systemConfigurations = templates.sorted { $0.label < $1.label }
            self.notations = notations
        }
    }
}

extension SettingsView {
    /// SwiftUI `View` with editor settings
    var editor: some View {
        ScrollView {
            VStack {
                Toggle("Use a custom template", isOn: $appState.settings.application.useCustomSongTemplate)
                FileButtonView(
                    bookmark: CustomFile.customSongTemplate
                ) {}
                    .disabled(!appState.settings.application.useCustomSongTemplate)
                Text("You can use your own **ChordPro** file as a starting point when you create a new song")
                    .font(.caption)
            }
            .wrapSettingsSection(title: "Template for a New Song")
            VStack {
                HStack {
                    Text("A")
                        .font(.system(size: AppSettings.Application.fontSizeRange.lowerBound))
                    Slider(
                        value: $appState.settings.application.fontSize,
                        in: AppSettings.Application.fontSizeRange,
                        step: 1
                    )
                    /// Give it a random ID to avoid random crashes on macOS Monterey
                    .id(UUID())
                    Text("A")
                        .font(.system(size: AppSettings.Application.fontSizeRange.upperBound))
                }
                .foregroundColor(.secondary)
                /// Give it a random ID to avoid random crashes on macOS Monterey
                .id(UUID())
                Picker("The font style of the editor", selection: $appState.settings.application.fontStyle) {
                    ForEach(FontStyle.allCases, id: \.self) { font in
                        Text("\(font.rawValue)")
                            .font(font.font(size: appState.settings.application.fontSize))
                    }
                }
                /// Give it a random ID to avoid random crashes on macOS Monterey
                .id(UUID())
                .pickerStyle(.radioGroup)
                .labelsHidden()
                .padding()
            }
            .wrapSettingsSection(title: "Editor Font")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

extension SettingsView {
    /// SwiftUI `View` with presets settings
    var presets: some View {
        VStack {
            Text("Built-in configurations")
                .font(.subheadline)
                .bold()
            List {
                ForEach($systemConfigurations) { $template in
                    Toggle(isOn: $template.enabled) {
                        Text(template.label)
                    }
                }
                .onChange(of: systemConfigurations) { _ in
                    appState.settings.chordPro.systemConfigs = systemConfigurations.filter({$0.enabled == true})
                }
            }
            Toggle("Add a custom configuration", isOn: $appState.settings.chordPro.useCustomConfig)
            FileButtonView(
                bookmark: CustomFile.customConfig
            ) {}
            Toggle("Ignore default configurations", isOn: $appState.settings.chordPro.noDefaultConfigs)
            // swiftlint:disable:next line_length
            Text("This prevents **ChordPro** from using system wide, user specific and song specific configurations. Checking this will make sure that **ChordPro** only uses the configuration as set in the _application_.")
                .font(.caption)
        }
        .wrapSettingsSection(title: "Preset Configurations")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.bottom)
    }
}

extension SettingsView {
    /// SwiftUI `View` with presets settings
    var library: some View {
        VStack {
            Toggle("Add a custom library", isOn: $appState.settings.chordPro.useAdditionalLibrary)
            FileButtonView(
                bookmark: CustomFile.customLibrary
            ) {}
                .disabled(!appState.settings.chordPro.useAdditionalLibrary)
            // swiftlint:disable:next line_length
            Text("**ChordPro** has a built-in library with configs and other data. With *custom library* you can add an additional location where to look for data.")
                .font(.caption)
        }
        .wrapSettingsSection(title: "Custom Library")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

extension SettingsView {
    /// SwiftUI `View` with options settings
    var options: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Toggle("Show only lyrics", isOn: $appState.settings.chordPro.lyricsOnly)
                Text("This option will hide all chords, ABC and LilyPonds")
                    .font(.caption)
                Toggle("Suppress chord diagrams", isOn: $appState.settings.chordPro.noChordGrids)
                Text("This hide diagrams but still shows inline chords")
                    .font(.caption)
                Toggle("Eliminate capo settings", isOn: $appState.settings.chordPro.deCapo)
                Text("This will be done by transposing the song")
                    .font(.caption)
                Toggle(isOn: $appState.settings.chordPro.debug) {
                    Text("Enable Debug Info in the PDF")
                }
            }
            .wrapSettingsSection(title: "General")
            VStack {
                Toggle("Transpose the song", isOn: $appState.settings.chordPro.transpose)
                if appState.settings.chordPro.transpose {
                    VStack {
                        HStack {
                            Picker("From:", selection: $appState.settings.chordPro.transposeFrom) {
                                ForEach(Note.allCases, id: \.self) { note in
                                    Text(note.rawValue)
                                }
                            }
                            /// Give it a random ID to avoid random crashes on macOS Monterey
                            .id(UUID())
                            Picker("To:", selection: $appState.settings.chordPro.transposeTo) {
                                ForEach(Note.allCases, id: \.self) { note in
                                    Text(note.rawValue)
                                }
                            }
                            /// Give it a random ID to avoid random crashes on macOS Monterey
                            .id(UUID())
                        }
                        Picker("Accidentals:", selection: $appState.settings.chordPro.transposeAccidentals) {
                            ForEach(Accidentals.allCases, id: \.self) { accidental in
                                Text(accidental.rawValue)
                            }
                        }
                        /// Give it a random ID to avoid random crashes on macOS Monterey
                        .id(UUID())
                    }
                    .padding(.top)
                }
            }
            .wrapSettingsSection(title: "Transpose")
            VStack {
                Toggle("Transcode the notation", isOn: $appState.settings.chordPro.transcode)
                if appState.settings.chordPro.transcode {
                    Picker("Transcode to:", selection: $appState.settings.chordPro.transcodeNotation) {
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
            .wrapSettingsSection(title: "Transcode")
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

extension SettingsView {

    struct WrapSettingsSection: ViewModifier {
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

    /// Shortcut to the `WrapSettingsSection` modifier
    /// - Parameter title: The title
    /// - Returns: A modified `View`
    func wrapSettingsSection(title: String) -> some View {
        modifier(SettingsView.WrapSettingsSection(title: title))
    }
}
