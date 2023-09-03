//
//  SearchView.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 29.08.2023.
//

import Cocoa

class SearchView: NSViewController {
    @IBOutlet var searchText: NSSearchField!
    @IBOutlet var searchButton: NSButton!
    @IBOutlet var exactCheckBox: NSButton!
    @IBOutlet var sortComboBox: NSPopUpButton!

    var stationsView: StationView?

    override func viewDidLoad() {
        super.viewDidLoad()

        searchText.target = self
        searchText.action = #selector(search)

        searchButton.target = self
        searchButton.action = #selector(search)
    }

//    override func viewWillDisappear() {
//        print(#function)
//    }

    @objc private func search() {
        Task {
            do {
                let request = RadioBrowser.StationsRequest()
                request.hidebroken = true
                request.order = .votes

                let res = try await request.get(bytag: searchText.stringValue)
                requestDone(res)

            } catch {
                print("Request failed with error: \(error)")
            }
        }
    }

    private func requestDone(_ resp: [RadioBrowser.Station]) {
        print("DONE", resp.count)
        var root = StationGroup(title: "")
        for r in resp {
            var s = Station(title: r.name, url: r.url)
            root.append(s)
        }

        //  stationsView?.stations = root
    }
}
