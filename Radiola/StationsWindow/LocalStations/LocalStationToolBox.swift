//
//  LocalStationToolBox.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 11.01.2024.
//

import Cocoa

// MARK: - LocalStationToolBox

class LocalStationToolBox: NSView {
    let addButton = NSButton()
    let delButton = NSButton()

    private var list: LocalStationList?

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(frame: NSRect.zero)
        addSubview(addButton)
        addSubview(delButton)

        addButton.bezelStyle = .smallSquare
        addButton.setButtonType(.momentaryPushIn)
        addButton.image = NSImage(systemSymbolName: NSImage.Name("plus.circle"), accessibilityDescription: "Add station")
        addButton.title = "Add station"
        addButton.imagePosition = .imageLeft
        addButton.image?.isTemplate = true
        addButton.isBordered = false

        delButton.bezelStyle = .smallSquare
        delButton.setButtonType(.momentaryPushIn)
        delButton.image = NSImage(systemSymbolName: NSImage.Name("minus.circle"), accessibilityDescription: "Delete station")
        delButton.title = "Remove station"
        delButton.imagePosition = .imageLeft
        delButton.image?.isTemplate = true
        delButton.isBordered = false

        addButton.translatesAutoresizingMaskIntoConstraints = false
        delButton.translatesAutoresizingMaskIntoConstraints = false

        addButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        delButton.heightAnchor.constraint(equalTo: addButton.heightAnchor).isActive = true

        addButton.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        delButton.topAnchor.constraint(equalTo: addButton.topAnchor).isActive = true

        addButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        delButton.leadingAnchor.constraint(equalToSystemSpacingAfter: addButton.trailingAnchor, multiplier: 1).isActive = true
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
