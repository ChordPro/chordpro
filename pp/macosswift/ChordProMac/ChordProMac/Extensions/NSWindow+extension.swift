//
//  NSWindow+extension (macOS).swift
//  Chord Provider
//
//  © 2024 Nick Berendsen
//

import SwiftUI

extension NSWindow {

    /// Find the NSWindow of the scene
    struct HostingWindowFinder: NSViewRepresentable {
        /// The optional `NSWindow`
        var callback: (NSWindow?) -> Void
        func makeNSView(context: Context) -> NSView {
            let view = NSView()
            Task { @MainActor in
                callback(view.window)
            }
            return view
        }
        func updateNSView(_ nsView: NSView, context: Context) { }
    }

    /// The structure of an open window
    struct WindowItem {
        /// The ID of the `Window`
        let windowID: Int
        /// The URL of the ChordPro document
        var fileURL: URL?
    }
}
