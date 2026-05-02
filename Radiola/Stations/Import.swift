//
//  Import.swift
//  Radiola
//
//  Created by Alex Sokolov on 02.05.2026.
//

import CSV
import Foundation
import M3UKit

// MARK: - ImportedStations

fileprivate class ImportedStations: OpmlStations {
    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(icon: "", file: URL(fileURLWithPath: ""))
    }

    /* ****************************************
     *
     * ****************************************/
    @discardableResult
    func addStation(url: String, title: String, path: [String], isFavorite: Bool = false) -> Station {
        let t = !title.isEmpty ? title : url

        let parent = findOrCreateGroup(path: path)
        let station = createStation(title: t, url: url)
        if let station = station as? OpmlStation {
            station.isFavorite = isFavorite
        }
        parent.append(station)
        return station
    }

    /* ****************************************
     *
     * ****************************************/
    @discardableResult
    func addStation(url: URL, title: String, path: [String], isFavorite: Bool = false) -> Station {
        return addStation(url: url.absoluteString, title: title, path: path, isFavorite: isFavorite)
    }

    /* ****************************************
     *
     * ****************************************/
    private func findOrCreateGroup(path: [any StringProtocol]) -> any StationGroup {
        if path.isEmpty {
            return self
        }

        var parent = self as StationGroup
        for p in path {
            let g = parent.items.first { $0 is StationGroup && $0.title == p } as? StationGroup
            if let g = g {
                parent = g
            } else {
                let new = createGroup(title: String(p))
                parent.append(new)
                parent = new
            }
        }

        return parent
    }
}

/* ****************************************
 *
 * ****************************************/
fileprivate func parsePath(_ path: String?, separator: Character = "/") -> [String] {
    return path?.split(separator: separator, omittingEmptySubsequences: true).map(String.init) ?? []
}

// MARK: - M3U

/* ****************************************
 *
 * ****************************************/
func importFromM3U(file: URL) throws -> StationList {
    let res = ImportedStations()
    let parser = PlaylistParser()
    let playlist = try parser.parse(file)

    for media in playlist.medias {
        res.addStation(url: media.url, title: media.name, path: parsePath(media.attributes.groupTitle))
    }

    return res
}

// MARK: - CSV

/* ****************************************
 *
 * ****************************************/
func importFromCSV(file: URL) throws -> StationList {
    let res = ImportedStations()

    guard
        let stream = InputStream(url: file)
    else {
        throw RadiolaError("File open error")
    }

    let csv = try CSVReader(stream: stream)

    while let row = csv.next() {
        if row.count < 1 {
            continue
        }

        let url = row[0]
        if !url.starts(with: "http") {
            continue
        }

        let title = row.count > 1 ? row[1] : ""
        let path = row.count > 2 ? row[2] : ""
        let favorite = row.count > 3 && row[3].lowercased() == "favorite"

        res.addStation(url: url, title: title, path: parsePath(path), isFavorite: favorite)
    }

    return res
}
