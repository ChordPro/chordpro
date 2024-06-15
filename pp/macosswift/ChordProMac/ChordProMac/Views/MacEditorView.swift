//
//  MacEditorView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 11/06/2024.
//

import SwiftUI

/// The editor for **ChordPro**
struct MacEditorView: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> CustomTextView {
        let textView = CustomTextView()
        textView.delegate = context.coordinator

        return textView
    }

    func updateNSView(_ view: CustomTextView, context: Context) {
        if view.textView.string != text {
            view.textView.string = text
            let all = NSRange(location: 0, length: text.utf16.count)
            MacEditorView.highlight(view: view.textView, font: font, range: all)
        }
        if view.textView.font != font {
            view.textView.font = font
        }
    }
}

extension MacEditorView {

    // MARK: Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MacEditorView
        var fullHighlight: Bool = true
        /// The optional balance string, close  a`{` or `[`
        var balance: String?

        init(_ parent: MacEditorView) {
            self.parent = parent
        }

        func textView(
            _ textView: NSTextView,
            shouldChangeTextIn affectedCharRange: NSRange,
            replacementString: String?
        ) -> Bool {
            /// The optional balance string, close  a`{` or `[`
            balance = replacementString == "[" ? "]" : replacementString == "{" ? "}" : nil
            /// For performance, don't highlight all text when not needed
            fullHighlight = replacementString?.count ?? 0 > 1
            return true
        }

        func textDidBeginEditing(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            self.parent.text = textView.string
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            if let balance, let range = textView.selectedRanges.first?.rangeValue {
                textView.insertText(balance, replacementRange: range)
                textView.selectedRanges = [NSValue(range: range)]
                self.balance = nil
            }
            let composeText = textView.string as NSString
            var highlightRange = NSRange()
            if fullHighlight {
                /// Full highlighting of the document
                highlightRange = NSRange(location: 0, length: composeText.length)
            } else {
                /// Highlight only the current paragraph
                highlightRange = composeText.paragraphRange(for: textView.selectedRange)
            }
            MacEditorView.highlight(
                view: textView,
                font: textView.font ?? .systemFont(ofSize: 14),
                range: highlightRange
            )
            parent.text = textView.string
        }

        func textDidEndEditing(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            self.parent.text = textView.string
        }
    }
}

extension MacEditorView {

    // MARK: CustomTextView

    final class CustomTextView: NSView {
        weak var delegate: NSTextViewDelegate?

        private lazy var scrollView: NSScrollView = {
            let scrollView = NSScrollView()
            scrollView.drawsBackground = true
            scrollView.borderType = .noBorder
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalRuler = false
            scrollView.autoresizingMask = [.width, .height]
            scrollView.translatesAutoresizingMaskIntoConstraints = false

            return scrollView
        }()

        lazy var textView: NSTextView = {
            let contentSize = scrollView.contentSize
            let textContentStorage = NSTextContentStorage()
            let textLayoutManager = NSTextLayoutManager()
            textContentStorage.addTextLayoutManager(textLayoutManager)
            let textContainer = NSTextContainer(containerSize: scrollView.frame.size)
            textContainer.widthTracksTextView = true
            textContainer.containerSize = NSSize(
                width: contentSize.width,
                height: CGFloat.greatestFiniteMagnitude
            )
            textLayoutManager.textContainer = textContainer

            let textView = NSTextView(frame: .zero, textContainer: textContainer)
            textView.autoresizingMask = .width
            textView.backgroundColor = NSColor.textBackgroundColor
            textView.delegate = self.delegate
            textView.drawsBackground = true
            textView.font = .systemFont(ofSize: 14)
            textView.isEditable = true
            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            textView.minSize = NSSize(width: 0, height: contentSize.height)
            textView.textColor = NSColor.labelColor
            textView.allowsUndo = true
            textView.isAutomaticQuoteSubstitutionEnabled = false
            textView.textContainerInset = .init(width: 4, height: 8)

            return textView
        }()

        override func viewWillDraw() {
            super.viewWillDraw()

            setupScrollViewConstraints()
            setupTextView()
        }

        func setupScrollViewConstraints() {
            scrollView.translatesAutoresizingMaskIntoConstraints = false

            addSubview(scrollView)

            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: topAnchor),
                scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
                scrollView.leadingAnchor.constraint(equalTo: leadingAnchor)
            ])
        }

        func setupTextView() {
            scrollView.documentView = textView
        }
    }
}
