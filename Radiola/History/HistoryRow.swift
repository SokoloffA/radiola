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
    func load(fromNIBNamed nibName: String) -> Bool {
        var nibObjects: NSArray?
        let nibName = NSNib.Name(stringLiteral: nibName)

        if Bundle.main.loadNibNamed(nibName, owner: self, topLevelObjects: &nibObjects) {
            guard let nibObjects = nibObjects else { return false }

            let viewObjects = nibObjects.filter { $0 is NSView }

            if viewObjects.count > 0 {
                guard let view = viewObjects[0] as? NSView else { return false }
                mainView = view
                addSubview(mainView!)

                mainView?.translatesAutoresizingMaskIntoConstraints = false
                mainView?.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
                mainView?.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
                mainView?.topAnchor.constraint(equalTo: topAnchor).isActive = true
                mainView?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

                return true
            }
        }

        return false
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func refreshDate() {
        if player.isPlaying && player.station.name == record.station && player.title == record.song {
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
