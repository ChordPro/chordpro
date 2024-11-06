//
//  Logger+extension.swift
//  ChordProMac
//

import Foundation
import OSLog

/// Messages for the Logger
extension Logger {

    /// The name of the subsystem
    private static let subsystem = Bundle.main.bundleIdentifier ?? ""
    /// Log PDF build messages
    static var pdfBuild: Logger {
        Logger(subsystem: subsystem, category: "PDF build")
    }
    /// Log application messages
    static var application: Logger {
        Logger(subsystem: subsystem, category: "Application")
    }
    /// Log file access messages
    static var fileAccess: Logger {
        Logger(subsystem: subsystem, category: "File Access")
    }
}
