//
//  HistoryDelegate.swift
//  Radiola
//
//  Created by William Entriken on 06.12.2024.
//

import Cocoa

// MARK: - HistoryDelegate

class HistoryDelegate: NSObject {
    private weak var outlineView: NSOutlineView!
    var showOnlyFavorites: Bool = false

    /* ****************************************
     *
     * ****************************************/
    init(outlineView: NSOutlineView) {
        self.outlineView = outlineView
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: Notification.Name.PlayerMetadataChanged,
            object: nil)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func refresh() {
        outlineView?.reloadData()
    }

    /* ****************************************
     *
     * ****************************************/
    private var records: [HistoryRecord] {
        if showOnlyFavorites {
            return AppState.shared.history.favorites()
        }
        return AppState.shared.history.records
    }
}

// MARK: - HistoryDelegate: NSOutlineViewDelegate

extension HistoryDelegate: NSOutlineViewDelegate {
    /* ****************************************
     *
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let record = item as? HistoryRecord else { return nil }
        return HistoryRow(history: record)
    }

    /* ****************************************
     * Variable Row Heights
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        return CGFloat(44.0)
    }
}

// MARK: - HistoryDelegate: NSOutlineViewDataSource

extension HistoryDelegate: NSOutlineViewDataSource {
    /* ****************************************
     * Returns the number of child items each item in the outline
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        // Root item - show records in reverse order (newest first)
        if item == nil {
            return records.count
        }
        return 0
    }

    /* ****************************************
     * Returns the actual item
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        // Root item - return records in reverse order (newest first)
        if item == nil {
            let list = records
            return list[list.count - index - 1]
        }
        return item!
    }

    /* ****************************************
     * We must specify if a given item should be expandable or not.
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
}
