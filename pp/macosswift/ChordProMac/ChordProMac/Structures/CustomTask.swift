//
//  CustomTask.swift
//  ChordProMac
//

import Foundation

/// A custom task we found in the **ChordPro** _custom library task_ folder
struct CustomTask: Identifiable, Equatable, Hashable {
    /// The calculated ID of the task
    var id: URL {
        url
    }
    /// The `URL` of the task
    let url: URL
    /// The label of the task
    let label: String
}
