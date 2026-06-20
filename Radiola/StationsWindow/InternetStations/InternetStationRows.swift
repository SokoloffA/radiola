//
//  InternetStationRows.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 15.01.2024.
//

import Cocoa
import Foundation

// MARK: - InternetStationRow

class InternetStationRow: NSView, NSTextFieldDelegate {
    private let station: InternetStation
    private let list: InternetStationList

    var nameEdit = TextField()
    var urlEdit = TextField()
    var qualityText = Label()
    var voteText = Label()
    var actionButton = ImageButton()
    var favoriteButton = ImageButton()
    let menuButton = StationMenuButton()
    let separator = Separator()

    private let actionButtonIcons = [
        false: NSImage(systemSymbolName: NSImage.Name("music.house"), accessibilityDescription: "")?.tint(color: .lightGray),
        true: NSImage(systemSymbolName: NSImage.Name("music.house.fill"), accessibilityDescription: "")?.tint(color: .systemYellow),
    ]

    private let favoriteIcons = [
        false: NSImage(systemSymbolName: NSImage.Name("star"), accessibilityDescription: "Favorite")?.tint(color: .lightGray),
        true: NSImage(systemSymbolName: NSImage.Name("star.fill"), accessibilityDescription: "Favorite")?.tint(color: .systemYellow),
    ]

    let normalFont = NSFont.systemFont(ofSize: 11)
    let smallFont = NSFont.systemFont(ofSize: 10)

    /* ****************************************
     *
     * ****************************************/
    init(station: InternetStation, list: InternetStationList) {
        self.station = station
        self.list = list
        menuButton.station = station

        super.init(frame: NSRect())
        addSubview(nameEdit)
        addSubview(actionButton)
        addSubview(favoriteButton)
        addSubview(menuButton)
        addSubview(urlEdit)
        addSubview(separator)
        addSubview(qualityText)
        addSubview(voteText)

        nameEdit.placeholderString = NSLocalizedString("Station name", comment: "Station name placeholder")
        nameEdit.isBordered = false
        nameEdit.drawsBackground = false
        if let font = nameEdit.font {
            nameEdit.font = NSFont.systemFont(ofSize: font.pointSize, weight: .medium)
        }

        nameEdit.stringValue = station.title
        nameEdit.delegate = self
        nameEdit.isEditable = false

        urlEdit.stringValue = station.url
        urlEdit.font = NSFont.systemFont(ofSize: 11)
        urlEdit.delegate = self
        urlEdit.isEditable = false
        urlEdit.textColor = .secondaryLabelColor

        actionButton.target = self
        actionButton.action = #selector(actionButtonClicked)

        favoriteButton.target = self
        favoriteButton.action = #selector(favClicked(sender:))
        favoriteButton.setButtonType(.toggle)

        qualityText.attributedStringValue = qualityInfo()
        qualityText.textColor = .secondaryLabelColor

        voteText.attributedStringValue = votesInfo()
        voteText.textColor = .secondaryLabelColor

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        nameEdit.translatesAutoresizingMaskIntoConstraints = false
        urlEdit.translatesAutoresizingMaskIntoConstraints = false
        qualityText.translatesAutoresizingMaskIntoConstraints = false
        voteText.translatesAutoresizingMaskIntoConstraints = false
        menuButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            actionButton.widthAnchor.constraint(equalToConstant: 16),
            favoriteButton.widthAnchor.constraint(equalTo: actionButton.widthAnchor),
            favoriteButton.heightAnchor.constraint(equalTo: actionButton.heightAnchor),
            favoriteButton.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor),
            nameEdit.leadingAnchor.constraint(equalTo: leadingAnchor),
            nameEdit.trailingAnchor.constraint(equalTo: actionButton.leadingAnchor, constant: -8),

            favoriteButton.leadingAnchor.constraint(equalTo: actionButton.trailingAnchor, constant: 8),

            menuButton.leadingAnchor.constraint(equalTo: favoriteButton.trailingAnchor, constant: 8),
            menuButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            menuButton.widthAnchor.constraint(equalTo: actionButton.widthAnchor),
            menuButton.heightAnchor.constraint(equalTo: actionButton.heightAnchor),
            menuButton.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor),

            urlEdit.leadingAnchor.constraint(equalTo: nameEdit.leadingAnchor),
            voteText.leadingAnchor.constraint(equalTo: urlEdit.trailingAnchor, constant: 8),
            qualityText.leadingAnchor.constraint(equalTo: voteText.trailingAnchor, constant: 8),
            qualityText.trailingAnchor.constraint(equalTo: actionButton.trailingAnchor),

            actionButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            actionButton.heightAnchor.constraint(equalToConstant: 16),
            nameEdit.topAnchor.constraint(equalTo: topAnchor, constant: 6.0),
            urlEdit.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5.0),
            voteText.lastBaselineAnchor.constraint(equalTo: urlEdit.lastBaselineAnchor),
            qualityText.lastBaselineAnchor.constraint(equalTo: urlEdit.lastBaselineAnchor),

        ])

        separator.alignBottom(of: self)

        refreshButtons()
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
    @objc private func actionButtonClicked(sender: NSButton) {
        if AppState.shared.localStation(byURL: station.url) == nil,
           let (_, list) = createLocalStation() {
            list.trySave()
        }

        refreshButtons()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func favClicked(sender: NSButton) {
        if let (localStation, list) = AppState.shared.localStationAndList(byURL: station.url) {
            localStation.isFavorite = !localStation.isFavorite
            list.trySave()
        } else if let (localStation, list) = createLocalStation() {
            localStation.isFavorite = true
            list.trySave()
        }

        refreshButtons()
    }

    /* ****************************************
     *
     * ****************************************/
    private func refreshActionButton() {
        let inLocal = AppState.shared.localStation(byURL: station.url) != nil
        actionButton.image = actionButtonIcons[inLocal]!
        actionButton.toolTip = inLocal ? "" : NSLocalizedString("Add the station to my stations list", comment: "Button tooltip")
    }

    /* ****************************************
     *
     * ****************************************/
    private func refreshFavoriteButton() {
        let isFavorite = AppState.shared.localStation(byURL: station.url)?.isFavorite ?? false

        favoriteButton.image = favoriteIcons[isFavorite]!
        favoriteButton.state = isFavorite ? .on : .off
        favoriteButton.toolTip = isFavorite ?
            NSLocalizedString("Unmark station as favorite", comment: "Station favorite star icon tooltip") :
            NSLocalizedString("Mark station as favorite", comment: "Station favorite star icon tooltip")
    }

    /* ****************************************
     *
     * ****************************************/
    private func refreshButtons() {
        refreshActionButton()
        refreshFavoriteButton()
    }

    /* ****************************************
     *
     * ****************************************/
    private func createLocalStation() -> (station: Station, list: any StationList)? {
        guard let list = AppState.shared.localStations.first else { return nil }

        let localStation = list.createStation(title: station.title, url: station.url)
        list.append(localStation)

        return (localStation, list)
    }

    /* ****************************************
     *
     * ****************************************/
    private func format(_ str: String, _ font: NSFont) -> NSAttributedString {
        return NSAttributedString(string: str, attributes: [.font: font])
    }

    /* ****************************************
     *
     * ****************************************/
    private func votesInfo() -> NSAttributedString {
        guard let votes = station.votes else { return NSAttributedString(string: "") }

        let res = NSMutableAttributedString()

        switch votes {
            case 0:
                res.append(format(NSLocalizedString("no votes", comment: "Internet station row"), normalFont))

            case 0 ..< 1000:
                res.append(format(NSLocalizedString("votes:", comment: "Internet station row"), smallFont))
                res.append(format(" \(votes)", normalFont))

            case 1000 ..< 1_000_000:
                res.append(format(NSLocalizedString("votes:", comment: "Internet station row"), smallFont))
                res.append(format(" \(votes / 1000)", normalFont))
                res.append(format("k", smallFont))
            default:
                res.append(format(NSLocalizedString("votes:", comment: "Internet station row"), smallFont))
                res.append(format(" \(votes / 10_000_000)", normalFont))
                res.append(format("M", smallFont))
        }
        return res
    }

    /* ****************************************
     *
     * ****************************************/
    private func qualityInfo() -> NSAttributedString {
        let res = NSMutableAttributedString()

        if let codec = station.codec {
            res.append(format(NSLocalizedString("codec:", comment: "Internet station row"), smallFont))
            res.append(format(" \(codec.lowercased())", normalFont))
        }

        if let bitrate = station.bitrate {
            switch bitrate {
                case 0: break

                case 1 ..< 1024:
                    res.append(format(" \(bitrate)b", normalFont))

                default:
                    res.append(format(" \(bitrate / 1024)k", normalFont))
            }
        }
        return res
    }
}
