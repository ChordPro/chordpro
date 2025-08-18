//
//  dndhandler.swift
//  ChordPro
//
//  Drag'n'Drop and Finder command handling
//

import AppKit

if #available(macOS 10.15, *) {
    
    // MARK: Start the application
    
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    
    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    
    // MARK: The Application Delegate
    
    class AppDelegate: NSObject, NSApplicationDelegate {
        
        /// The optional URLs to open, either dropped or clicked in the Finder
        var open: [URL]?
        /// Bool if the **dndhandler** is already running
        var running: Bool = false
        /// Current open **wxchordpro** windows
        var openWindows: [String: Int32] = [:]
        
        /// # Static
        
        /// The URL to the Bundle
        let bundleURL = Bundle.main.bundleURL
        /// Bundle launch configuration  options
        let configuration = NSWorkspace.OpenConfiguration()
        
        /// # Protocol functions
        
        /// Store the requested file URL to add as argument for **wxchordpro**
        func application(_ sender: NSApplication, open urls: [URL]) {
            open = urls
            /// The **dndhandler** is already running, open the **wxchordpro** windows
            if running {
                createWxChordProProcess()
            }
        }

        /// Set the arguments and create a window with **wxchordpro**
        func applicationDidFinishLaunching(_ aNotification: Notification) {
            /// Remember that we are launched
            running = true
            /// Open at least one window
            createWxChordProProcess()
        }
        /// Bring all **wxchordpro** windows to the foreground
        func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
            for app in NSWorkspace.shared.runningApplications where app.localizedName == "ChordPro" {
                if !app.isActive {
                    app.activate(options: NSApplication.ActivationOptions.activateIgnoringOtherApps)
                }
            }
            return false
        }
        
        /// # Private functions
        
        private func createWxChordProProcess() {
            /// Open **wxchordpro** with the file(s) as argument
            if let open = open {
                for file in open {
                    if let windowID = openWindows[file.path] {
                        NSLog("Already open: \(file.lastPathComponent)")
                        for app in NSWorkspace.shared.runningApplications where app.processIdentifier == windowID {
                            app.activate(options: NSApplication.ActivationOptions.activateIgnoringOtherApps)
                        }
                    } else {
                        NSLog("Opening: \(file.lastPathComponent)")
                        launchProcess(argument: file.path)
                    }
                }
                /// Clear the list with files to open
                self.open = nil
            } else {
                /// Just open, it is not a DnD
                NSLog("Opening Main Window")
                launchProcess(argument: "main")
            }
        }
        
        private func launchProcess(argument: String) {
            let wxURL = URL(fileURLWithPath: "\(self.bundleURL.path )/Contents/MacOS/wxchordpro")
            let process = Process()
            process.executableURL = wxURL
            /// Add the file argument
            /// - Note: Main means no file argument
            if argument != "main" {
                process.arguments = [argument]
            }
            process.terminationHandler = { _ in
                self.openWindows[argument] = nil
                if self.openWindows.isEmpty {
                    /// No more open windows
                    NSLog("All windows closed, terminating")
                    NSApplication.shared.terminate(nil)
                }
            }
            try? process.run()
            /// Remember the window ID
            openWindows[argument] = process.processIdentifier
            /// Make sure we have the focus
            /// - Note: Needed for Ventura and lower or else the menu bar is unresponsive
            if #available(macOS 14.0, *) { } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    NSWorkspace.shared.openApplication(
                        at: self.bundleURL,
                        configuration: self.configuration,
                        completionHandler: nil
                    )
                }
            }
        }
    }
}
