//
//  LocalStationDelegate.swift
//  Radiola
//
//  Created by Alex Sokolov on 07.01.2024.
//

import Cocoa

// MARK: - LocalStationDelegate

class LocalStationDelegate: NSObject {
    private weak var outlineView: NSOutlineView!

    var list: LocalStationList?

    let nodePasteboardType = NSPasteboard.PasteboardType(rawValue: "Station.row")

    /* ****************************************
     *
     * ****************************************/
    init(outlineView: NSOutlineView) {
        self.outlineView = outlineView
        list = nil
    }
}

// MARK: - LocalStationDelegate: NSOutlineViewDelegate

extension LocalStationDelegate: NSOutlineViewDelegate {
    /* ****************************************
     *
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let list = list else { return nil }

        if let station = item as? LocalStation {
            return LocalStationRow(station: station, list: list)
        }

        if let group = item as? LocalStationGroup {
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
        // Root item
        if item == nil {
            return list?.items.count ?? 0
        }

        if let group = item as? LocalStationGroup {
            return group.items.count
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

        if let group = item as? LocalStationGroup {
            return group.items[index]
        }

        return item!
    }

    /* ****************************************
     * We must specify if a given item should be expandable or not.
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let group = item as? LocalStationGroup {
            return !group.items.isEmpty
        }

        return false
    }

    /* ****************************************
     * Variable Row Heights
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if item is LocalStationGroup {
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
        outlineView.registerForDraggedTypes([nodePasteboardType])
        if let station = item as? LocalStation {
            let res = NSPasteboardItem()
            res.setString(station.id.uuidString, forType: nodePasteboardType)
            return res
        }

        if let group = item as? LocalStationGroup {
            let res = NSPasteboardItem()
            res.setString(group.id.uuidString, forType: nodePasteboardType)
            return res
        }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    private func canDragAndDrop(src: LocalStationItem, dest: LocalStationGroup) -> Bool {
        var node: LocalStationGroup? = dest
        while node != nil {
            if node?.id == src.id {
                return false
            }
            node = node?.parent
        }

        return true
    }

    /* ****************************************
     *
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        if info.draggingSource as? NSOutlineView != outlineView {
            return []
        }

        // We forbid insertion into the station node
        if item is LocalStation && index == NSOutlineViewDropOnItemIndex {
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
            let srcId = UUID(uuidString: info.draggingPasteboard.pasteboardItems?.first?.string(forType: nodePasteboardType) ?? ""),
            let srcItem = list.item(byID: srcId),
            let srcParent = srcItem.parent,
            let srcIndex = srcParent.items.firstIndex(where: { $0.id == srcId }),
            let destGroup = item == nil ? list.root : item as? LocalStationGroup
        else {
            return false
        }

        if !canDragAndDrop(src: srcItem, dest: destGroup) {
            return false
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
                return false
            }

            // When you drag an item downwards, the "new row" index is actually --1. Remember dragging operation is `.above`.
            if srcIndex < destIndex {
                destIndex -= 1
            }

            if destIndex == srcIndex {
                return false
            }

            let node = srcParent.items.remove(at: srcIndex)
            destGroup.items.insert(node, at: destIndex)
        }

        list.save()

        // Animate the rows .......................
        outlineView.beginUpdates()
        outlineView.moveItem(
            at: srcIndex,
            inParent: srcParent === list.root ? nil : srcParent,
            to: destIndex,
            inParent: destGroup === list.root ? nil : destGroup
        )
        outlineView.endUpdates()
        outlineView.reloadItem(destGroup)
        outlineView.expandItem(destGroup)

        // stationsStore.dump()
        return true
    }
}

// MARK: - Toolbox

extension LocalStationDelegate {
    /* ****************************************
     *
     * ****************************************/
    func addStation(title: String, url: String) {
        addItem(newItem: LocalStation(title: title, url: url))
    }

    /* ****************************************
     *
     * ****************************************/
    func addGroup(title: String) {
        addItem(newItem: LocalStationGroup(title: title))
    }

    /* ****************************************
     *
     * ****************************************/
    private func addItem(newItem: LocalStationItem) {
        guard let list = list else { return }

        let destItem = outlineView.item(atRow: outlineView.selectedRow)
        // as? LocalStationGroup

        // ::::::::::::::::::::::::::::::
        // No items selected, we append to endo of top items
        if destItem == nil {
            list.root.append(newItem)
        }

        // ::::::::::::::::::::::::::::::
        // A group is selected, we add to its end
        if let group = destItem as? LocalStationGroup {
            group.append(newItem)
        }

        // ::::::::::::::::::::::::::::::
        // A station is selected, we after it
        if let station = destItem as? LocalStation, let group = station.parent {
            group.insert(newItem, afterId: station.id)
        }

        list.save()

        if let index = newItem.parent?.index(newItem.id) {
            outlineView.beginUpdates()
            outlineView.insertItems(
                at: IndexSet(integer: index),
                inParent: newItem.parent !== list.root ? newItem.parent : nil,
                withAnimation: .effectFade
            )
            outlineView.endUpdates()
        }

        outlineView.expandItem(newItem.parent)

        // Select new item
        var row = outlineView.row(forItem: newItem)

        if row > -1 {
            outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            outlineView.scrollRowToVisible(row)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func getParentGroup(item: Any) -> LocalStationGroup? {
        if let station = item as? LocalStation {
            return station.parent
        }

        if let group = item as? LocalStationGroup {
            return group.parent
        }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    func remove(item: Any) {
        guard
            let list = list,
            let parent = getParentGroup(item: item)
        else {
            return
        }
        let index = outlineView.childIndex(forItem: item)

        parent.items.remove(at: index)
        list.save()

        outlineView.beginUpdates()
        outlineView.removeItems(
            at: IndexSet(integer: index),
            inParent: parent !== list.root ? parent : nil,
            withAnimation: .effectFade)
        outlineView.endUpdates()

        let row = parent.items.isEmpty ? outlineView.row(forItem: parent) : outlineView.row(forItem: parent.items[min(index, parent.items.count - 1)])
        outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        outlineView.scrollRowToVisible(row)
    }
}
