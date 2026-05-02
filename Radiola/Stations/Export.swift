//
//  Export.swift
//  Radiola
//
//  Created by Alex Sokolov on 03.05.2026.
//

import CSV
import Foundation
import M3UKit

fileprivate typealias ExportFunc = (_ url: String, _ title: String, _ path: [String], _ isFavorite: Bool) throws -> Void

fileprivate extension StationList {
    /* ****************************************
     *
     * ****************************************/
    func export(func handler: ExportFunc) rethrows {
        func f(item: StationItem, path: [String]) throws {
            if let station = item as? Station {
                try handler(station.url, station.title, path, station.isFavorite)
            }

            if let group = item as? StationGroup {
                let p = path + [item.title]
                for it in group.items {
                    try f(item: it, path: p)
                }
            }
        }

        for item in items {
            try f(item: item, path: [])
        }
    }
}

fileprivate extension FileHandle {
    func write(_ str: String) throws {
        guard let data = str.data(using: .utf8) else {
            throw RadiolaError("Can't write string to file")
        }

        write(data)
    }
}

// MARK: - M3U

/* ****************************************
 *
 * ****************************************/
func exportToM3U(list: StationList, file: URL) throws {
    var content: [String] = []
    content.append("#EXTM3U")
    content.append("")

    list.export { url, title, path, _ in
        var attributes = ""

        if !path.isEmpty {
            var p = path.joined(separator: "/")
            p = p.replacingOccurrences(of: "\"", with: "\\\"")

            attributes += " group-title=\"\(p)\""
        }

        var t = title
        t = t.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "\r", with: " ")

        content.append("#EXTINF:-1\(attributes),\(title)")
        content.append(url)
        content.append("")
    }

    try content.joined(separator: "\n").write(to: file, atomically: true, encoding: .utf8)
}

// MARK: - CSV

/* ****************************************
 *
 * ****************************************/
func exportToCSV(list: StationList, file: URL) throws {
    guard
        let stream = OutputStream(url: file, append: false)
    else {
        throw RadiolaError("File open error")
    }

    let csv: CSVWriter
    csv = try CSVWriter(stream: stream)

    try csv.write(field: "URL")
    try csv.write(field: "Title")
    try csv.write(field: "Path")
    try csv.write(field: "Favorite")

    try list.export { url, title, path, isFavorite in
        csv.beginNewRow()
        try csv.write(field: url)
        try csv.write(field: title)
        try csv.write(field: path.joined(separator: "/"))
        try csv.write(field: isFavorite ? "favorite" : "")
    }
}
