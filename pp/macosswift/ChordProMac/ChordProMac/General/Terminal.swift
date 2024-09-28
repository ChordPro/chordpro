//
//  Terminal.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI
import UniformTypeIdentifiers
import OSLog

/// Terminal utilities
enum Terminal {
    // Just a placeholder
}

extension Terminal {

    /// Run a script in the shell and return its output
    /// - Parameter arguments: The arguments to pass to the shell
    /// - Returns: The output from the shell
    static func runInShell(arguments: [String]) async -> Output {
        /// The normal output
        var allOutput: [String] = []
        /// The error output
        var allErrors: [String] = []
        /// Await the results
        for await streamedOutput in runInShell(arguments: arguments) {
            switch streamedOutput {
            case let .standardOutput(output):
                allOutput.append(output)
            case let .standardError(error):
                allErrors.append(error)
            }
        }
        /// Return the output
        return Output(
            standardOutput: allOutput.joined(),
            standardError: allErrors.joined()
        )
    }

    /// Run a script in the shell and return its output
    /// - Parameter arguments: The arguments to pass to the shell
    /// - Returns: The output from the shell as a stream
    static func runInShell(arguments: [String]) -> AsyncStream<StreamedOutput> {
        /// Create the task
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["--login", "-c"] + arguments
        /// Standard output
        let pipe = Pipe()
        task.standardOutput = pipe
        /// Error output
        let errorPipe = Pipe()
        task.standardError = errorPipe
        /// Try to run the task
        do {
            try task.run()
        } catch {
            print(error.localizedDescription)
        }
        /// Return the stream
        return AsyncStream { continuation in
            pipe.fileHandleForReading.readabilityHandler = { handler in
                let standardOutput = String(decoding: handler.availableData, as: UTF8.self)
                guard !standardOutput.isEmpty else {
                    return
                }
                continuation.yield(.standardOutput(standardOutput))
            }
            errorPipe.fileHandleForReading.readabilityHandler = { handler in
                let errorOutput = String(decoding: handler.availableData, as: UTF8.self)
                guard !errorOutput.isEmpty else {
                    return
                }
                continuation.yield(.standardError(errorOutput))
            }
            /// Finish the stream
            task.terminationHandler = { _ in
                continuation.finish()
            }
        }
    }
}

extension Terminal {

    /// The complete output from the shell
    struct Output {
        /// The standard output
        var standardOutput: String
        /// The standard error
        var standardError: String
    }

    /// The stream output from the shell
    enum StreamedOutput {
        /// The standard output
        case standardOutput(String)
        /// The standard error
        case standardError(String)
    }
}

extension Terminal {

    /// We are using the official **ChordPro** binary to create the PDF
    /// - Note: The executable is packed in this application
    static func getChordProBinary() throws -> URL {
        guard
            let binary = Bundle.main.url(forResource: "chordpro", withExtension: nil)
        else {
            throw AppError.binaryNotFound
        }
        return binary
    }
}

extension Terminal {

    /// Get access to the optional custom config
    static func getOptionalCustomConfig(settings: AppSettings) -> String? {
        if
            settings.chordPro.useCustomConfig,
            let persistentURL = UserFileBookmark.getBookmarkURL(UserFileItem.customConfig) {
            /// Get access to the URL
            _ = persistentURL.startAccessingSecurityScopedResource()
            /// Close the access
            UserFileBookmark.stopCustomFileAccess(persistentURL: persistentURL)
            return "--config='\(persistentURL.path)'"
        }
        return nil
    }
}

extension Terminal {

    /// Get information about the **ChordPro** binary
    /// - Returns: The info in a ``ChordProInfo`` struct
    static func getChordProInfo() async throws -> ChordProInfo {
        /// Get the application settings
        let settings = AppSettings.load()
        /// Get the **ChordPro** binary
        let chordProApp = try getChordProBinary()
        /// Build the arguments to pass to the shell
        var arguments: [String] = []
        /// Add the optional additional library to the environment of the shell
        if
            settings.chordPro.useAdditionalLibrary,
            let persistentURL = UserFileBookmark.getBookmarkURL(UserFileItem.customLibrary) {
            /// Get access to the URL
            _ = persistentURL.startAccessingSecurityScopedResource()
            arguments.append("CHORDPRO_LIB='\(persistentURL.path)'")
            /// Close the access
            UserFileBookmark.stopCustomFileAccess(persistentURL: persistentURL)
        }
        /// Add the argument to get the information
        arguments.append("'\(chordProApp.path)' -A -A -A")
        /// Add selected built-in presets
        for preset in settings.chordPro.systemConfigs {
            arguments.append("--config=\(preset.fileName)")
        }
        /// Add the optional custom config file
        if let customConfig = getOptionalCustomConfig(settings: settings) {
            arguments.append(customConfig)
        }
        /// Run **ChordPro** in the shell
        let output = await Terminal.runInShell(arguments: [arguments.joined(separator: " ")])
        /// Convert the JSON data to a ``ChordProInfo`` struct
        let jsonData = output.standardOutput.data(using: .utf8)!
        let chordProInfo = try JSONDecoder().decode(ChordProInfo.self, from: jsonData)
        Logger.application.log("Loaded ChordPro info")
        return chordProInfo
    }
}

extension Terminal {

    /// Export a document or folder with the **ChordPro** binary to a PDF
    /// - Parameters:
    ///   - text: The current text of the document
    ///   - settings: The current ``AppSettings``
    ///   - sceneState: The current ``SceneStateModel``
    ///   - fileList: The optional list of files (for a songbook)
    ///   - title: The title of the export
    ///   - subtitle: The optional subtitle of the export
    /// - Returns: The PDF as `Data` and the status as ``AppError``
    static func exportPDF(
        text: String,
        settings: AppSettings,
        sceneState: SceneStateModel,
        fileList: Bool = false,
        title: String = "",
        subtitle: String = ""
    ) async throws -> (data: Data, status: AppError) {
        /// Get the **ChordPro** binary
        let chordProApp = try getChordProBinary()
        /// Remove previous export (if any)
        try? FileManager.default.removeItem(atPath: sceneState.exportURL.path)
        /// Write the song to the source URL
        /// - Note: We don't read the file URL directly because it might not be saved yet
        do {
            try text.write(to: sceneState.sourceURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            throw AppError.writeDocumentError
        }
        /// Build the arguments to pass to the shell
        var arguments: [String] = []
        /// Add the optional additional library to the environment of the shell
        if
            settings.chordPro.useAdditionalLibrary,
            let persistentURL = UserFileBookmark.getBookmarkURL(UserFileItem.customLibrary) {
            /// Get access to the URL
            _ = persistentURL.startAccessingSecurityScopedResource()
            arguments.append("CHORDPRO_LIB='\(persistentURL.path)'")
            /// Close the access
            UserFileBookmark.stopCustomFileAccess(persistentURL: persistentURL)
        }
        /// The **ChordPro** binary
        arguments.append("\"\(chordProApp.path)\"")
        /// Songbook export
        if fileList {
            /// Add the system generated front cover if selected
            if settings.application.songbookGenerateCover {
                arguments.append("--title='\(title)'")
                if !subtitle.isEmpty {
                    arguments.append("--subtitle='\(subtitle)'")
                }
            }
            /// Add a custom cover if selected
            if
                settings.application.songbookUseCustomCover,
                let persistentURL = UserFileBookmark.getBookmarkURL(UserFileItem.songbookCover) {
                /// Get access to the URL
                _ = persistentURL.startAccessingSecurityScopedResource()
                arguments.append("--front-matter='\(persistentURL.path)'")
                /// Close the access
                UserFileBookmark.stopCustomFileAccess(persistentURL: persistentURL)
            }
            /// Add the file list
            arguments.append("--filelist=\"\(sceneState.fileListURL.path)\"")
        } else {
            arguments.append("\"\(sceneState.sourceURL.path)\"")
        }
        /// Get the user settings that are simple and do not need sandbox help
        arguments.append(contentsOf: AppStateModel.getUserSettings(settings: settings))
        /// Add the optional custom config file
        if let customConfig = getOptionalCustomConfig(settings: settings) {
            arguments.append(customConfig)
        }
        /// Add the optional selected ``CustomTask``
        if let taskConfig = sceneState.customTask {
            arguments.append("--config='\(taskConfig.url.path)'")
        }

        if let localConfigURL = sceneState.localConfigURL, !settings.chordPro.noDefaultConfigs {
            _ = localConfigURL.startAccessingSecurityScopedResource()
            arguments.append("--config='\(localConfigURL.path)'")
            UserFileBookmark.stopCustomFileAccess(persistentURL: localConfigURL)
        }

        /// Add the output file
        arguments.append("--output='\(sceneState.exportURL.path)'")
        /// Run **ChordPro** in the shell
        /// - Note: The output is logged
        let output = await Terminal.runInShell(arguments: [arguments.joined(separator: " ")])
        /// Write to the log file
        let log = output.standardError.isEmpty ? "No errors occurred but the song might be empty" : output.standardError
        do {
            try log.write(to: sceneState.logFileURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            throw AppError.writeDocumentError
        }
        do {
            /// Try to get the `Data` from the created PDF
            let data = try Data(contentsOf: sceneState.exportURL)
            /// Return the `Data` and the status of the creation as an ``AppError`
            /// - Note: That does not mean it is has an error, the status is just using the same structure
            return (data, output.standardError.isEmpty ? .noErrorOccurred : .pdfCreatedWithErrors)
        } catch {
            /// There is no data, throw an ``AppError``
            throw output.standardError.isEmpty ? AppError.emptySong : AppError.pdfCreationError
        }
    }
}
