//
//  SearchView.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 29.08.2023.
//

import Cocoa

extension NSPopUpButton {
    func addItem(withTitle title: String, tag: Int) {
        addItem(withTitle: title)
        lastItem?.tag = tag
    }
}

class SearchPanel: NSViewController {
    @IBOutlet var searchTextView: NSSearchField!
    @IBOutlet var matchTypeCombo: NSPopUpButton!
    @IBOutlet var sortCombo: NSPopUpButton!

    var provider: SearchableStationList? {
        didSet {
            setProvider()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    override func viewDidLoad() {
        super.viewDidLoad()

        searchTextView.sendsWholeSearchString = true
        searchTextView.target = self
        searchTextView.action = #selector(search)

        matchTypeCombo.target = self
        matchTypeCombo.action = #selector(search)

        sortCombo.target = self
        sortCombo.action = #selector(search)

        sortCombo.removeAllItems()
        sortCombo.addItem(withTitle: "sort by votes", tag: SearchOptions.Order.byVotes.rawValue)
        sortCombo.addItem(withTitle: "sort by name", tag: SearchOptions.Order.byName.rawValue)
        sortCombo.addItem(withTitle: "sort by country", tag: SearchOptions.Order.byCountry.rawValue)
        sortCombo.addItem(withTitle: "sort by bitrate", tag: SearchOptions.Order.byBitrate.rawValue)
        sortCombo.selectItem(at: 0)

        setProvider()
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
    private func setProvider() {
        guard let provider = provider else { return }

        matchTypeCombo.selectItem(withTag: provider.searchOptions.isExactMatch ? 1 : 0)
        searchTextView.stringValue = provider.searchOptions.searchText
        sortCombo.selectItem(withTag: provider.searchOptions.order.rawValue)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func search() {
        guard let provider = provider else { return }

        if searchTextView.stringValue.isEmpty {
            return
        }

        provider.searchOptions.searchText = searchTextView.stringValue
        provider.searchOptions.isExactMatch = matchTypeCombo.selectedItem?.tag == 1
        provider.searchOptions.order = SearchOptions.Order(rawValue: sortCombo.selectedTag()) ?? .byVotes

        provider.fetch()
    }
}
