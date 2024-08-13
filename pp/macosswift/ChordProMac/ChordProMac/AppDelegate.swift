//
//  AppDelegate.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 13/06/2024.
//

import SwiftUI

/// The AppDelegate to bring the `About` Window into the SwiftUI world
class AppDelegate: NSObject, NSApplicationDelegate {

    private var aboutBoxWindowController: NSWindowController?

    @MainActor func showAboutWindow() {
        if aboutBoxWindowController == nil {
            let styleMask: NSWindow.StyleMask = [.closable, .miniaturizable, .titled]
            let window = NSWindow()
            window.styleMask = styleMask
            window.title = "About ChordPro"
            window.contentView = NSHostingView(rootView: AboutView())
            window.center()
            aboutBoxWindowController = NSWindowController(window: window)
        }

        aboutBoxWindowController?.showWindow(aboutBoxWindowController?.window)
    }
}
