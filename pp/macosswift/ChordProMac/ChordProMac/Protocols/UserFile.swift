//
//  File.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/06/2024.
//

import Foundation
import UniformTypeIdentifiers

/// Protocol to define user selectable files
protocol UserFile {
    /// The ID of the user file
    var id: String { get }
    /// The `UTType`s of the file
    var utTypes: [UTType] { get }
    /// The optional calculated label of the file
    var label: String? { get }
    /// The SF icon of the file
    var icon: String { get }
    /// The message for the file sheet
    var message: String { get }
}
