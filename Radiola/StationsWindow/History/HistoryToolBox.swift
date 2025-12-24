//
//  HistoryToolBox.swift
//  Radiola
//
//  Created by William Entriken on 06.12.2024.
//

import Cocoa

// MARK: - HistoryToolBox

class HistoryToolBox: NSView {
    let exportButton = NSButton()

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(frame: NSRect())

        addSubview(exportButton)

        exportButton.bezelStyle = .smallSquare
        exportButton.setButtonType(.momentaryPushIn)
        exportButton.title = NSLocalizedString("Export…", comment: "History export button")
        exportButton.image = NSImage(systemSymbolName: NSImage.Name("arrowshape.down.circle"), accessibilityDescription: exportButton.title)
        exportButton.imagePosition = .imageLeft
        exportButton.image?.isTemplate = true
        exportButton.isBordered = false

        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        exportButton.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        exportButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
