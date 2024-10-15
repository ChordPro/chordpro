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
    @EnvironmentObject private var appState: AppStateModel
    /// The configurations we found in the official **ChordPro** source
    @State var systemConfigurations: [Template] = []
    /// The notations we found in the official **ChordPro** source
    @State var notations: [Notation] = []
    /// The body of the `View`
    var body: some View {
        TabView {
            general
                .tabItem {
                    Label("General", systemImage: "gear")
                }
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
            /// No need for ChordPro style, it's default.
            if let index = templates.firstIndex(where: {$0.label == "Chordpro"}) {
              templates.remove(at: index)
            }
            Logger.application.info("Found \(templates.count) system templates")
            self.systemConfigurations = templates.sorted { $0.label < $1.label }
            self.notations = notations
        }
    }
}

extension SettingsView {

    // MARK: General Settings

    /// SwiftUI `View` with general settings
    var general: some View {
        ScrollView {
            VStack {
                VStack(alignment: .leading) {
                    Toggle("Show the welcome screen when creating a new document", isOn: $appState.settings.application.showWelcomeWindow)
                    Text("When enabled you can choose between a new song, a new songbook or open an existing song. When disabled, a new song will be created.")
                        .font(.caption)
                    Toggle("Use a custom template for a new song", isOn: $appState.settings.application.useCustomSongTemplate)
                        .onChange(of: appState.settings.application.useCustomSongTemplate) { _ in
                            /// Update the appState with the new song content
                            appState.standardDocumentContent = ChordProDocument.getSongTemplateContent(settings: appState.settings)
                            appState.newDocumentContent = appState.standardDocumentContent
                        }
                }
                UserFileButton(
                    userFile: UserFileItem.customSongTemplate
                ) {
                    /// Update the appState with the new song content
                    appState.standardDocumentContent = ChordProDocument.getSongTemplateContent(settings: appState.settings)
                    appState.newDocumentContent = appState.standardDocumentContent
                }
                    .disabled(!appState.settings.application.useCustomSongTemplate)
                Text("You can use your own **ChordPro** file as a starting point when you create a new song")
                    .font(.caption)
            }
            .wrapSettingsSection(title: "Template for a New Song")
            VStack {
                Picker("Options", selection: $appState.settings.application.openSongAction) {
                    ForEach(AppSettings.PaneView.allCases, id: \.self) { option in
                        Text("\(option.rawValue)")
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
                Text("Set the default action when you open an existing song. You can always hide or show the editor and preview for each song.")
                    .font(.caption)
            }
            .wrapSettingsSection(title: "Open an Existing Song")

        }
    }
}

extension SettingsView {

    // MARK: Editor Settings

    /// SwiftUI `View` with editor settings
    var editor: some View {
        ScrollView {
            VStack {
                HStack {
                    Text("A")
                        .font(.system(size: ChordProEditor.Settings.fontSizeRange.lowerBound))
                    Slider(
                        value: $appState.settings.editor.fontSize,
                        in: ChordProEditor.Settings.fontSizeRange,
                        step: 1
                    )
                    Text("A")
                        .font(.system(size: ChordProEditor.Settings.fontSizeRange.upperBound))
                }
                .foregroundColor(.secondary)
                Picker("Font style", selection: $appState.settings.editor.fontStyle) {
                    ForEach(ChordProEditor.Settings.FontStyle.allCases, id: \.self) { font in
                        Text("\(font.rawValue)")
                            .font(font.font())
                    }
                }
                .labelsHidden()
                .frame(maxHeight: 20)
            }
            .wrapSettingsSection(title: "Editor Font")
            VStack {
                ColorPickerButton(
                    selectedColor: $appState.settings.editor.chordColor,
                    label: "Color for **chords**"
                )
                ColorPickerButton(
                    selectedColor: $appState.settings.editor.directiveColor,
                    label: "Color for **directives**"
                )
                ColorPickerButton(
                    selectedColor: $appState.settings.editor.argumentColor,
                    label: "Color for **arguments**"
                )
                ColorPickerButton(
                    selectedColor: $appState.settings.editor.markupColor,
                    label: "Color for **markup**"
                )
                ColorPickerButton(
                    selectedColor: $appState.settings.editor.bracketColor,
                    label: "Color for **brackets**"
                )
                ColorPickerButton(
                    selectedColor: $appState.settings.editor.commentColor,
                    label: "Color for **comments**"
                )
            }
            .wrapSettingsSection(title: "Highlight Colors")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.bottom)
    }
}

extension SettingsView {

    // MARK: Presets Settings

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
            UserFileButton(
                userFile: UserFileItem.customConfig
            ) {
                /// Trigger an update of the Views
                appState.settings.chordPro.useCustomConfig = true
            }
                .disabled(!appState.settings.chordPro.useCustomConfig)
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

    // MARK: Library Settings

    /// SwiftUI `View` with presets settings
    var library: some View {
        VStack {
            Toggle("Add a custom library", isOn: $appState.settings.chordPro.useAdditionalLibrary)
            UserFileButton(
                userFile: UserFileItem.customLibrary
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

    // MARK: Options Settings

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
                            Picker("To:", selection: $appState.settings.chordPro.transposeTo) {
                                ForEach(Note.allCases, id: \.self) { note in
                                    Text(note.rawValue)
                                }
                            }
                        }
                        Picker("Accidentals:", selection: $appState.settings.chordPro.transposeAccidentals) {
                            ForEach(Accidentals.allCases, id: \.self) { accidental in
                                Text(accidental.rawValue)
                            }
                        }
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
                    .padding(.top)
                }
            }
            .wrapSettingsSection(title: "Transcode")
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: SettingsView Modifiers

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
