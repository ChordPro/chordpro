//
//  ChordProEditor+highlight.swift
//  ChordProMac
//

import AppKit

extension ChordProEditor {

    /// The type of regex
    enum RegexType {
        /// Normal; only apply a color to the match
        case normal
        /// Range; apply a color and the range of the match
        case range
        /// Argument; apply a color and the argument of the match
        case argument
    }

    // swiftlint:disable force_try

    /// The regex for chords
    static let chordRegex = try! NSRegularExpression(pattern: "\\[([\\w#b\\/]+)\\]", options: .caseInsensitive)
    /// The regex for directives
    static let directiveRegex = try! NSRegularExpression(pattern: "\\{.*\\}")
    /// The regex for directive arguments
    static let directiveArgumentRegex = try! NSRegularExpression(pattern: "(?<=\\:)(.*)(?=\\})")
    /// The regex for comments
    static let commentsRegex = try! NSRegularExpression(pattern: "(?<=^|\\n)#[^\\n]*")
    /// The regex for markup
    static let markupRegex = try! NSRegularExpression(pattern: "<\\/?[^>]*>")
    /// The regex for brackets
    static let bracketsRegex = try! NSRegularExpression(pattern: "\\/?[\\[\\]\\{\\}\"]")
    /// The regex for new lines
    static let newLineRegex = try! NSRegularExpression(pattern: "\n", options: [])

    // swiftlint:enable force_try

    // swiftlint:disable:next large_tuple
    static func regexes(settings: Settings) -> [(regex: NSRegularExpression, color: NSColor, regexType: RegexType)] {
        return [
            (commentsRegex, NSColor(settings.commentColor), .normal),
            (directiveRegex, NSColor(settings.directiveColor), .range),
            (directiveArgumentRegex, NSColor(settings.argumentColor), .argument),
            (markupRegex, NSColor(settings.markupColor), .normal),
            (chordRegex, NSColor(settings.chordColor), .normal),
            (bracketsRegex, NSColor(settings.bracketColor), .normal)
        ]
    }

    /// Highlight the text in the editor
    /// - Parameters:
    ///   - view: The `NSTextView`
    ///   - font: The current `NSFont`
    ///   - range: The `NSRange` to highlight
    ///   - directives: The known directives
    /// - Returns: A highlighted text
    @MainActor static func highlight(
        view: NSTextView,
        settings: Settings,
        range: NSRange,
        directives: [ChordProDirective]
    ) {
        let text = view.textStorage?.string ?? ""
        let regexes = ChordProEditor.regexes(settings: settings)
        /// Make all text in the default style
        view.textStorage?.setAttributes(
            [
                .foregroundColor: NSColor.textColor,
                .font: settings.font
            ],
            range: range
        )
        /// Go to all the regex definitions
        regexes.forEach { regex in
            let matches = regex.regex.matches(in: text, options: [], range: range)
            matches.forEach { match in
                switch regex.regexType {
                case .normal:
                    view.textStorage?.addAttribute(
                        .foregroundColor,
                        value: regex.color,
                        range: match.range
                    )
                case .range:
                    view.textStorage?.addAttributes(
                        [
                            .foregroundColor: regex.color,
                            .directiveRange: match.range
                        ],
                        range: match.range
                    )
                case .argument:
                    if let swiftRange = Range(match.range, in: text) {
                        view.textStorage?.addAttributes(
                            [
                                .foregroundColor: regex.color,
                                .directiveArgument: text[swiftRange]
                            ],
                            range: match.range
                        )
                    }
                }
            }
        }
        /// Some extra love for known directives
        guard
            let knownDirectiveRegex = try? NSRegularExpression(
                pattern: "(?<=\\{)(?:" + directives.map(\.directive).joined(separator: "|") + ")(?=[\\}|\\:])"
            ),
            let boldFont = NSFont(
                descriptor: settings.font.fontDescriptor.addingAttributes().withSymbolicTraits(.bold),
                size: settings.font.pointSize
            )
        else {
            return
        }
        let matches = knownDirectiveRegex.matches(in: text, options: [], range: range)
        matches.forEach { match in
            if let swiftRange = Range(match.range, in: text) {
                view.textStorage?.addAttributes(
                    [
                        .font: boldFont,
                        .directive: text[swiftRange]
                    ],
                    range: match.range
                )
            }
        }

        /// The attributes for the next typing
        view.typingAttributes = [
            .foregroundColor: NSColor.textColor,
            .font: settings.font
        ]
    }
}

extension NSAttributedString.Key {

    /// Make `directive` an attributed string key
    static let directive: NSAttributedString.Key = .init("directive")

    /// Make `directiveArgument` an attributed string key
    static let directiveArgument: NSAttributedString.Key = .init("directiveArgument")

    /// Make `directiveRange` an attributed string key
    static let directiveRange: NSAttributedString.Key = .init("directiveRange")
}
