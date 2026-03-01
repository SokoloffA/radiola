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
    private let favoriteButton = ImageButton()
    let menuButton = MenuButton()
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
        addSubview(menuButton)
        addSubview(dateLabel)
        addSubview(favoriteButton)
        addSubview(separator)

        songLabel.setFontWeight(.medium)

        favoriteButton.image = NSImage(systemSymbolName: NSImage.Name("heart"), accessibilityDescription: NSLocalizedString("Mark song as favorite", comment: "History window icon tooltip"))
        favoriteButton.alternateImage = NSImage(systemSymbolName: NSImage.Name("heart.fill"), accessibilityDescription: NSLocalizedString("Unmark song as favorite", comment: "History window icon tooltip"))
        favoriteButton.target = self
        favoriteButton.action = #selector(toggleFavorite)

        stationLabel.font = NSFont.systemFont(ofSize: 11)
        stationLabel.textColor = .secondaryLabelColor

        dateLabel.font = NSFont.systemFont(ofSize: 12)
        dateLabel.textColor = .secondaryLabelColor

        songLabel.translatesAutoresizingMaskIntoConstraints = false
        stationLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        menuButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            songLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            songLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -36),

            favoriteButton.centerYAnchor.constraint(equalTo: songLabel.centerYAnchor),
            favoriteButton.widthAnchor.constraint(equalToConstant: 20),
            favoriteButton.heightAnchor.constraint(equalToConstant: 20),

            menuButton.leadingAnchor.constraint(equalTo: favoriteButton.trailingAnchor, constant: 8),
            menuButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            menuButton.centerYAnchor.constraint(equalTo: favoriteButton.centerYAnchor),
            menuButton.widthAnchor.constraint(equalTo: favoriteButton.widthAnchor),
            menuButton.heightAnchor.constraint(equalTo: favoriteButton.heightAnchor),

            stationLabel.leadingAnchor.constraint(equalTo: songLabel.leadingAnchor),
            dateLabel.leadingAnchor.constraint(equalTo: stationLabel.trailingAnchor, constant: 8),
            dateLabel.trailingAnchor.constraint(equalTo: favoriteButton.trailingAnchor),

            songLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6.0),
            stationLabel.topAnchor.constraint(equalTo: songLabel.bottomAnchor, constant: 4),
            stationLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5.0),

            dateLabel.lastBaselineAnchor.constraint(equalTo: stationLabel.lastBaselineAnchor),
        ])

        separator.alignBottom(of: self)

        menuButton.menu = initMenu()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshDate),
                                               name: Notification.Name.PlayerStatusChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshDate),
                                               name: Notification.Name.PlayerMetadataChanged,
                                               object: nil)

        songLabel.stringValue = record.song
        stationLabel.stringValue = record.stationTitle
        dateLabel.toolTip = dateAndTime()

        refreshFavoriteButton()
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
    private func initMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: NSLocalizedString("Copy song title to clipboard", comment: "History action menu item"), action: #selector(copySongToClipboard), keyEquivalent: "").target = self
        return menu
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func copySongToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(record.song, forType: .string)
    }

    /* ****************************************
     *
     * ****************************************/
    private func refreshFavoriteButton() {
        if record.isFavorite {
            favoriteButton.state = .on
            favoriteButton.toolTip = NSLocalizedString("The current song has been marked as a favorite.", comment: "History window icon tooltip")
        } else {
            favoriteButton.state = .off
            favoriteButton.toolTip = NSLocalizedString("Toggle favorite", comment: "History window icon tooltip")
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func refreshDate() {
        if record.isLast && player.isPlaying && player.stationName == record.stationTitle && player.songTitle == record.song {
            dateLabel.stringValue = NSLocalizedString("playing now", comment: "History window song status")
            dateLabel.sizeToFit()
            return
        }

        let now = Date()
        if now.timeIntervalSince(record.date) < 60 {
            dateLabel.stringValue = NSLocalizedString("less than a minute ago", comment: "History window song status")
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

    /* ****************************************
     *
     * ****************************************/
    @objc private func toggleFavorite() {
        record.isFavorite = !record.isFavorite
        refreshFavoriteButton()
    }
}
