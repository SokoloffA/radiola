//
//  LocalStationToolBox.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 11.01.2024.
//

import Cocoa

// MARK: - LocalStationToolBox

class LocalStationToolBox: NSView {
    let addStationButton = NSButton()
    let addGroupButton = NSButton()
    let delButton = NSButton()

    private var list: (any StationList)?

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(frame: NSRect.zero)
        addSubview(addStationButton)
        addSubview(addGroupButton)
        addSubview(delButton)

        addStationButton.bezelStyle = .smallSquare
        addStationButton.setButtonType(.momentaryPushIn)
        addStationButton.image = NSImage(systemSymbolName: NSImage.Name("plus.circle"), accessibilityDescription: "Add station")
        addStationButton.title = "Add station"
        addStationButton.imagePosition = .imageLeft
        addStationButton.image?.isTemplate = true
        addStationButton.isBordered = false

        addGroupButton.bezelStyle = .smallSquare
        addGroupButton.setButtonType(.momentaryPushIn)
        addGroupButton.image = NSImage(systemSymbolName: NSImage.Name("plus.circle"), accessibilityDescription: "Add group")
        addGroupButton.title = "Add group"
        addGroupButton.imagePosition = .imageLeft
        addGroupButton.image?.isTemplate = true
        addGroupButton.isBordered = false

        delButton.bezelStyle = .smallSquare
        delButton.setButtonType(.momentaryPushIn)
        delButton.image = NSImage(systemSymbolName: NSImage.Name("minus.circle"), accessibilityDescription: "Delete station")
        delButton.title = "Remove station"
        delButton.imagePosition = .imageLeft
        delButton.image?.isTemplate = true
        delButton.isBordered = false

        addStationButton.translatesAutoresizingMaskIntoConstraints = false
        addGroupButton.translatesAutoresizingMaskIntoConstraints = false
        delButton.translatesAutoresizingMaskIntoConstraints = false

        addStationButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        addGroupButton.heightAnchor.constraint(equalTo: addStationButton.heightAnchor).isActive = true
        delButton.heightAnchor.constraint(equalTo: addStationButton.heightAnchor).isActive = true

        addStationButton.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        addGroupButton.topAnchor.constraint(equalTo: addStationButton.topAnchor).isActive = true
        delButton.topAnchor.constraint(equalTo: addStationButton.topAnchor).isActive = true

        addStationButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        addGroupButton.leadingAnchor.constraint(equalToSystemSpacingAfter: addStationButton.trailingAnchor, multiplier: 1).isActive = true
        delButton.leadingAnchor.constraint(equalToSystemSpacingAfter: addGroupButton.trailingAnchor, multiplier: 3).isActive = true
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
