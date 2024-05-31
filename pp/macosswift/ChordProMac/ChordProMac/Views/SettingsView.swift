//
//  SettingsView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 27/05/2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The templates we found in the official **ChordPro** source
    @State var templates: [Template] = []
    /// The notations we found in the official **ChordPro** source
    @State var notations: [Notation] = []
    /// The body of the `View`
    var body: some View {
        TabView {
            editor
                .tabItem {
                    Label("Editor", systemImage: "text.word.spacing")
                }
            configuration
                .tabItem {
                    Label("Configuration", systemImage: "filemenu.and.selection")
                }
        }
        //.formStyle(.grouped)
        .animation(.smooth, value: appState.settings)
    }
}

extension SettingsView {
    /// SwiftUI `View` with editor settings
    var editor: some View {
        VStack {
            Section {
                Picker("The font size of the editor", selection: $appState.settings.fontSize) {
                    ForEach(12...24, id: \.self) { value in
                        Text("\(value)px")
                            .tag(Double(value))
                    }
                }
            } header: {
                Text("Font")
                    .font(.title2)
            }
            .padding([.horizontal, .bottom])
        }
        .padding(.top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

extension SettingsView {
    /// SwiftUI `View` with configuration settings
    var configuration: some View {
        ScrollView {
            Section {
                Picker("Build-in", selection: $appState.settings.template) {
                    ForEach(templates) { template in
                        Text(template.label.capitalized)
                            .tag(template.label)
                    }
                }
            } header: {
                Text("Template")
                    .font(.title2)
            }
            .padding([.horizontal, .bottom])
            Section {
                Toggle("Transpose the song", isOn: $appState.settings.transpose)
                if appState.settings.transpose {
                    HStack {
                        Picker("From", selection: $appState.settings.transposeFrom) {
                            ForEach(Note.allCases, id: \.self) { note in
                                Text(note.rawValue)
                            }
                        }
                        Picker("To", selection: $appState.settings.transposeTo) {
                            ForEach(Note.allCases, id: \.self) { note in
                                Text(note.rawValue)
                            }
                        }
                    }
                    Picker("Accents", selection: $appState.settings.transposeAccents) {
                        ForEach(Accents.allCases, id: \.self) { accents in
                            Text(accents.rawValue)
                        }
                    }
                }
            } header: {
                Text("Transpose")
                    .font(.title2)
            }
            .padding([.horizontal, .bottom])
            Section {
                Toggle("Transcode the notation", isOn: $appState.settings.transcode)
                if appState.settings.transcode {
                    Picker("Transcode to", selection: $appState.settings.transcodeNotation) {
                        ForEach(notations) { notation in
                            Text("\(notation.label.capitalized): \(notation.description)")
                            //.frame(maxWidth: .infinity, alignment: .trailing)
                                .tag(notation.label)
                        }
                    }
                    .labelsHidden()
                }
            } header: {
                Text("Transcode")
                    .font(.title2)
            }
            .padding([.horizontal, .bottom])
        }
        .padding(.top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
            self.templates = templates
            self.notations = notations
        }
    }
}
