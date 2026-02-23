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
    private var sortCombo = NSPopUpButton()
    private var onlyFavoriteCheckbox = Checkbox()
    private var separator = Separator()

    var searchText: String { searchTextView.stringValue }
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
        setBackgroundColor(NSColor.textBackgroundColor)

        addSubview(searchTextView)
        addSubview(sortCombo)
        addSubview(onlyFavoriteCheckbox)
        addSubview(separator)

        searchTextView.sendsSearchStringImmediately = true
        searchTextView.controlSize = .large
        searchTextView.target = self
        searchTextView.action = #selector(searchChanged)

        sortCombo.target = self
        sortCombo.action = #selector(searchChanged)
        sortCombo.isBordered = false

        onlyFavoriteCheckbox.title = NSLocalizedString("favorites only", comment: "History search panel")
        onlyFavoriteCheckbox.target = self
        onlyFavoriteCheckbox.action = #selector(searchChanged)

        searchTextView.translatesAutoresizingMaskIntoConstraints = false
        sortCombo.translatesAutoresizingMaskIntoConstraints = false
        onlyFavoriteCheckbox.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchTextView.centerYAnchor.constraint(equalTo: centerYAnchor),
            sortCombo.centerYAnchor.constraint(equalTo: centerYAnchor),
            onlyFavoriteCheckbox.centerYAnchor.constraint(equalTo: centerYAnchor),

            searchTextView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            sortCombo.leadingAnchor.constraint(equalTo: searchTextView.trailingAnchor, constant: 20),
            onlyFavoriteCheckbox.leadingAnchor.constraint(equalTo: sortCombo.trailingAnchor, constant: 20),
            onlyFavoriteCheckbox.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),

            searchTextView.widthAnchor.constraint(equalToConstant: 300),
        ])

        sortCombo.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        separator.alignBottom(of: self)

        sortCombo.removeAllItems()
        sortCombo.addItem(withTitle: NSLocalizedString("sort by recent", comment: "History search panel"), tag: Order.byRecent.rawValue)
        sortCombo.addItem(withTitle: NSLocalizedString("sort by name", comment: "History search panel"), tag: Order.byName.rawValue)
        sortCombo.addItem(withTitle: NSLocalizedString("sort by station", comment: "History search panel"), tag: Order.byStation.rawValue)
        sortCombo.selectItem(withTag: Order.byRecent.rawValue)
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
}
