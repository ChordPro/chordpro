//
//  ChordProInfo.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 13/06/2024.
//

import Foundation

/// The structure of the JSON **ChordPro** information
struct ChordProInfo: Codable, Equatable {
    let general: General
    let modules: [Module]
    let resources: [Resource]
}

extension ChordProInfo {

    struct General: Codable, Equatable {
        let abc: String
        let chordpro: Chordpro
        let library: [Resource]
        let perl: Perl
    }

    struct Chordpro: Codable, Equatable {
        let aux, version: String
    }

    struct Resource: Codable, Hashable, Equatable {
        let dppath, path: String
    }

    struct Perl: Codable, Equatable {
        let dppath, path, version: String
    }

    struct Module: Codable, Hashable, Equatable {
        let dppath, name, path, version: String
        let library: String?
    }
}
