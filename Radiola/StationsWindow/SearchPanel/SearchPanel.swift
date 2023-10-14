//
//  SearchView.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 29.08.2023.
//

import Cocoa

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
        matchTypeCombo.action = #selector(matchTypeChanged)

        sortCombo.target = self
        sortCombo.action = #selector(orderTypeChanged)

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

        sortCombo.removeAllItems()
        for (i, v) in provider.searchOptions.allOrderTypes.enumerated() {
            sortCombo.addItem(withTitle: orderTitle(forOrder: v))
            sortCombo.lastItem?.tag = i
            if v == provider.searchOptions.order {
                sortCombo.selectItem(withTag: i)
            }
        }

        searchTextView.stringValue = provider.searchOptions.searchText
    }

    /* ****************************************
     *
     * ****************************************/
    private func orderTitle(forOrder: SearchOptions.Order) -> String {
        switch forOrder {
            case .byName: return "sort by name"
            case .byVotes: return "sort by votes"
            case .byCountry: return "sort by country"
            case .byBitrate: return "sort by bitrate"
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func matchTypeChanged() {
        guard let provider = provider else { return }
        provider.searchOptions.isExactMatch = matchTypeCombo.selectedItem?.tag == 1
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func orderTypeChanged() {
        guard let provider = provider else { return }
        let n = sortCombo.selectedItem?.tag ?? 0
        provider.searchOptions.order = provider.searchOptions.allOrderTypes[n]
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
        let n = sortCombo.selectedItem?.tag ?? 0
        provider.searchOptions.order = provider.searchOptions.allOrderTypes[n]

        provider.fetch()
//        provider
//        Task {
//            do {
//                print(#function, #line)
//                try await provider.fetch()
//                print(#function, #line)
//                //        stationsView?.stations = res
//                await MainActor.run {
//                    self.stationsView?.stations = provider.stations
//                }
//            } catch {
//                print(#function, #line)
//                print("Request failed with error: \(error)")
//            }
//        }
    }
}
