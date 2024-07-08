//
//  PreviewState.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 02/07/2024.
//

import Foundation

/// The state of a PDF preview
public struct PreviewState: Equatable {
    /// Init the preview state
    /// - Parameters:
    ///   - id: The ID of the preview`
    ///   - url: The optional URL for a preview
    ///   - data: The optional data for a preview
    ///   - outdated: Bool if the preview is outdated
    public init(id: String = UUID().uuidString, url: URL? = nil, data: Data? = nil, outdated: Bool = false) {
        self.id = id
        self.url = url
        self.data = data
        self.outdated = outdated
    }
    /// The ID of the preview`
    public var id: String
    /// The optional URL for a preview
    public var url: URL?
    /// The optional data for a preview
    public var data: Data?
    /// Bool if the preview is outdated
    public var outdated: Bool = false
    /// Bool if the preview is active
    public var active: Bool {
        return (url != nil || data != nil)
    }
}
