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
    private var sortCombo = NSPopUpButton()
    private var separator = Separator()

    var searchText: String { searchTextView.stringValue }
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
        setBackgroundColor(NSColor.textBackgroundColor)

        addSubview(searchTextView)
        addSubview(sortCombo)
        addSubview(separator)

        searchTextView.sendsSearchStringImmediately = true
        searchTextView.controlSize = .large
        searchTextView.target = self
        searchTextView.action = #selector(searchChanged)

        sortCombo.target = self
        sortCombo.action = #selector(sortChanged)
        sortCombo.isBordered = false

        searchTextView.translatesAutoresizingMaskIntoConstraints = false
        sortCombo.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchTextView.centerYAnchor.constraint(equalTo: centerYAnchor),
            sortCombo.centerYAnchor.constraint(equalTo: centerYAnchor),

            searchTextView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            sortCombo.leadingAnchor.constraint(equalTo: searchTextView.trailingAnchor, constant: 20),
            sortCombo.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),

            searchTextView.widthAnchor.constraint(equalToConstant: 400),
        ])

        sortCombo.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        separator.alignBottom(of: self)

        sortCombo.removeAllItems()
        sortCombo.addItem(withTitle: NSLocalizedString("my ordering", comment: "Station search panel"), tag: Order.myOrdering.rawValue)
        sortCombo.addItem(withTitle: NSLocalizedString("sort by name", comment: "Station search panel"), tag: Order.byName.rawValue)
        sortCombo.selectItem(withTag: Order.myOrdering.rawValue)
    }

    /* ****************************************
     *
     * ****************************************/
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        setBackgroundColor(NSColor.textBackgroundColor)
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
