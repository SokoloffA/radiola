//
//  HistoryRow.swift
//  Radiola
//
//  Created by Alex Sokolov on 10.07.2022.
//

import Cocoa

class HistoryRow: NSView {
    private var songLabel = Label()
    private var stationLabel = Label()
    private var dateLabel = Label()
    private let favoriteSong = IconView(
        onImage: NSImage(systemSymbolName: NSImage.Name("heart.fill"), accessibilityDescription: "Current song is favorite"),
        offImage: nil
    )
    let separator = Separator()

    let record: HistoryRecord
    var timer: Timer?

    /* ****************************************
     *
     * ****************************************/
    init(history: HistoryRecord) {
        record = history
        super.init(frame: NSRect.zero)

        addSubview(songLabel)
        addSubview(stationLabel)
        addSubview(dateLabel)
        addSubview(favoriteSong)
        addSubview(separator)

        songLabel.setFontWeight(.medium)

        favoriteSong.toolTip = "The current song has been marked as a favorite."

        stationLabel.font = NSFont.systemFont(ofSize: 11)
        stationLabel.textColor = .secondaryLabelColor

        dateLabel.font = NSFont.systemFont(ofSize: 12)
        dateLabel.textColor = .secondaryLabelColor

        songLabel.translatesAutoresizingMaskIntoConstraints = false
        stationLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        favoriteSong.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            songLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            songLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -36),

            favoriteSong.centerYAnchor.constraint(equalTo: songLabel.centerYAnchor),
            favoriteSong.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),

            stationLabel.leadingAnchor.constraint(equalTo: songLabel.leadingAnchor),
            dateLabel.leadingAnchor.constraint(equalTo: stationLabel.trailingAnchor, constant: 8),
            dateLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),

            songLabel.topAnchor.constraint(equalTo: topAnchor, constant: 7.0),
            stationLabel.topAnchor.constraint(equalTo: songLabel.bottomAnchor, constant: 4),
            stationLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5.0),

            dateLabel.lastBaselineAnchor.constraint(equalTo: stationLabel.lastBaselineAnchor),
        ])

        separator.alignBottom(of: self)

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
        favoriteSong.state = record.favorite ? .on : .off

        refreshDate()
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
