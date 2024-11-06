//
//  ChordProEditor.swift
//  ChordProMac
//

import SwiftUI

// MARK: The ChordPro editor

/// SwiftUI `NSViewRepresentable` for the **ChordPro** editor
struct ChordProEditor: NSViewRepresentable {
    /// The `Binding` to the text of the document
    @Binding var text: String
    /// The  settings for the editor
    let settings: Settings
    /// All the directives we know about
    let directives: [ChordProDirective]
    /// The log from the song parser
    let log: [LogItem]
    /// The 'introspect' callback with the editor``Internals``
    private(set) var introspect: IntrospectCallback?
    /// Make a `coordinator` for the `NSViewRepresentable`
    /// - Returns: A `coordinator`
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    /// Make the `View`
    /// - Parameter context: The context
    /// - Returns: The wrapped editor
    func makeNSView(context: Context) -> Wrapper {
        let wrapper = Wrapper()
        wrapper.delegate = context.coordinator
        wrapper.textView.directives = directives
        wrapper.textView.parent = self
        wrapper.textView.font = settings.font
        wrapper.textView.string = text
        wrapper.textView.log = log
        /// Wait for next cycle and set the textview as first responder
        Task { @MainActor in
            highlightText(textView: wrapper.textView)
            wrapper.textView.selectedRanges = [NSValue(range: NSRange())]
            wrapper.textView.window?.makeFirstResponder(wrapper.textView)
        }
        return wrapper
    }
    /// Update the `View`
    /// - Parameters:
    ///   - view: The wrapped editor
    ///   - context: The context
    func updateNSView(_ wrapper: Wrapper, context: Context) {
        if wrapper.textView.log != log {
            wrapper.textView.log = log
            wrapper.selectionNeedsDisplay()
        }
        if wrapper.textView.directives.map(\.directive) != directives.map(\.directive) {
            wrapper.textView.directives = directives
            wrapper.selectionNeedsDisplay()
        }
        /// Update the text in the TextView when it is changed from *outside*; like when adding the example song
        if context.coordinator.task == nil, self.text != wrapper.textView.string {
            wrapper.textView.string = text
            highlightText(textView: wrapper.textView)
        }
        /// Update the settings when changed
        if context.coordinator.parent.settings != settings {
            context.coordinator.parent = self
            highlightText(textView: wrapper.textView)
        }
    }
    /// Highlight the text in the editor
    /// - Parameters:
    ///   - textView: The current ``TextView``
    ///   - range: The range to highlight
    @MainActor func highlightText(textView: NSTextView, range: NSRange? = nil) {
        ChordProEditor.highlight(
            view: textView,
            settings: settings,
            range: range ?? NSRange(location: 0, length: text.utf16.count),
            directives: directives
        )
    }
}

// MARK: Introspect extensions

extension ChordProEditor {

    func introspect(callback: @escaping IntrospectCallback) -> Self {
        var editor = self
        editor.introspect = callback
        return editor
    }

    @MainActor func runIntrospect(_ view: TextView) {
        guard let introspect = introspect else { return }
        /// Set the internals of the editor
        let internals = Internals(
            currentLineNumber: view.currentLineNumber,
            directive: view.currentDirective,
            directiveArgument: view.currentDirectiveArgument,
            directiveRange: view.currentDirectiveRange,
            clickedDirective: view.clickedDirective,
            selectedRange: view.selectedRange(),
            textView: view
        )
        introspect(internals)
    }
}

typealias IntrospectCallback = (_ editor: ChordProEditor.Internals) -> Void
