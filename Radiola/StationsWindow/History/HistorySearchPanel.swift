//
//  HistorySearchPanel.swift
//  Radiola
//
//  Created by William Entriken on 06.12.2024.
//

import Cocoa

// MARK: - HistorySearchPanel

class HistorySearchPanel: NSControl {
    enum Order: Int {
        case byRecent = 0
        case byName = 1
        case byStation = 2
    }

    private var searchTextView = NSSearchField()
    private var matchTypeCombo = NSPopUpButton()
    private var sortCombo = NSPopUpButton()
    private var onlyFavoriteCheckbox = Checkbox()
    private var separator = Separator()

    var searchText: String { searchTextView.stringValue }
    var isExactMatch: Bool { matchTypeCombo.selectedItem?.tag == 1 }
    var order: Order { Order(rawValue: sortCombo.selectedTag()) ?? .byRecent }
    var showOnlyFavorites: Bool { onlyFavoriteCheckbox.state == .on }

    /* ****************************************
     *
     * ****************************************/
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
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
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.textBackgroundColor.cgColor

        addSubview(matchTypeCombo)
        addSubview(searchTextView)
        addSubview(sortCombo)
        addSubview(onlyFavoriteCheckbox)
        addSubview(separator)

        searchTextView.sendsSearchStringImmediately = true
        searchTextView.controlSize = .large
        searchTextView.target = self
        searchTextView.action = #selector(searchChanged)

        matchTypeCombo.target = self
        matchTypeCombo.action = #selector(searchChanged)
        matchTypeCombo.isBordered = false

        sortCombo.target = self
        sortCombo.action = #selector(searchChanged)
        sortCombo.isBordered = false

        onlyFavoriteCheckbox.title = NSLocalizedString("Favorites only", comment: "History search panel")
        onlyFavoriteCheckbox.target = self
        onlyFavoriteCheckbox.action = #selector(searchChanged)

        matchTypeCombo.translatesAutoresizingMaskIntoConstraints = false
        searchTextView.translatesAutoresizingMaskIntoConstraints = false
        sortCombo.translatesAutoresizingMaskIntoConstraints = false
        onlyFavoriteCheckbox.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            matchTypeCombo.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchTextView.centerYAnchor.constraint(equalTo: centerYAnchor),
            sortCombo.centerYAnchor.constraint(equalTo: centerYAnchor),
            onlyFavoriteCheckbox.centerYAnchor.constraint(equalTo: centerYAnchor),

            matchTypeCombo.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            searchTextView.leadingAnchor.constraint(equalTo: matchTypeCombo.trailingAnchor, constant: 8),
            sortCombo.leadingAnchor.constraint(equalTo: searchTextView.trailingAnchor, constant: 20),
            onlyFavoriteCheckbox.leadingAnchor.constraint(equalTo: sortCombo.trailingAnchor, constant: 20),
            onlyFavoriteCheckbox.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            searchTextView.widthAnchor.constraint(equalToConstant: 300),
        ])

        separator.alignBottom(of: self)

        matchTypeCombo.removeAllItems()
        matchTypeCombo.addItem(withTitle: NSLocalizedString("matches with", comment: "History search panel"), tag: 1)
        matchTypeCombo.addItem(withTitle: NSLocalizedString("contains", comment: "History search panel"), tag: 0)
        matchTypeCombo.selectItem(withTag: 0)

        sortCombo.removeAllItems()
        sortCombo.addItem(withTitle: NSLocalizedString("sort by recent", comment: "History search panel"), tag: Order.byRecent.rawValue)
        sortCombo.addItem(withTitle: NSLocalizedString("sort by name", comment: "History search panel"), tag: Order.byName.rawValue)
        sortCombo.addItem(withTitle: NSLocalizedString("sort by station", comment: "History search panel"), tag: Order.byStation.rawValue)
        sortCombo.selectItem(withTag: Order.byRecent.rawValue)
    }

    /* ****************************************
     *
     * ****************************************/
    override func becomeFirstResponder() -> Bool {
        return searchTextView.becomeFirstResponder()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func searchChanged() {
        guard let target = target, let action = action else { return }
        NSApp.sendAction(action, to: target, from: self)
    }
}
