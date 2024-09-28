//
//  TaskMenuButtons.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 04/06/2024.
//

import SwiftUI
import UniformTypeIdentifiers

/// SwiftUI `View` with buttons to run a ``CustomTask``
struct TaskMenuButtons: View {
    /// The observable state of the scene
    @FocusedValue(\.sceneState) private var sceneState: SceneStateModel?
    /// The body of the `View`
    var body: some View {
        VStack {
            Text("System Tasks")
                .font(.caption)
            ForEach(getSystemTasks()) { task in
                button(task: task)
            }
            if let userTasks = getUserTasks() {
                Divider()
                Text("Your custom Tasks")
                    .font(.caption)
                ForEach(userTasks) { task in
                    button(task: task)
                }
            }
        }
        .disabled(sceneState == nil)
    }
    /// SwiftUI `View for a button`
    /// - Parameter task: The ``CustomTask``
    /// - Returns: A `View`
    func button(task: CustomTask) -> some View {
        Button(task.label) {
            sceneState?.customTask = task
        }
    }
    /// Get all tasks that are build-in the application
    /// - Returns: A ``CustomTask`` array
    private func getSystemTasks() -> [CustomTask] {
        guard
            let tasksFolder = Bundle.main.url(forResource: "SystemTasks", withExtension: nil),
            let items = try? FileManager.default.contentsOfDirectory(atPath: tasksFolder.path)
        else {
            return []
        }
        return items.map { item -> CustomTask in
            let url = tasksFolder.appendingPathComponent(item)
            return CustomTask(
                url: url,
                label: url.deletingPathExtension().lastPathComponent
            )
        }
    }
    /// Get all tasks that a user might have in the _custom library folder_
    /// - Returns: A ``CustomTask`` array
    private func getUserTasks() -> [CustomTask]? {
        /// Get the user settings
        let settings = AppSettings.load()
        if settings.chordPro.useAdditionalLibrary {
            guard
                let persistentURL = UserFileBookmark.getBookmarkURL(UserFileItem.customLibrary),
                let regex = try? NSRegularExpression(
                    pattern: "(?://|\\#)\\s*(?:chordpro\\s*)?task:\\s*(.*)",
                    options: []
                )
            else {
                return nil
            }
            /// Get access to the URL
            _ = persistentURL.startAccessingSecurityScopedResource()
            let tasksURL = persistentURL.appendingPathComponent("tasks", conformingTo: .directory)
            let items = FileManager.default.enumerator(at: tasksURL, includingPropertiesForKeys: nil)
            var tasks: [CustomTask] = []
            while let item = items?.nextObject() as? URL {
                /// Check if it is a JSON or PRP file
                if item.pathExtension == "json" || item.pathExtension == "prp" {
                    /// Set the label of the task
                    var taskLabel = item
                        .deletingPathExtension()
                        .lastPathComponent.replacingOccurrences(of: "_", with: " ")
                        .capitalized
                    /// Check if there is a custom label in the file content
                    if
                        let content = try? String(contentsOf: item, encoding: .utf8),
                        let match = regex.firstMatch(
                            in: content,
                            range: NSRange(location: 0, length: content.utf16.count)
                        )?.range(at: 1),
                        let swiftRange = Range(match, in: content) {
                        taskLabel = String(content[swiftRange])
                    }
                    tasks.append(.init(url: item, label: taskLabel))
                }
            }
            /// Close the access
            persistentURL.stopAccessingSecurityScopedResource()
            /// Return the tasks, sorted by label
            return tasks.isEmpty ? nil : tasks.sorted { $0.label < $1.label }
        }
        return nil
    }
}
