//
//  LocalStationSearchPanel.swift
//  Radiola
//
//  Created by William Entriken on 06.12.2024.
//

import Cocoa

// MARK: - LocalStationSearchPanel

class LocalStationSearchPanel: NSControl {
    enum Order: Int {
        case myOrdering = 0
        case byName = 1
    }

    private var searchTextView = NSSearchField()
    private var matchTypeCombo = NSPopUpButton()
    private var sortCombo = NSPopUpButton()
    private var separator = Separator()

    var searchText: String { searchTextView.stringValue }
    var isExactMatch: Bool { matchTypeCombo.selectedItem?.tag == 1 }
    var order: Order { Order(rawValue: sortCombo.selectedTag()) ?? .myOrdering }

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
        addSubview(separator)

        searchTextView.sendsSearchStringImmediately = true
        searchTextView.controlSize = .large
        searchTextView.target = self
        searchTextView.action = #selector(searchChanged)

        matchTypeCombo.target = self
        matchTypeCombo.action = #selector(searchChanged)
        matchTypeCombo.isBordered = false

        sortCombo.target = self
        sortCombo.action = #selector(sortChanged)
        sortCombo.isBordered = false

        matchTypeCombo.translatesAutoresizingMaskIntoConstraints = false
        searchTextView.translatesAutoresizingMaskIntoConstraints = false
        sortCombo.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            matchTypeCombo.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchTextView.centerYAnchor.constraint(equalTo: centerYAnchor),
            sortCombo.centerYAnchor.constraint(equalTo: centerYAnchor),

            searchTextView.leadingAnchor.constraint(equalTo: matchTypeCombo.trailingAnchor, constant: 8),
            sortCombo.leadingAnchor.constraint(equalTo: searchTextView.trailingAnchor, constant: 20),
            sortCombo.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            searchTextView.widthAnchor.constraint(equalToConstant: 400),

            matchTypeCombo.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
        ])

        separator.alignBottom(of: self)

        matchTypeCombo.removeAllItems()
        matchTypeCombo.addItem(withTitle: NSLocalizedString("matches with", comment: "Station search panel"), tag: 1)
        matchTypeCombo.addItem(withTitle: NSLocalizedString("contains", comment: "Station search panel"), tag: 0)
        matchTypeCombo.selectItem(withTag: 0)

        sortCombo.removeAllItems()
        sortCombo.addItem(withTitle: NSLocalizedString("my ordering", comment: "Station search panel"), tag: Order.myOrdering.rawValue)
        sortCombo.addItem(withTitle: NSLocalizedString("sort by name", comment: "Station search panel"), tag: Order.byName.rawValue)
        sortCombo.selectItem(withTag: Order.myOrdering.rawValue)
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

    /* ****************************************
     *
     * ****************************************/
    @objc private func sortChanged() {
        guard let target = target, let action = action else { return }
        NSApp.sendAction(action, to: target, from: self)
    }
}
