//
//  Logger.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 27/05/2024.
//

import OSLog

/// Messages for the Logger
public extension Logger {

    /// The name of the subsystem
    private static let subsystem = Bundle.main.bundleIdentifier ?? ""

    /// Log PDF build messages
    static var pdfBuild: Logger {
        Logger(subsystem: subsystem, category: "PDF build")
    }
}
