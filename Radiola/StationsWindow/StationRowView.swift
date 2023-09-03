//
//  RowView.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 22.06.2022.
//  Copyright © 2022 Alex Sokolov. All rights reserved.
//

import Cocoa

class StationRowView: NSView {
    @IBOutlet var contentView: NSView!
    @IBOutlet var nameEdit: NSTextField!
    @IBOutlet var urledit: NSTextField!
    @IBOutlet var favoriteButton: NSButton!

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
        nameEdit.isEditable = stationView.isEditable

        urledit.stringValue = station.url
        urledit.tag = station.id
        urledit.target = self
        urledit.action = #selector(urlEdited(sender:))
        urledit.isEditable = stationView.isEditable

        favoriteButton.tag = station.id
        favoriteButton.image = favoriteIcons[station.isFavorite]!
        favoriteButton.target = self
        favoriteButton.action = #selector(favClicked(sender:))
        favoriteButton.isHidden = !stationView.isEditable
    }

    required init?(coder: NSCoder) {
        station = Station(title: "", url: "")
        super.init(coder: coder)
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
