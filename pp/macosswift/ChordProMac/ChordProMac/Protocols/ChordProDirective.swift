//
//  ChordProDirective.swift
//  ChordProMac
//

import Foundation

/// Protocol to define directives
protocol ChordProDirective: Sendable {
    /// The name of the directive
    var directive: String { get }
    /// The label of the directive
    var label: String { get }
    /// The icon of the directive
    var icon: String { get }
    /// Bool of the directive is editable
    var editable: Bool { get }
    /// The name for an optional button to add this directive
    var button: String { get }
    /// Optional help-text for the directive
    var help: String { get }
}
