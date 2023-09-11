//
//  SearchView.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 29.08.2023.
//

import Cocoa

class SearchView: NSViewController {
    @IBOutlet var searchTextView: NSSearchField!
    @IBOutlet var exactButton: NSButton!
    @IBOutlet var sortComboBox: NSPopUpButton!

    weak var stationsView: StationView?
    var provider: RadioBrowserProvider? {
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

        exactButton.target = self
        exactButton.action = #selector(exactButtonClicked)

        setProvider()
    }

    /* ****************************************
     *
     * ****************************************/
    private func setProvider() {
        guard let provider = provider else { return }
        if isViewLoaded {
            searchTextView.stringValue = provider.searchText
            exactButton.state = provider.isExactMatch ? .on : .off
            exactButtonClicked()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func exactButtonClicked() {
        if exactButton.state == .on {
            exactButton.image = NSImage(systemSymbolName: NSImage.Name("checkmark"), accessibilityDescription: "")
            exactButton.image?.isTemplate = true
        } else {
            exactButton.image = nil
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func search() {
        guard let provider = provider else { return }

        provider.searchText = searchTextView.stringValue
        provider.isExactMatch = exactButton.state == .on

        Task {
            do {
                print(#function, #line)
                try await provider.fetch()
                print(#function, #line)
                //        stationsView?.stations = res
                await MainActor.run {
                    self.stationsView?.stations = provider.stations
                }
            } catch {
                print(#function, #line)
                print("Request failed with error: \(error)")
            }
        }
    }
}
