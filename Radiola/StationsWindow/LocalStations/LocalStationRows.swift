//
//  LocalStationRows.swift
//  Radiola
//
//  Created by Alex Sokolov on 08.01.2024.
//

import Cocoa

// MARK: - LocalGroupRow

class LocalGroupRow: NSView {
    private let group: StationGroup
    private let list: any StationList

    private var nameEdit = TextField()
    private let separator = Separator()
    let menuButton = StationGroupMenuButton()

    /* ****************************************
     *
     * ****************************************/
    init(group: StationGroup, list: any StationList) {
        self.group = group
        self.list = list
        menuButton.group = group

        super.init(frame: NSRect())
        addSubview(nameEdit)
        addSubview(separator)
        addSubview(menuButton)

        nameEdit.placeholderString = "Group name"
        nameEdit.isBordered = false
        nameEdit.drawsBackground = false
        if let font = nameEdit.font {
            nameEdit.font = NSFont.systemFont(ofSize: font.pointSize, weight: .medium)
        }

        nameEdit.stringValue = group.title
        nameEdit.target = self
        nameEdit.action = #selector(nameEdited(sender:))
        nameEdit.isEditable = true

        nameEdit.translatesAutoresizingMaskIntoConstraints = false
        nameEdit.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        nameEdit.trailingAnchor.constraint(equalTo: menuButton.leadingAnchor, constant: -8).isActive = true
        nameEdit.topAnchor.constraint(equalTo: topAnchor, constant: 10.0).isActive = true

        menuButton.translatesAutoresizingMaskIntoConstraints = false
        menuButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        menuButton.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        menuButton.widthAnchor.constraint(equalToConstant: 16).isActive = true
        menuButton.heightAnchor.constraint(equalToConstant: 16).isActive = true

        separator.alignBottom(of: self)
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
    @objc func nameEdited(sender: NSTextField) {
        group.title = sender.stringValue
        list.trySave()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func copyTitleToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(group.title, forType: .string)
    }
}

// MARK: - LocalStationRow

class LocalStationRow: NSView, NSTextFieldDelegate {
    private let station: Station
    private let list: any StationList

    var nameEdit = TextField()
    var urlEdit = TextField()
    var favoriteButton = ImageButton()
    let menuButton = StationMenuButton()
    let separator = Separator()

    private let contextMenu = NSMenu(title: "Context")

    private let favoriteIcons = [
        false: NSImage(systemSymbolName: NSImage.Name("star"), accessibilityDescription: "Favorite")?.tint(color: .lightGray),
        true: NSImage(systemSymbolName: NSImage.Name("star.fill"), accessibilityDescription: "Favorite")?.tint(color: .systemYellow),
    ]

    /* ****************************************
     *
     * ****************************************/
    init(station: Station, list: any StationList) {
        self.station = station
        self.list = list
        menuButton.station = station

        super.init(frame: NSRect())
        addSubview(nameEdit)
        addSubview(favoriteButton)
        addSubview(menuButton)
        addSubview(urlEdit)
        addSubview(separator)

        nameEdit.placeholderString = "Station name"
        nameEdit.isBordered = false
        nameEdit.drawsBackground = false
        if let font = nameEdit.font {
            nameEdit.font = NSFont.systemFont(ofSize: font.pointSize, weight: .medium)
        }

        nameEdit.stringValue = station.title
        nameEdit.delegate = self
        nameEdit.isEditable = true

        urlEdit.stringValue = station.url
        urlEdit.font = NSFont.systemFont(ofSize: 11)
        urlEdit.delegate = self
        urlEdit.isEditable = true

        favoriteButton.target = self
        favoriteButton.action = #selector(favClicked(sender:))

        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        favoriteButton.widthAnchor.constraint(equalToConstant: 16).isActive = true
        favoriteButton.heightAnchor.constraint(equalToConstant: 16).isActive = true

        menuButton.translatesAutoresizingMaskIntoConstraints = false
        menuButton.leadingAnchor.constraint(equalTo: favoriteButton.trailingAnchor, constant: 8).isActive = true
        menuButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        menuButton.centerYAnchor.constraint(equalTo: favoriteButton.centerYAnchor).isActive = true
        menuButton.widthAnchor.constraint(equalTo: favoriteButton.widthAnchor).isActive = true
        menuButton.heightAnchor.constraint(equalTo: favoriteButton.heightAnchor).isActive = true

        nameEdit.translatesAutoresizingMaskIntoConstraints = false
        nameEdit.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        nameEdit.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -8).isActive = true
        nameEdit.topAnchor.constraint(equalTo: topAnchor, constant: 6.0).isActive = true

        urlEdit.translatesAutoresizingMaskIntoConstraints = false
        urlEdit.leadingAnchor.constraint(equalTo: nameEdit.leadingAnchor).isActive = true
        urlEdit.trailingAnchor.constraint(equalTo: nameEdit.trailingAnchor).isActive = true
        urlEdit.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5.0).isActive = true
        urlEdit.textColor = .secondaryLabelColor

        separator.alignBottom(of: self)

        refreshFavoriteButton()
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
    @objc private func update() {
        station.title = nameEdit.stringValue
        station.url = urlEdit.stringValue
        list.trySave()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func favClicked(sender: NSButton) {
        station.isFavorite = !station.isFavorite
        list.trySave()
        refreshFavoriteButton()
    }

    /* ****************************************
     *
     * ****************************************/
    private func refreshFavoriteButton() {
        favoriteButton.image = favoriteIcons[station.isFavorite]!
        favoriteButton.toolTip = NSLocalizedString(
            station.isFavorite ? "Unmark station as favorite" : "Mark station as favorite",
            comment: "Station favorite star icon tooltip"
        )
    }

    /* ****************************************
     *
     * ****************************************/
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        update()
        return true
    }
}
