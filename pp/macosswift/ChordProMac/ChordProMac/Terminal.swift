//
//  Terminal.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI
import OSLog

/// Terminal utilities
public enum Terminal {
    // Just a placeholder
}

public extension Terminal {

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
    public struct Output {
        /// The standard output
        public var standardOutput: String
        /// The standard error
        public var standardError: String
    }

    /// The stream output from the shell
    public enum StreamedOutput {
        /// The standard output
        case standardOutput(String)
        /// The standard error
        case standardError(String)
    }
}

extension Terminal {

    static func exportDocument(document: ChordProDocument, settings: AppSettings) async throws -> (data: Data?, exportURL: URL) {
        /// For now, just use the official **ChordPro** binary to create the PDF
        /// - Note: The executable is packed in this application
        guard
            let chordProApp = Bundle.main.url(forResource: "chordpro", withExtension: nil)
        else {
            throw AppError.binaryNotFound
        }
        Logger.pdfBuild.log("BUNDLE: \(chordProApp.path, privacy: .public)")
        /// Store the export in the temporarily directory
        /// - Note: I don;t read the file URL directly because it might not be saved yet
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        /// Create a source URL
        let sourceURL = temporaryDirectoryURL.appendingPathComponent(document.fileID, conformingTo: .chordProSong)
        /// Create an export URL
        let exportURL = temporaryDirectoryURL.appendingPathComponent(document.fileID, conformingTo: .pdf)
        /// Write the song to the source URL
        do {
            try document.text.write(to: sourceURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            throw AppError.writeDocumentError
        }
        /// Build the arguments for **ChordPro**
        
        /// The **ChordPro** binary
        var arguments:[String] = ["'\(chordProApp.path)'"]
        /// Add the source file
        arguments.append("'\(sourceURL.path)'")
        /// Add the config file
        arguments.append("--config=\(settings.template)")
        /// Add the optional  transcode
        if settings.transcode {
            arguments.append("--transcode=\(settings.transcodeNotation)")
        }
        /// Add the optional transpose value
        if settings.transpose, let transpose = settings.transposeValue {
            arguments.append("--transpose=\(transpose)")
        }
        /// Add the output file
        arguments.append("--output='\(exportURL.path)'")
        /// Run **ChordPro** in the shell
        /// - Note: The output is logged
        let output = await Terminal.runInShell(arguments: [arguments.joined(separator: " ")])
        Logger.pdfBuild.log("OUTPUT: \(output.standardError, privacy: .public)")
        /// Return the created PDF
        return (try? Data(contentsOf: exportURL), exportURL)
    }
}
