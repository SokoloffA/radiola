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

        exportButton.bezelStyle = .accessoryBarAction
        exportButton.title = NSLocalizedString("Export…", comment: "History export button")
        exportButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        addSubview(exportButton)

        exportButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            exportButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            exportButton.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
