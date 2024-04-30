//
//  History.swift
//  Radiola
//
//  Created by Alex Sokolov on 30.04.2024.
//

import Foundation

// MARK: - HistoryRecord

class HistoryRecord {
    var song: String = ""
    var station: String = ""
    var date: Date = Date()
    var favorite: Bool = false

    init(song: String, station: String, favorite: Bool = false) {
        self.song = song
        self.station = station
        self.favorite = favorite
    }
}

// MARK: - History

typealias History = [HistoryRecord]

extension History {
    private var maxCount: Int { 100 }

    mutating func add(station: Station, songTitle: String) {
        if last?.song == songTitle && last?.station == station.title {
            return
        }

        append(HistoryRecord(song: songTitle, station: station.title))
        if count > maxCount {
            removeFirst(count - maxCount)
        }
    }

    func isFavorite(song: String) -> Bool {
        return contains { rec in
            rec.favorite && rec.song == song
        }
    }

    mutating func setFavorite(song: String, favorite: Bool) {
        for rec in self {
            if rec.song == song {
                rec.favorite = favorite
            }
        }
    }
}
