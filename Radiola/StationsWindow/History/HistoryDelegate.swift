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

    // Search and filter properties
    var searchText: String = ""
    var isExactMatch: Bool = false
    var sortOrder: HistorySearchPanel.Order = .byRecent
    var showOnlyFavorites: Bool = false

    // Cached filtered records
    private var filteredRecords: [HistoryRecord] = []

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
        updateFilteredRecords()
        outlineView?.reloadData()
    }

    /* ****************************************
     *
     * ****************************************/
    private func updateFilteredRecords() {
        var records = AppState.shared.history.records

        // Filter by favorites
        if showOnlyFavorites {
            records = records.filter { $0.isFavorite }
        }

        // Filter by search text
        if !searchText.isEmpty {
            records = records.filter { matchesSearch($0) }
        }

        // Sort
        filteredRecords = applySort(records: records)
    }

    /* ****************************************
     *
     * ****************************************/
    private func matchesSearch(_ record: HistoryRecord) -> Bool {
        let searchLower = searchText.lowercased()

        if isExactMatch {
            return record.song.lowercased() == searchLower ||
                   record.stationTitle.lowercased() == searchLower
        } else {
            return record.song.lowercased().contains(searchLower) ||
                   record.stationTitle.lowercased().contains(searchLower)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func applySort(records: [HistoryRecord]) -> [HistoryRecord] {
        switch sortOrder {
        case .byRecent:
            // Newest first (reverse order)
            return records.reversed()
        case .byName:
            return records.sorted { $0.song.localizedCaseInsensitiveCompare($1.song) == .orderedAscending }
        case .byStation:
            return records.sorted { $0.stationTitle.localizedCaseInsensitiveCompare($1.stationTitle) == .orderedAscending }
        }
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
        if item == nil {
            return filteredRecords.count
        }
        return 0
    }

    /* ****************************************
     * Returns the actual item
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil && index < filteredRecords.count {
            return filteredRecords[index]
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
