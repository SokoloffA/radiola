//
//  HistoryToolBox.swift
//  Radiola
//
//  Created by William Entriken on 06.12.2024.
//

import Cocoa

// MARK: - HistoryToolBox

class HistoryToolBox: NSView {
    let onlyFavoriteCheckbox = Checkbox()
    let exportButton = NSButton()

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(frame: NSRect())

        onlyFavoriteCheckbox.title = NSLocalizedString("Show only your favorite songs", comment: "History window checkbox title")

        exportButton.bezelStyle = .accessoryBarAction
        exportButton.title = NSLocalizedString("Export…", comment: "History export button")
        exportButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        addSubview(onlyFavoriteCheckbox)
        addSubview(exportButton)

        onlyFavoriteCheckbox.translatesAutoresizingMaskIntoConstraints = false
        exportButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            onlyFavoriteCheckbox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            onlyFavoriteCheckbox.centerYAnchor.constraint(equalTo: centerYAnchor),

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
