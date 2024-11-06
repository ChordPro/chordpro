//
//  Terminal.swift
//  ChordProMac
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
    @MainActor static func runInShell(arguments: [String], sceneState: SceneStateModel?) async -> Output {
        /// The normal output
        var allOutput: [OutputItem] = []
        /// The error output
        var allErrors: [OutputItem] = []
        /// Await the results
        for await streamedOutput in runInShell(arguments: arguments) {
            switch streamedOutput {
            case let .standardOutput(output):
                allOutput.append(.init(time: output.time, message: output.message))
            case let .standardError(error):
                if let sceneState, !error.message.isEmpty {
                    sceneState.logMessages.append(parseChordProMessage(error, sceneState: sceneState))
                }
                allErrors.append(.init(time: error.time, message: error.message))
            }
        }
        /// Return the output
        return Output(
            standardOutput: allOutput,
            standardError: allErrors
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
                guard let standardOutput = String(data: handler.availableData, encoding: .utf8) else {
                    return
                }
                continuation.yield(.standardOutput(.init(time: .now, message: standardOutput)))
            }
            errorPipe.fileHandleForReading.readabilityHandler = { handler in
                guard let errorOutput = String(data: handler.availableData, encoding: .utf8) else {
                    return
                }
                continuation.yield(.standardError(.init(time: .now, message: errorOutput)))
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
        var standardOutput: [OutputItem]
        /// The standard error
        var standardError: [OutputItem]
    }

    /// The stream output from the shell
    enum StreamedOutput {
        /// The standard output
        case standardOutput(OutputItem)
        /// The standard error
        case standardError(OutputItem)
    }

    /// The structure for an output item
    struct OutputItem {
        let time: Date
        let message: String
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
        let output = await Terminal.runInShell(arguments: [arguments.joined(separator: " ")], sceneState: nil)
        /// Convert the JSON data to a ``ChordProInfo`` struct
        let json = output.standardOutput.map(\.message).joined()
        let jsonData = json.data(using: .utf8)!
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
    @MainActor static func exportPDF(
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
            /// Define the warning messages
            arguments.append("--define diagnostics.format='%f, line %n, %m'")
            /// Log in verbose modus to get an idea of the progress
            arguments.append("--verbose")
            /// Reset the progress
            sceneState.songbookProgress = (0, "Processing songs")
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
            /// Define the warning messages
            arguments.append("--define diagnostics.format='Line %n, %m'")
            /// Add the source file
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
        /// Add the optional local config that is next to a song file
        if let localConfigURL = sceneState.localConfigURL, !settings.chordPro.noDefaultConfigs {
            _ = localConfigURL.startAccessingSecurityScopedResource()
            arguments.append("--config='\(localConfigURL.path)'")
            UserFileBookmark.stopCustomFileAccess(persistentURL: localConfigURL)
        }
        /// Add the output file
        arguments.append("--output=\"\(sceneState.exportURL.path)\"")
        /// Add the process to the log
        sceneState.logMessages = [.init(type: .notice, message: "Creating PDF preview")]
        /// Clear the editor messages
        sceneState.editorMessages = []
        /// Run **ChordPro** in the shell
        /// - Note: The output is logged
        let output = await Terminal.runInShell(arguments: [arguments.joined(separator: " ")], sceneState: sceneState)
        /// Try to get the `Data` from the created PDF
        do {
            let data = try Data(contentsOf: sceneState.exportURL)
            /// If **ChordPro** does not return any output all went well
            if sceneState.logMessages.count == 1 {
                sceneState.logMessages.append(.init(type: .notice, message: "No issues found"))
            }
            /// Return the `Data` and the status of the creation as an ``AppError`
            /// - Note: That does not mean it is has an error, the status is just using the same structure
            return (data, sceneState.logMessages.filter { $0.type == .warning}.isEmpty ? .noErrorOccurred : .pdfCreatedWithErrors)
        } catch {
            /// There is no data, throw an ``AppError``
            throw output.standardError.isEmpty ? AppError.emptySong : AppError.pdfCreationError
        }
    }
}

extension Terminal {

    /// Parse a **ChordPro** mesdsage
    /// - Parameters:
    ///   - output: The raw outoput as read from stdError
    ///   - sceneState: The sceneState of the current document
    /// - Returns: An item for the internal log
    @MainActor static func parseChordProMessage(_ output: Terminal.OutputItem, sceneState: SceneStateModel) -> ChordProEditor.LogItem {
        /// Cleanup the message
        let message = output.message
            .replacingOccurrences(of: sceneState.sourceURL.path, with: sceneState.sourceURL.lastPathComponent)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let lineNumberRegex = try? NSRegularExpression(pattern: "^Line (\\d+), (.*)")
        let progressRegex = try? NSRegularExpression(pattern: "^Progress\\[PDF(.*) - (.*)")
        /// Check for progress (for a Songbook export)
        if
            let match = progressRegex?.firstMatch(in: message, options: [], range: NSRange(location: 0, length: message.utf16.count)),
            let remaining = Range(match.range(at: 2), in: message) {
            sceneState.songbookProgress  = (sceneState.songbookProgress.item + 1, String(message[remaining]))
        }
        /// Check for a line number
        if
            let match = lineNumberRegex?.firstMatch(in: message, options: [], range: NSRange(location: 0, length: message.utf16.count)),
            let lineNumber = Range(match.range(at: 1), in: message),
            let remaining = Range(match.range(at: 2), in: message)
        {
            let message = ChordProEditor.LogItem(
                time: output.time,
                type: .warning,
                lineNumber: Int(message[lineNumber]),
                message: "Warning: \(String(message[remaining]))"
            )
            sceneState.editorMessages.append(message)
            return message
        } else {
            return (
                .init(
                    time: output.time,
                    type: .notice,
                    message: message
                )
            )
        }
    }
}
