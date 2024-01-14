//
//  HistoryRow.swift
//  Radiola
//
//  Created by Alex Sokolov on 10.07.2022.
//

import Cocoa

class HistoryRow: NSView {
    @IBOutlet var songLabel: NSTextField!
    @IBOutlet var stationLabel: NSTextField!
    @IBOutlet var dateLabel: NSTextField!
    var mainView: NSView?

    let record: Player.HistoryRecord!
    var timer: Timer?

    /* ****************************************
     *
     * ****************************************/
    init(history: Player.HistoryRecord) {
        record = history
        super.init(frame: NSRect.zero)
        _ = load(fromNIBNamed: "HistoryRow")

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshDate),
                                               name: Notification.Name.PlayerStatusChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshDate),
                                               name: Notification.Name.PlayerMetadataChanged,
                                               object: nil)

        songLabel.stringValue = record.song
        stationLabel.stringValue = record.station
        dateLabel.toolTip = dateAndTime()

        refreshDate()
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        record = Player.HistoryRecord()
        super.init(coder: coder)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func refreshDate() {
        if player.isPlaying && player.stationName == record.station && player.songTitle == record.song {
            dateLabel.stringValue = "playing now"
            dateLabel.sizeToFit()
            return
        }

        let now = Date()
        if now.timeIntervalSince(record.date) < 60 {
            dateLabel.stringValue = "less than a minute ago"
            startTimer(timeInterval: 60)

        } else if now.timeIntervalSince(record.date) < 60 * 60 {
            dateLabel.stringValue = relativeTime()
            startTimer(timeInterval: 60)

        } else if now.timeIntervalSince(record.date) < 60 * 60 * 6 {
            dateLabel.stringValue = absoluteTime()
            stopTimer()
        } else {
            dateLabel.stringValue = dateAndTime()
            stopTimer()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func relativeTime() -> String {
        let dateFormatter = RelativeDateTimeFormatter()
        dateFormatter.unitsStyle = .full

        let preferredLanguages = Locale.preferredLanguages
        if !preferredLanguages.isEmpty {
            dateFormatter.locale = Locale(identifier: preferredLanguages[0])
        }

        return dateFormatter.localizedString(for: record.date, relativeTo: Date())
    }

    /* ****************************************
     *
     * ****************************************/
    private func absoluteTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        dateFormatter.dateStyle = .none

        let preferredLanguages = Locale.preferredLanguages
        if !preferredLanguages.isEmpty {
            dateFormatter.locale = Locale(identifier: preferredLanguages[0])
        }

        return dateFormatter.string(from: record.date)
    }

    /* ****************************************
     *
     * ****************************************/
    private func dateAndTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        dateFormatter.dateStyle = .long

        let preferredLanguages = Locale.preferredLanguages
        if !preferredLanguages.isEmpty {
            dateFormatter.locale = Locale(identifier: preferredLanguages[0])
        }

        return dateFormatter.string(from: record.date)
    }

    /* ****************************************
     *
     * ****************************************/
    private func startTimer(timeInterval: Double) {
        if timer != nil && timer?.timeInterval == timeInterval {
            return
        }
        timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(refreshDate), userInfo: nil, repeats: true)
    }

    /* ****************************************
     *
     * ****************************************/
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
