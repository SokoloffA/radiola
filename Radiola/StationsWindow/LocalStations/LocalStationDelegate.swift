//
//  LocalStationDelegate.swift
//  Radiola
//
//  Created by Alex Sokolov on 07.01.2024.
//

import Cocoa

// MARK: - FilteredGroup

/// A wrapper for StationGroup that holds filtered children for display during search
private class FilteredGroup: StationGroup {
    let original: StationGroup
    var filteredItems: [StationItem]

    var id: UUID { original.id }
    var title: String {
        get { original.title }
        set { original.title = newValue }
    }
    var items: [StationItem] {
        get { filteredItems }
        set { filteredItems = newValue }
    }

    init(original: StationGroup, filteredItems: [StationItem]) {
        self.original = original
        self.filteredItems = filteredItems
    }
}

// MARK: - LocalStationDelegate

class LocalStationDelegate: NSObject {
    private weak var outlineView: NSOutlineView!

    var list: (any StationList)?

    // Search and filter properties
    var searchText: String = ""
    var isExactMatch: Bool = false
    var sortOrder: LocalStationSearchPanel.Order = .myOrdering

    // Cached filtered items
    private var filteredItems: [StationItem] = []

    /* ****************************************
     *
     * ****************************************/
    init(outlineView: NSOutlineView) {
        self.outlineView = outlineView
        list = nil
    }

    /* ****************************************
     *
     * ****************************************/
    func refresh() {
        updateFilteredItems()
        outlineView?.reloadData()
        outlineView?.expandItem(nil, expandChildren: true)
    }

    /* ****************************************
     *
     * ****************************************/
    private func updateFilteredItems() {
        guard let list = list else {
            filteredItems = []
            return
        }

        if searchText.isEmpty {
            filteredItems = applySort(items: Array(list.items))
        } else {
            filteredItems = applySort(items: filterItems(list.items))
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func filterItems(_ items: [StationItem]) -> [StationItem] {
        var result: [StationItem] = []

        for item in items {
            if let station = item as? Station {
                if matchesSearch(station.title) {
                    result.append(station)
                }
            } else if let group = item as? StationGroup {
                let filteredChildren = filterItems(group.items)
                if !filteredChildren.isEmpty || matchesSearch(group.title) {
                    // Create a filtered copy of the group
                    let filteredGroup = FilteredGroup(original: group, filteredItems: filteredChildren)
                    result.append(filteredGroup)
                }
            }
        }

        return result
    }

    /* ****************************************
     *
     * ****************************************/
    private func matchesSearch(_ text: String) -> Bool {
        if isExactMatch {
            // "Matches with" - whole word match (search term appears as a complete word)
            return matchesWholeWord(text, searchText)
        } else {
            // "Contains" - substring match
            return text.lowercased().contains(searchText.lowercased())
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func matchesWholeWord(_ text: String, _ word: String) -> Bool {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return text.lowercased().contains(word.lowercased())
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }

    /* ****************************************
     *
     * ****************************************/
    private func applySort(items: [StationItem]) -> [StationItem] {
        switch sortOrder {
        case .myOrdering:
            return items
        case .byName:
            return items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    var isFiltering: Bool {
        return !searchText.isEmpty || sortOrder != .myOrdering
    }

    /* ****************************************
     *
     * ****************************************/
    private func currentItems(for item: Any?) -> [StationItem] {
        if isFiltering {
            if item == nil {
                return filteredItems
            } else if let filteredGroup = item as? FilteredGroup {
                return filteredGroup.filteredItems
            } else if let group = item as? StationGroup {
                return applySort(items: Array(group.items))
            }
        } else {
            if item == nil {
                return list?.items ?? []
            } else if let group = item as? StationGroup {
                return Array(group.items)
            }
        }
        return []
    }
}

// MARK: - LocalStationDelegate: NSOutlineViewDelegate

extension LocalStationDelegate: NSOutlineViewDelegate {
    /* ****************************************
     *
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let list = list else { return nil }

        if let station = item as? Station {
            return LocalStationRow(station: station, list: list)
        }

        if let group = item as? StationGroup {
            return LocalGroupRow(group: group, list: list)
        }

        return nil
    }
}

// MARK: - LocalStationDelegate: NSOutlineViewDataSource

extension LocalStationDelegate: NSOutlineViewDataSource {
    /* ****************************************
     * Returns the number of child items each item in the outline
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return currentItems(for: item).count
    }

    /* ****************************************
     * Returns the actual item
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        let items = currentItems(for: item)
        guard index < items.count else { return "" }
        return items[index]
    }

    /* ****************************************
     * We must specify if a given item should be expandable or not.
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if item is StationGroup {
            return !currentItems(for: item).isEmpty
        }

        return false
    }

    /* ****************************************
     * Variable Row Heights
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if item is StationGroup {
            return CGFloat(38.0)
        }

        return CGFloat(48.0)
    }
}

// MARK: - Drag'N'Drop

extension LocalStationDelegate {
    /* ****************************************
     *
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any]) {
        outlineView.draggingDestinationFeedbackStyle = .regular
    }

    /* ****************************************
     *
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        outlineView.draggingDestinationFeedbackStyle = .none
    }

    /* ****************************************
     *
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        // Disable drag when filtering or sorting by name
        if isFiltering {
            return nil
        }

        outlineView.registerForDraggedTypes([StationItemPasteboardType])
        if let station = item as? Station {
            let res = NSPasteboardItem()
            res.setString(station.id.uuidString, forType: StationItemPasteboardType)
            return res
        }

        if let group = item as? StationGroup {
            let res = NSPasteboardItem()
            res.setString(group.id.uuidString, forType: StationItemPasteboardType)
            return res
        }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    private func canDragAndDrop(src: StationItem, dest: StationGroup) -> Bool {
        // Disable drag when filtering or sorting by name
        if isFiltering {
            return false
        }

        var node: StationGroup? = dest
        while node != nil {
            if node?.id == src.id {
                return false
            }
            node = list?.itemParent(item: node!)
        }

        return true
    }

    /* ****************************************
     *
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        // Disable drop when filtering or sorting by name
        if isFiltering {
            return []
        }

        if info.draggingSource as? NSOutlineView != outlineView {
            return []
        }

        // We forbid insertion into the station node
        if item is Station && index == NSOutlineViewDropOnItemIndex {
            return []
        }

        return .move
    }

    /* ****************************************
     *
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        guard
            let list = list,
            let pasteboardItems = info.draggingPasteboard.pasteboardItems
        else {
            return false
        }

        for pasteboardItem in pasteboardItems {
            guard
                let srcId = UUID(uuidString: pasteboardItem.string(forType: StationItemPasteboardType) ?? ""),
                let srcItem = list.item(byID: srcId),
                let destGroup = item == nil ? list : item as? StationGroup
            else {
                return false
            }

            if !canDragAndDrop(src: srcItem, dest: destGroup) {
                return false
            }
        }

        outlineView.beginUpdates()
        var destIndex = index
        for pasteboardItem in pasteboardItems /* .reversed() */ {
            destIndex = moveItem(pasteboardItem: pasteboardItem, item: item, childIndex: destIndex)
            if destIndex < 0 {
                outlineView.endUpdates()
                return false
            }
            destIndex += 1
        }
        outlineView.endUpdates()

        return true
    }

    /* ****************************************
     *
     * ****************************************/
    private func moveItem(pasteboardItem: NSPasteboardItem, item: Any?, childIndex index: Int) -> Int {
        guard
            let list = list,
            let srcId = UUID(uuidString: pasteboardItem.string(forType: StationItemPasteboardType) ?? ""),
            let srcItem = list.item(byID: srcId),
            let srcParent = list.itemParent(item: srcItem),
            let srcIndex = srcParent.items.firstIndex(where: { $0.id == srcId }),
            let destGroup = item == nil ? list : item as? StationGroup
        else {
            return -1
        }

        var destIndex = index
        if srcParent !== destGroup {
            let node = srcParent.items.remove(at: srcIndex)

            if index > -1 && index < destGroup.items.count {
                destGroup.items.insert(node, at: index)
            } else {
                destGroup.items.append(node)
                destIndex = destGroup.items.count - 1
            }
        } else {
            if destIndex == NSOutlineViewDropOnItemIndex {
                return -1
            }

            // When you drag an item downwards, the "new row" index is actually --1. Remember dragging operation is `.above`.
            if srcIndex < destIndex {
                destIndex -= 1
            }

            if destIndex == srcIndex {
                return -1
            }

            let node = srcParent.items.remove(at: srcIndex)
            destGroup.items.insert(node, at: destIndex)
        }

        list.trySave()

        // Animate the rows .......................
        outlineView.beginUpdates()
        outlineView.moveItem(
            at: srcIndex,
            inParent: srcParent === list ? nil : srcParent,
            to: destIndex,
            inParent: destGroup === list ? nil : destGroup
        )
        outlineView.endUpdates()
        outlineView.reloadItem(destGroup)
        outlineView.expandItem(destGroup)

        // stationsStore.dump()
        return destIndex
    }
}

// MARK: - Toolbox

extension LocalStationDelegate {
    /* ****************************************
     *
     * ****************************************/
    func addStation(title: String, url: String) {
        if let list = list {
            addItem(list.createStation(title: title, url: url))
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func addGroup(title: String) {
        if let list = list {
            addItem(list.createGroup(title: title))
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func addItem(_ newItem: StationItem) {
        guard let list = list else { return }

        let destItem = outlineView.item(atRow: outlineView.selectedRow)
        // as? LocalStationGroup

        // ::::::::::::::::::::::::::::::
        // No items selected, we append to endo of top items
        if destItem == nil {
            list.items.append(newItem)
        }

        // ::::::::::::::::::::::::::::::
        // A group is selected, we add to its end
        if let group = destItem as? StationGroup {
            group.append(newItem)
        }

        // ::::::::::::::::::::::::::::::
        // A station is selected, we after it
        if let station = destItem as? Station {
            let group = list.itemParent(item: station) ?? list
            group.insert(newItem, afterId: station.id)
        }

        list.trySave()

        let newItemParent = list.itemParent(item: newItem)

        if let index = newItemParent?.index(newItem.id) {
            outlineView.beginUpdates()
            outlineView.insertItems(
                at: IndexSet(integer: index),
                inParent: newItemParent !== list ? newItemParent : nil,
                withAnimation: .effectFade
            )
            outlineView.endUpdates()
        }

        outlineView.expandItem(newItemParent)

        // Select new item
        let row = outlineView.row(forItem: newItem)

        if row > -1 {
            outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            outlineView.scrollRowToVisible(row)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func remove(indexes: IndexSet) {
        guard let list = list else { return }

        var itemsToRemove: [StationItem] = []
        for index in indexes {
            guard let item = outlineView.item(atRow: index) as? StationItem else { return }
            itemsToRemove.append(item)
        }

        outlineView.beginUpdates()
        for item in itemsToRemove {
            guard let parent = list.itemParent(item: item) else { continue }
            let index = outlineView.childIndex(forItem: item)
            if index < 0 { continue }

            outlineView.removeItems(
                at: IndexSet(integer: index),
                inParent: parent !== list ? parent : nil,
                withAnimation: .effectFade)
        }
        outlineView.endUpdates()

        for item in itemsToRemove {
            guard
                let parent = list.itemParent(item: item),
                let index = parent.index(item.id)
            else {
                continue
            }
            debug("Remove \(item.title)")
            parent.items.remove(at: index)
        }
        list.trySave()

        guard
            let idx = indexes.first,
            let item = outlineView.item(atRow: idx) as? StationItem,
            let parent = list.itemParent(item: item)
        else {
            return
        }
        let index = outlineView.childIndex(forItem: item)
        let row = parent.items.isEmpty ? outlineView.row(forItem: parent) : outlineView.row(forItem: parent.items[min(index, parent.items.count - 1)])
        outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        outlineView.scrollRowToVisible(row)
    }
}
