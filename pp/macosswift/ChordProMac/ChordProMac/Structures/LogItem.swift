//
//  LogItem.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 02/06/2024.
//

import Foundation

/// A single line from the **ChordPro** log
struct LogItem: Identifiable {
    /// Make sure it has an unique ID because lines can be the same
    let id: UUID = UUID()
    /// The line from the log
    var line: String
}
