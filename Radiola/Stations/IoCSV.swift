//
//  iocsv.swift
//  Radiola
//
//  Created by Alex Sokolov on 02.05.2026.
//

import CSV
import Foundation

extension StationList {
    /* ****************************************
     *
     * ****************************************/
    func saveAsCSV(file: URL) throws {
        func writeOutline(csv: CSVWriter, item: StationItem, path: String) throws {
            if let station = item as? Station {
                csv.beginNewRow()
                try csv.write(field: station.url)
                try csv.write(field: station.title)
                try csv.write(field: path)
                try csv.write(field: station.isFavorite ? "favorite" : "")
            }

            if let group = item as? StationGroup {
                let p = path + "/" + item.title
                for it in group.items {
                    try writeOutline(csv: csv, item: it, path: p)
                }
            }
        }

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

        for item in items {
            try writeOutline(csv: csv, item: item, path: "")
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func LoadFromCSV(file: URL) throws {
        func addItem(url: String, title: String, favorite: Bool, path: String) {
            let pi = path.split(separator: "/", maxSplits: Int.max, omittingEmptySubsequences: true)
            let parent = findOrCreateGroup(path: pi)

            let station = createStation(title: title, url: url)
            if let station = station as? OpmlStation {
                station.isFavorite = favorite
            }
            parent.append(station)
        }

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

            let title = row.count > 1 ? row[1] : url
            let path = row.count > 2 ? row[2] : ""
            let favorite = row.count > 3 && row[3].lowercased() == "favorite"

            addItem(url: url, title: title, favorite: favorite, path: path)
        }
    }
}
