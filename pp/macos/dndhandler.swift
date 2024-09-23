//
//  dndhandler.swift
//  ChordPro
//
//  Drag'n'Drop and Finder command handling
//

import AppKit

// MARK: Start the application

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)

// MARK: The Application Delegate

@available(macOS 10.15, *)
class AppDelegate: NSObject, NSApplicationDelegate {
    /// The optional URL to open
    var open: URL?
    /// Store the requested file URL to add as agument for **wxchordpro**
    func application(_ sender: NSApplication, open urls: [URL]) {
        open = urls.first
    }
    /// Set the arguments and create a window with **wxchordpro**
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let path = Bundle.main.executablePath?.replacingOccurrences(of: "dndhandler", with: "wxchordpro")
        if let path {
            /// We *must* create arguments and the first one is the path to the executable
            var args: [String] = ["\(path)"]
            /// Add the optional file URL as second argument
            if let open {
                args.append("\(open.path)")
            }
            /// Black magic
            let cargs = args.map { strdup($0) } + [nil]
            /// Execute the **wxchordpro** program with its arguments
            execv(path, cargs)
        }
        /// This should not happen
        fatalError("exec failed")
    }
}
