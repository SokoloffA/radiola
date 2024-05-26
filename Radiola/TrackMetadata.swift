//
//  TrackMetadata.swift
//  Radiola
//
//  Created by Alex Sokolov on 26.05.2024.
//

import Foundation

// MARK: - TrackMetadata

func cleanTrackMetadata(raw: String) -> String {
    if raw.isEmpty { return raw }

    if raw.first == "{" && raw.last == "}" {
        if let res = processJson(raw) {
            return res
        }
    }

    return raw
}

fileprivate func processJson(_ raw: String) -> String? {
    let data = raw.data(using: .utf8)!

    do {
        struct Struct: Decodable {
            var artist: String
            var name: String
        }

        let res = try JSONDecoder().decode(Struct.self, from: data)
        return "\(res.artist) - \(res.name)"
    } catch { }

    do {
        struct Struct: Decodable {
            var artist: String
            var title: String
        }

        let res = try JSONDecoder().decode(Struct.self, from: data)
        return "\(res.artist) - \(res.title)"
    } catch { }

    return nil
}
