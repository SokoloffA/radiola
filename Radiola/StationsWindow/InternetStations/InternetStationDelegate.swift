//
//  InternetStationsDelegate.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 15.01.2024.
//

import Cocoa

// MARK: - InternetStationDelegate

class InternetStationDelegate: NSObject {
    private weak var outlineView: NSOutlineView!

    var list: InternetStationList?

    /* ****************************************
     *
     * ****************************************/
    init(outlineView: NSOutlineView) {
        self.outlineView = outlineView
        list = nil
    }

    @MainActor
    @objc func search() {
        guard let list = list else { return }
        Task {
            await list.fetch()
            outlineView.reloadData()
        }
    }
}

// MARK: - InternetStationDelegate: NSOutlineViewDelegate

extension InternetStationDelegate: NSOutlineViewDelegate {
    /* ****************************************
     *
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let list = list else { return nil }

        if let station = item as? InternetStation {
            return InternetStationRow(station: station, list: list)
        }

        return nil
    }
}

// MARK: - InternetStationDelegate: NSOutlineViewDataSource

extension InternetStationDelegate: NSOutlineViewDataSource {
    /* ****************************************
     * Returns the number of child items each item in the outline
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        // Root item
        if item == nil {
            return list?.items.count ?? 0
        }

        return 0
    }

    /* ****************************************
     * Returns the actual item
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let list = list else { return "" }

        // Root item
        if item == nil {
            return list.items[index]
        }

        return item!
    }

    /* ****************************************
     * Variable Row Heights
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        return CGFloat(48.0)
    }
}
