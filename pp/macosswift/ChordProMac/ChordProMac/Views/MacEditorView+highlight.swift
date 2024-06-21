//
//  MacEditorView+highlight.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 11/06/2024.
//

import AppKit

extension MacEditorView {

    // swiftlint:disable force_try

    /// The regex for chords
    static let chordRegex = try! NSRegularExpression(pattern: "\\[([\\w#b\\/]+)\\]", options: .caseInsensitive)
    /// The regex for directives
    static let directiveRegex = try! NSRegularExpression(pattern: "\\{.*\\}")
    /// The regex for directive arguments
    static let directiveArgumentRegex = try! NSRegularExpression(pattern: "(?<=\\:)(.*)(?=\\})")
    /// The regex for comments
    static let commentsRegex = try! NSRegularExpression(pattern: "#[^\\[\\]\\n]*")
    /// The regex for pango
    static let pangoRegex = try! NSRegularExpression(pattern: "<\\/?[^>]*>")
    /// The regex for brackets
    static var bracketsRegex = try! NSRegularExpression(pattern: "\\/?[\\[\\]\\{\\}\"]")

    // swiftlint:enable force_try

    /// The line height multiplier for the editor text
    static let lineHeightMultiple: Double = 1.2
    /// The style of a paragraph in the editor
    static let paragraphStyle: NSParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = MacEditorView.lineHeightMultiple
        return style
    }()

    static let regexes: [(regex: NSRegularExpression, color: NSColor)] =
    [
        (commentsRegex, NSColor.systemGray),
        (chordRegex, NSColor.systemRed),
        (directiveRegex, NSColor.systemIndigo),
        (directiveArgumentRegex, NSColor.systemOrange),
        (pangoRegex, NSColor.systemTeal),
        (bracketsRegex, NSColor.systemGray)
    ]

    /// Highlight the text in the editor
    /// - Parameters:
    ///   - view: The `NSTextView`
    ///   - font: The current `NSFont`
    ///   - range: The `NSRange` to highlight
    ///   - directives: The known directives
    /// - Returns: A highlighted text
    static func highlight(view: NSTextView, font: NSFont, range: NSRange, directives: [String]) {
        let text = view.textStorage?.string ?? ""
        /// Make all text in the default style
        view.textStorage?.setAttributes(
            [
                .paragraphStyle: MacEditorView.paragraphStyle,
                .foregroundColor: NSColor.textColor,
                .font: font
            ],
            range: range
        )
        /// Go to all the regex definitions
        MacEditorView.regexes.forEach { regex in
            let matches = regex.regex.matches(in: text, options: [], range: range)
            matches.forEach { match in
                view.textStorage?.addAttribute(
                    .foregroundColor,
                    value: regex.color,
                    range: match.range
                )
            }
        }
        /// Some extra love for known directives
        if let knownDirectiveRegex =  try? NSRegularExpression(
            pattern: "(?<=\\{)(?:" + directives.joined(separator: "|") + ")(?=[\\}|\\:])"
        ) {
            let boldFont = font.fontDescriptor.addingAttributes().withSymbolicTraits(.bold)
            let matches = knownDirectiveRegex.matches(in: text, options: [], range: range)
            matches.forEach { match in
                view.textStorage?.addAttribute(
                    .font,
                    value:  NSFont(descriptor: boldFont, size: font.pointSize)!,
                    range: match.range
                )
            }
        }

        /// The attributes for the next typing
        view.typingAttributes = [
            .paragraphStyle: MacEditorView.paragraphStyle,
            .foregroundColor: NSColor.textColor,
            .font: font
        ]
    }
}
