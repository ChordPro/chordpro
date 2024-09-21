//
//  Directive.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 24/06/2024.
//

import Foundation

/// Definition of a directive
struct Directive: ChordProDirective {
    /// The name of the directive
    let directive: String
    /// The group the directive belongs to
    let group: Group
    /// The icon for the directive
    let icon: String
    /// Bool if the directive is editable
    let editable: Bool
    /// Optional help-text for the directive
    let help: String
    /// The name for an optional button to add this directive
    var button: String = ""
    /// The label of the directive
    var label: String {
        return self.directive.replacingOccurrences(of: "_", with: " ").capitalized
    }
    /// The directive groups
    enum Group {
        case metadata
        case directive
        case abbreviation
    }
}

extension Directive {

    /// Get all the directive we know about
    /// - Returns: An array of directives
    static func getChordProDirectives(chordProInfo: ChordProInfo?) -> [Directive] {
        var directives: [Directive] = []
        guard
            let info = chordProInfo
        else {
            return directives
        }
        directives.append(
            contentsOf: info.metadata.map { item in
                Directive(
                    directive: item,
                    group: .metadata,
                    icon: "info.circle",
                    editable: false,
                    help: ""
                )
            }
        )
        directives.append(
            contentsOf: info.directives.map { item in
                // swiftlint:disable:next line_length
                let icon = item.starts(with: "start_") ? "increase.indent" : item.starts(with: "end_") ? "decrease.quotelevel" : "tag"
                return Directive(
                    directive: item,
                    group: .directive,
                    icon: icon,
                    editable: false,
                    help: ""
                )
            }
        )
        directives.append(
            contentsOf: info.directiveAbbreviations.map(\.key).map { item in
                Directive(
                    directive: item,
                    group: .abbreviation,
                    icon: "tag",
                    editable: false,
                    help: ""
                )
            }
        )
        return directives
    }
}
