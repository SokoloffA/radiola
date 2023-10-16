//
//  RowView.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 22.06.2022.
//  Copyright © 2022 Alex Sokolov. All rights reserved.
//

import Cocoa

class StationRowView: NSView, NSTextFieldDelegate {
    @IBOutlet var contentView: NSView!
    @IBOutlet var nameEdit: NSTextField!
    @IBOutlet var urledit: NSTextField!
    @IBOutlet var favoriteButton: NSButton!
    @IBOutlet var bitrateLabel: NSTextField!

    private let favoriteIcons = [
        false: NSImage(named: NSImage.Name("star-empty"))?.tint(color: .lightGray),
        true: NSImage(named: NSImage.Name("star-filled"))?.tint(color: .systemYellow),
    ]

    private let station: Station
    private weak var stationView: StationView!

    init(station: Station, stationView: StationView) {
        self.station = station
        self.stationView = stationView
        super.init(frame: NSRect.zero)
        _ = load(fromNIBNamed: "StationRowView")

        nameEdit.stringValue = station.title
        nameEdit.tag = station.id
        nameEdit.target = self
        nameEdit.action = #selector(nameEdited(sender:))
        nameEdit.delegate = self
        nameEdit.isEditable = true

        urledit.stringValue = station.url
        urledit.tag = station.id
        urledit.target = self
        urledit.action = #selector(urlEdited(sender:))
        urledit.delegate = self
        urledit.isEditable = true

        favoriteButton.tag = station.id
        favoriteButton.image = favoriteIcons[station.isFavorite]!
        favoriteButton.target = self
        favoriteButton.action = #selector(favClicked(sender:))
        favoriteButton.isHidden = !stationView.isEditable

        bitrateLabel.stringValue = additionalInfo(station: station)
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        station = Station(title: "", url: "")
        super.init(coder: coder)
    }

    /* ****************************************
     *
     * ****************************************/
    func control(_ control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
        return stationView.isEditable
    }

    /* ****************************************
     *
     * ****************************************/
    private func additionalInfo(station: Station) -> String {
        var res: [String] = []

        if let votes = station.votes {
            switch votes {
                case 0: res.append("no votes")
                case 0 ..< 1000: res.append("votes: \(votes)")
                case 1000 ..< 1000000: res.append("votes: \(votes / 1000)k")
                default: res.append("votes: \(votes / 1000 / 1000)M")
            }
        }

        if let bitrate = station.bitrate {
            switch bitrate {
                case 0: res.append("unknown bitrate")
                case 1 ..< 1024: res.append("bitrate: \(bitrate)b")
                default: res.append("  bitrate: \(bitrate / 1024)k")
            }
        }

        return res.joined(separator: "  ")
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func nameEdited(sender: NSTextField) {
        station.title = sender.stringValue
        stationView.nodeDidChanged(node: station)
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction private func urlEdited(sender: NSTextField) {
        station.url = sender.stringValue
        stationView.nodeDidChanged(node: station)
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction private func favClicked(sender: NSButton) {
        station.isFavorite = !station.isFavorite
        sender.image = favoriteIcons[station.isFavorite]!
        stationView.nodeDidChanged(node: station)
    }
}
