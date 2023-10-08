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

    weak var stationsView: StationView?
    var provider: SearchProvider? {
        didSet {
            setProvider()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    override func viewDidLoad() {
        super.viewDidLoad()

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

        matchTypeCombo.selectItem(withTag: provider.isExactMatch ? 1 : 0)

        sortCombo.removeAllItems()
        for (i, v) in provider.allOrderTypes.enumerated() {
            sortCombo.addItem(withTitle: v.rawValue)
            sortCombo.lastItem?.tag = i
            if v == provider.order {
                sortCombo.selectItem(withTag: i)
            }
        }

        searchTextView.stringValue = provider.searchText
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func matchTypeChanged() {
        guard var provider = provider else { return }
        provider.isExactMatch = matchTypeCombo.selectedItem?.tag == 1
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func orderTypeChanged() {
        guard var provider = provider else { return }
        let n = sortCombo.selectedItem?.tag ?? 0
        provider.order = provider.allOrderTypes[n]
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func search() {
//        guard let provider = provider else { return }

//        provider.searchText = searchTextView.stringValue
//        provider.isExactMatch = exactButton.state == .on
//
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
