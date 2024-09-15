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
    let menuButton = StationMenuButton()
    let separator = Separator()

    private let actionButtonIcons = [
        false: NSImage(systemSymbolName: NSImage.Name("music.house"), accessibilityDescription: "")?.tint(color: .lightGray),
        true: NSImage(systemSymbolName: NSImage.Name("music.house.fill"), accessibilityDescription: "")?.tint(color: .systemYellow),
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
        addSubview(menuButton)
        addSubview(urlEdit)
        addSubview(separator)
        addSubview(qualityText)
        addSubview(voteText)

        nameEdit.placeholderString = "Station name"
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

        qualityText.attributedStringValue = qualityInfo()
        qualityText.textColor = .secondaryLabelColor

        voteText.attributedStringValue = votesInfo()
        voteText.textColor = .secondaryLabelColor

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        nameEdit.translatesAutoresizingMaskIntoConstraints = false
        urlEdit.translatesAutoresizingMaskIntoConstraints = false
        qualityText.translatesAutoresizingMaskIntoConstraints = false
        voteText.translatesAutoresizingMaskIntoConstraints = false
        menuButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            actionButton.widthAnchor.constraint(equalToConstant: 16),
            nameEdit.leadingAnchor.constraint(equalTo: leadingAnchor),
            nameEdit.trailingAnchor.constraint(equalTo: actionButton.leadingAnchor, constant: -8),

            menuButton.leadingAnchor.constraint(equalTo: actionButton.trailingAnchor, constant: 8),
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

        refreshActionButton()
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
        guard let list = AppState.shared.localStations.first else { return }
        let inLocal = list.firstStation(byURL: station.url) != nil

        if !inLocal {
            let s = list.createStation(title: station.title, url: station.url)
            list.append(s)
            list.trySave()
            refreshActionButton()
        }
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
                res.append(format("no votes", normalFont))

            case 0 ..< 1000:
                res.append(format("votes:", smallFont))
                res.append(format(" \(votes)", normalFont))

            case 1000 ..< 1000000:
                res.append(format("votes:", smallFont))
                res.append(format(" \(votes / 1000)", normalFont))
                res.append(format("k", smallFont))
            default:
                res.append(format("votes: ", smallFont))
                res.append(format("\(votes / 10000000)", normalFont))
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
            res.append(format("codec: ", smallFont))
            res.append(format(codec.lowercased(), normalFont))
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
