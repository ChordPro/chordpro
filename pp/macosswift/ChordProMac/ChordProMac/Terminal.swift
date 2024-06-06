//
//  Terminal.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI
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
                guard let standardOutput = String(data: handler.availableData, encoding: .utf8) else {
                    return
                }
                guard !standardOutput.isEmpty else {
                    return
                }
                continuation.yield(.standardOutput(standardOutput))
            }
            errorPipe.fileHandleForReading.readabilityHandler = { handler in
                guard let errorOutput = String(data: handler.availableData, encoding: .utf8) else {
                    return
                }
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
        public var standardOutput: String
        /// The standard error
        public var standardError: String
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

    /// Export a document with the **chordpro** binary to a PDF
    /// - Parameters:
    ///   - document: The current ``ChordProDocument``
    ///   - settings: The current ``AppSettings``
    ///   - sceneState: The current ``SceneState``
    /// - Returns: The PDF as `Data` and the status as ``AppError``
    static func exportDocument(
        document: ChordProDocument,
        settings: AppSettings,
        sceneState: SceneState
    ) async throws -> (data: Data, status: AppError) {
        /// We are using the official **ChordPro** binary to create the PDF
        /// - Note: The executable is packed in this application
        guard
            let chordProApp = Bundle.main.url(forResource: "chordpro", withExtension: nil)
        else {
            throw AppError.binaryNotFound
        }
        /// Remove previous export (if any)
        try? FileManager.default.removeItem(atPath: sceneState.exportURL.path)
        /// Write the song to the source URL
        /// - Note: We don't read the file URL directly because it might not be saved yet
        do {
            try document.text.write(to: sceneState.sourceURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            throw AppError.writeDocumentError
        }
        /// Build the arguments to pass to the shell
        var arguments: [String] = []
        /// Add the optional additional library to the environment of the shell
        if
            settings.useAdditionalLibrary,
            let persistentURL = try? FileBookmark.getBookmarkURL(CustomFile.customLibrary) {
            /// Get access to the URL
            _ = persistentURL.startAccessingSecurityScopedResource()
            arguments.append("CHORDPRO_LIB='\(persistentURL.path)'")
            /// Close the access
            FileBookmark.stopCustomFileAccess(persistentURL: persistentURL)
        }
        /// The **ChordPro** binary
        arguments.append("'\(chordProApp.path)'")
        /// Add the source file
        arguments.append("'\(sceneState.sourceURL.path)'")
        /// Add the config file
        ///
        /// This can be one of the following
        /// - A user selected **Custom Config File**
        /// - A system provided configuration
        if settings.useCustomConfig, let persistentURL = try? FileBookmark.getBookmarkURL(CustomFile.customConfig) {
            /// Get access to the URL
            _ = persistentURL.startAccessingSecurityScopedResource()
            arguments.append("--config='\(persistentURL.path)'")
            /// Close the access
            FileBookmark.stopCustomFileAccess(persistentURL: persistentURL)
        } else {
            /// Use the system config
            arguments.append("--config=\(settings.systemConfig)")
        }
        /// Get the user settings that are simple and do not need sandbox help
        arguments.append(contentsOf: AppState.getUserSettings(settings: settings))
        /// Add the optional selected ``CustomTask``
        if let taskConfig = sceneState.customTask {
            arguments.append("--config='\(taskConfig.url.path)'")
        }
        /// Add the output file
        arguments.append("--output='\(sceneState.exportURL.path)'")
        /// Run **ChordPro** in the shell
        /// - Note: The output is logged
        let output = await Terminal.runInShell(arguments: [arguments.joined(separator: " ")])
        Logger.pdfBuild.log("ERROR: \(output.standardError, privacy: .public)")
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
            throw AppError.emptySong
        }
    }
}
