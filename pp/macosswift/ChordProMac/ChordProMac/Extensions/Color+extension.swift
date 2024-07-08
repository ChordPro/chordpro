//
//  Color+extension.swift
//  Chord Provider
//
//  © 2024 Nick Berendsen
//

import SwiftUI

extension Color: Codable {

    /// Make `Color` encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let nsColor = NSColor(self)
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: nsColor,
            requiringSecureCoding: true
        )
        try container.encode(data)
    }

    /// Make `Color` decodable
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        guard let nsColor = try NSKeyedUnarchiver
            .unarchivedObject(ofClass: NSColor.self, from: data)
        else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid decoding of archived data")
        }
        self.init(nsColor: nsColor)
    }
}
