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
    @IBOutlet var infoLabel: NSTextField!

    private let favoriteIcons = [
        false: NSImage(named: NSImage.Name("star-empty"))?.tint(color: .lightGray),
        true: NSImage(named: NSImage.Name("star-filled"))?.tint(color: .systemYellow),
    ]

    private let station: Station
    private weak var stationView: StationView!

    /* ****************************************
     *
     * ****************************************/
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

        infoLabel.attributedStringValue = AdditionaLinfo(station: station).string()
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

internal struct AdditionaLinfo {
    let station: Station
    let normalFont = NSFont.systemFont(ofSize: 11)
    let smallFont = NSFont.systemFont(ofSize: 10)

    /* ****************************************
     *
     * ****************************************/
    func string() -> NSAttributedString {
        let res = NSMutableAttributedString()
        for f in [votesInfo, qualityInfo] {
            let s = f()
            if !s.string.isEmpty {
                if !res.string.isEmpty {
                    res.append(NSAttributedString(string: "    "))
                }
                res.append(s)
            }
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
    private func format(_ str: String, _ font: NSFont) -> NSAttributedString {
        return NSAttributedString(string: str, attributes: [.font: font])
    }
}
