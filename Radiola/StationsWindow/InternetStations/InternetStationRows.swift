//
//  InternetStationRows.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 15.01.2024.
//

import Cocoa

// MARK: - InternetStationRow

class InternetStationRow: NSView, NSTextFieldDelegate {
    private let station: InternetStation
    private let list: InternetStationList

    var nameEdit = TextField()
    var urlEdit = TextField()
    var favoriteButton = ImageButton()
    let separator = Separator()

    private let favoriteIcons = [
        false: NSImage(named: NSImage.Name("star-empty"))?.tint(color: .lightGray),
        true: NSImage(named: NSImage.Name("star-filled"))?.tint(color: .systemYellow),
    ]

    /* ****************************************
     *
     * ****************************************/
    init(station: InternetStation, list: InternetStationList) {
        self.station = station
        self.list = list

        super.init(frame: NSRect())
        addSubview(nameEdit)
        addSubview(favoriteButton)
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
        nameEdit.isEditable = false

        urlEdit.stringValue = station.url
        urlEdit.font = NSFont.systemFont(ofSize: 11)
        urlEdit.delegate = self
        urlEdit.isEditable = false

        favoriteButton.target = self
        favoriteButton.action = #selector(favClicked(sender:))

        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        favoriteButton.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        favoriteButton.widthAnchor.constraint(equalToConstant: 16).isActive = true
        favoriteButton.heightAnchor.constraint(equalToConstant: 16).isActive = true

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
        //      list.save()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func favClicked(sender: NSButton) {
        // station.isFavorite = !station.isFavorite
//        list.save()
//        refreshFavoriteButton()
    }

    /* ****************************************
     *
     * ****************************************/
    private func refreshFavoriteButton() {
        //    favoriteButton.image = favoriteIcons[station.isFavorite]!
        //    favoriteButton.toolTip = station.isFavorite ? "Unmark the station as a favorite" : "Mark the station as a favorite"
    }

    /* ****************************************
     *
     * ****************************************/
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        update()
        return true
    }
}
