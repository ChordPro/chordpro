//
//  ExportSongbookView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 05/09/2024.
//

import SwiftUI
import UniformTypeIdentifiers
import QuickLook
import OSLog

/// SwiftUI `View` to export a folder of songs to a **ChordPro** Songbook
/// - Note: macOS Monterey does not understand UTType.folder
///         so we have to write a whole DropDelegate to validate the drop as 'folder'

struct ExportSongbookView: View, DropDelegate {
    /// The observable state of the application
    @StateObject private var appState = AppStateModel.shared
    /// The observable state of the scene
    @StateObject private var sceneState = SceneStateModel()
    /// The observable state of the songbook
    @StateObject private var songbookState = SongbookStateModel()
    /// The optional dropped folder with songs
    @State private var droppedURL: URL?
    /// Optional annotations in the PDF
    @State private var annotations: [(userName: String, contents: String)] = []

    // MARK: Body View

    /// The body of the `View`
    var body: some View {
        VStack {
            HStack {
                list
                options
                    .frame(width: 300)
            }
            Divider()
            StatusView()
                .padding(.horizontal)
        }
        .frame(minWidth: 680, minHeight: 500, alignment: .top)
        .animation(.default, value: appState.settings.application)
        .overlay {
            VStack {
                Text(songbookState.chordProRunning ? "Making the PDF" : "Your PDF is ready")
                    .font(.headline)
                if let data = songbookState.pdf {
                        AppKitUtils.PDFKitRepresentedView(data: data, annotations: $annotations)
                            .frame(width: 400, height: 300)
                            .border(Color.accentColor, width: 1)
                        HStack {
                            Button("Close") {
                                songbookState.pdf = nil
                            }
                            Button("Export") {
                                songbookState.exportFolderDialog = true
                            }
                        }
                        .padding()
                } else {
                    ProgressView()
                        .padding()
                    Text("This might take some time...")
                        .font(.caption)
                }
            }
            .padding()
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 10)
            .opacity(songbookState.chordProRunning || songbookState.pdf != nil ? 1 : 0)
        }
        .animation(.default, value: songbookState.pdf)
        .task {
            songbookState.makeFileList(appState: appState)
        }
        .task(id: appState.settings.application.songbookGenerateCover) {
            if appState.settings.application.songbookGenerateCover {
                appState.settings.application.songbookUseCustomCover = false
            }
        }
        .task(id: appState.settings.application.songbookUseCustomCover) {
            if appState.settings.application.songbookUseCustomCover {
                appState.settings.application.songbookGenerateCover = false
            }
        }
        .onDrop(of: [.fileURL], delegate: self)
        .fileExporter(
            isPresented: $songbookState.exportFolderDialog,
            document: ExportDocument(pdf: songbookState.pdf),
            contentType: .pdf,
            defaultFilename: appState.settings.application.songbookTitle
        ) { _ in
            Logger.pdfBuild.notice("Export completed")
            songbookState.pdf = nil
        }
        .quickLookPreview($songbookState.coverPreview)
        .environmentObject(appState)
        .environmentObject(sceneState)
    }

    // MARK: List View

    var list: some View {
        VStack {
            List {
                ForEach($appState.settings.application.fileList) { $item in
                    HStack {
                        Toggle(isOn: $item.enabled, label: {
                            Text("Enable")
                        })
                        .labelsHidden()
                        VStack(alignment: .leading) {
                            if !item.path.isEmpty {
                                Text(item.path.joined(separator: "・"))
                                    .font(.caption)
                            }
                            Text(item.url.deletingPathExtension().lastPathComponent)
                        }
                    }
                    .swipeActions {
                        Button {
                            Task {
                                await songbookState.openSong(url: item.url)
                            }
                        } label: {
                            Label {
                                Text("Edit")
                            } icon: {
                                Image(systemName: "pencil")
                            }
                        }
                        .tint(.green)
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([item.url])
                        } label: {
                            Label {
                                Text("Open in Finder")
                            } icon: {
                                Image(systemName: "folder")
                            }
                        }
                        .tint(.indigo)
                    }
                }
                /// - Note: Monterey is screwing multi-line items when dragged/dropped
                .onMove { fromOffsets, toOffset in
                    appState.settings.application.fileList.move(fromOffsets: fromOffsets, toOffset: toOffset)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .border(Color.accentColor, width: songbookState.isDropping ? 2 : 0)
            .overlay {
                if appState.settings.application.fileList.isEmpty {
                    Text("Drop a folder with your **ChordPro** files here to view its content and to make a Songbook.")
                        .multilineTextAlignment(.center)
                        .wrapSettingsSection(title: "File List")
                }
            }
            Label(
                title: { Text("You can reorder the songs by drag and drop\nand swipe left for more actions") },
                icon: { Image(systemName: "info.circle") }
            )
            .foregroundStyle(.secondary)
            .font(.caption)
        }
    }

    // MARK: Options View

    var options: some View {
        VStack {
            ScrollView {
                VStack {
                    UserFileButton(userFile: UserFileItem.exportFolder) {
                        songbookState.currentFolder = SongbookStateModel.exportFolderTitle
                        songbookState.makeFileList(appState: appState)
                    }
                    .id(songbookState.currentFolder)
                    Toggle(isOn: $appState.settings.application.recursiveFileList) {
                        Text("Also look for songs in subfolders")
                    }
                    .onChange(of: appState.settings.application.recursiveFileList) { _ in
                        songbookState.makeFileList(appState: appState)
                    }
                    .padding(.vertical)
                    Text(.init(songbookState.songCountLabel(count: appState.settings.application.fileList.count)))
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .wrapSettingsSection(title: "The folder with your songs")
                VStack {
                    Toggle(isOn: $appState.settings.application.songbookGenerateCover, label: {
                        Text("Add a standard cover page")
                    })
                    .padding(.bottom)
                    if appState.settings.application.songbookGenerateCover {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Title:")
                                    .frame(width: 60, alignment: .trailing)
                                    .font(.headline)
                                TextField(
                                    text: $appState.settings.application.songbookTitle,
                                    prompt: Text("Title")
                                ) {
                                    Text("Title")
                                }
                            }
                            HStack {
                                Text("Subtitle:")
                                    .frame(width: 60, alignment: .trailing)
                                    .font(.headline)
                                TextField(
                                    text: $appState.settings.application.songbookSubtitle,
                                    prompt: Text("Subtitle")
                                ) {
                                    Text("Subtitle")
                                }
                            }
                        }
                        .padding([.horizontal, .bottom])
                    }

                    Toggle(isOn: $appState.settings.application.songbookUseCustomCover, label: {
                        Text("Add a custom cover page")

                    })
                    if appState.settings.application.songbookUseCustomCover {
                        VStack {
                            HStack {
                                UserFileButton(userFile: UserFileItem.songbookCover) {
                                    songbookState.currentCover = SongbookStateModel.exportCoverTitle
                                }
                                if let url = UserFileBookmark.getBookmarkURL(UserFileItem.songbookCover) {
                                    Button(
                                        action: {
                                            songbookState.coverPreview = url
                                        },
                                        label: {
                                            Image(systemName: "eye")
                                        }
                                    )
                                }
                            }
                            .disabled(!appState.settings.application.songbookUseCustomCover)
                            .id(songbookState.currentCover)
                            .padding()
                            Label(
                                title: { Text("Only a PDF can be used as a custom cover") },
                                icon: { Image(systemName: "info.circle") }
                            )
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .wrapSettingsSection(title: "The cover page")
            }
            .disabled(songbookState.chordProRunning)
            .frame(maxWidth: .infinity)
            Button(action: {
                songbookState.makeSongbook(appState: appState, sceneState: sceneState)
            }, label: {
                Text("Export Songbook")
            })
            .padding()
            .disabled(songbookState.currentFolder == nil || appState.settings.application.songbookTitle.isEmpty)
        }
    }
}

extension ExportSongbookView {

    /// DropDelegate protocol item to verify a drop
    /// - Parameter info: Information about the dropped area
    /// - Returns: True if a folder is dropped
    func validateDrop(info: DropInfo) -> Bool {
        guard
            info.hasItemsConforming(to: [.fileURL]),
            let provider = info.itemProviders(for: [.fileURL]).first
        else { return false }
        /// Set the standard default
        var result = false
        if provider.canLoadObject(ofClass: URL.self) {
            let group = DispatchGroup()
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                defer { group.leave() }
                if let url {
                    let flag = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType == .folder
                    result = flag ?? false
                }
                droppedURL = result ? url : nil
            }

            /// Wait a moment for verification result
            _ = group.wait(timeout: .now() + 0.5)
        }
        return result
    }

    /// DropDelegate protocol item to perform a drop action
    /// - Parameter info: Information about the dropped area
    /// - Returns: True
    func performDrop(info: DropInfo) -> Bool {
        Task {
            if let url = droppedURL {
                UserFileBookmark.setBookmarkURL(UserFileItem.exportFolder, url)
                songbookState.currentFolder = url.lastPathComponent
                songbookState.makeFileList(appState: appState)
            }
        }
        return true
    }
}
