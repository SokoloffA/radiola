//
//  InternetStationSearchPanel.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 15.01.2024.
//

import Cocoa

extension NSPopUpButton {
    func addItem(withTitle title: String, tag: Int) {
        addItem(withTitle: title)
        lastItem?.tag = tag
    }
}

class InternetStationSearchPanel: NSControl {
    var provider: RadioBrowserProvider?
    private var searchTextView = NSSearchField()
    private var matchTypeCombo = NSPopUpButton()
    private var sortCombo = NSPopUpButton()
    private var separator = Separator()

    /* ****************************************
     *
     * ****************************************/
    init(provider: RadioBrowserProvider) {
        self.provider = provider
        super.init(frame: NSRect.zero)

        wantsLayer = true
        layer?.backgroundColor = NSColor.textBackgroundColor.cgColor

        addSubview(matchTypeCombo)
        addSubview(searchTextView)
        addSubview(sortCombo)
        addSubview(separator)

        searchTextView.sendsWholeSearchString = true
        searchTextView.controlSize = .large
        searchTextView.target = self
        searchTextView.action = #selector(search)

        matchTypeCombo.target = self
        matchTypeCombo.action = #selector(search)
        matchTypeCombo.isBordered = false

        sortCombo.target = self
        sortCombo.action = #selector(search)
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

        searchTextView.stringValue = provider.searchText
        searchTextView.target = self
        searchTextView.action = #selector(search)

        matchTypeCombo.removeAllItems()
        matchTypeCombo.addItem(withTitle: exactMatchToString(true), tag: 1)
        matchTypeCombo.addItem(withTitle: exactMatchToString(false), tag: 0)
        matchTypeCombo.target = self
        matchTypeCombo.action = #selector(search)
        matchTypeCombo.selectItem(withTag: provider.isExactMatch ? 1 : 0)

        sortCombo.removeAllItems()
        sortCombo.addItem(withTitle: orderToString(.byVotes), tag: RadioBrowserProvider.Order.byVotes.rawValue)
        sortCombo.addItem(withTitle: orderToString(.byName), tag: RadioBrowserProvider.Order.byName.rawValue)
        sortCombo.addItem(withTitle: orderToString(.byCountry), tag: RadioBrowserProvider.Order.byCountry.rawValue)
        sortCombo.addItem(withTitle: orderToString(.byBitrate), tag: RadioBrowserProvider.Order.byBitrate.rawValue)
        sortCombo.target = self
        sortCombo.action = #selector(search)
        sortCombo.selectItem(withTag: provider.order.rawValue)
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
    override func becomeFirstResponder() -> Bool {
        return searchTextView.becomeFirstResponder()
    }

    /* ****************************************
     *
     * ****************************************/
    private func exactMatchToString(_ value: Bool) -> String {
        return value ?
            NSLocalizedString("matches with", comment: "Internet station search panel") :
            NSLocalizedString("contains", comment: "Internet station search panel")
    }

    /* ****************************************
     *
     * ****************************************/
    private func orderToString(_ order: RadioBrowserProvider.Order) -> String {
        switch order {
            case .byName: return NSLocalizedString("sort by name", comment: "Internet station search panel")
            case .byVotes: return NSLocalizedString("sort by votes", comment: "Internet station search panel")
            case .byCountry: return NSLocalizedString("sort by country", comment: "Internet station search panel")
            case .byBitrate: return NSLocalizedString("sort by bitrate", comment: "Internet station search panel")
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func search() {
        guard let provider = provider else { return }
        provider.searchText = searchTextView.stringValue
        provider.isExactMatch = matchTypeCombo.selectedItem?.tag == 1
        provider.order = RadioBrowserProvider.Order(rawValue: sortCombo.selectedTag()) ?? .byVotes

        if provider.searchText.isEmpty {
            return
        }

        guard
            let target = target,
            let action = action
        else {
            return
        }

        NSApp.sendAction(action, to: target, from: self)
    }
}
