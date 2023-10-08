//
//  StationView.swift
//  Radiola
//
//  Created by Alex Sokolov on 20.08.2023.
//

import Cocoa

class StationView: NSView {
    private let nodePasteboardType = NSPasteboard.PasteboardType(rawValue: "Station.row")
    private(set) var isEditable = false
    private static var selectedRows: [Int: Int] = [:]

    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var stationsTree: NSOutlineView!
    @IBOutlet var addStationButton: NSButton!
    @IBOutlet var removeStationButton: NSButton!
    @IBOutlet var bottomBar: NSView!

    var stations: StationList? {
        didSet {
            isEditable = stations?.isEditable ?? false
            stationsTree.reloadData()

            if let stations = stations {
                let n = StationView.selectedRows[stations.id] ?? max(0, stationsTree.row(forItem: player.station))
                stationsTree.selectRowIndexes(IndexSet(arrayLiteral: n), byExtendingSelection: true)
                stationsTree.scrollRowToVisible(stationsTree.selectedRow)
            }

            refresh()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(frame: NSRect.zero)
        _ = load(fromNIBNamed: "StationView")

        stationsTree.delegate = self
        stationsTree.dataSource = self

        stationsTree.rowHeight = 48

        stationsTree.doubleAction = #selector(doubleClickRow)
        stationsTree.registerForDraggedTypes([nodePasteboardType])
        stationsTree.expandItem(nil, expandChildren: true)

        addStationButton.target = self
        addStationButton.action = #selector(addStation)

        removeStationButton.target = self
        removeStationButton.action = #selector(removeStation)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refresh),
                                               name: Notification.Name.PlayerStatusChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refresh),
                                               name: Notification.Name.PlayerMetadataChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refresh),
                                               name: NSOutlineView.selectionDidChangeNotification,
                                               object: nil)

        refresh()
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /* ****************************************
     *
     * ****************************************/
    override func becomeFirstResponder() -> Bool {
        return scrollView.becomeFirstResponder()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func refresh() {
        let selNode = selectedNode()
        removeStationButton.isEnabled = (selNode != nil)
        addStationButton.isHidden = !isEditable
        removeStationButton.isHidden = !isEditable
    }

    /* ****************************************
     *
     * ****************************************/
    func nodeDidChanged(node: StationNode) {
        guard let stations = stations as? LocalStationList else { return }
        stations.save()
    }

    /* ****************************************
     *
     * ****************************************/
    private func selectedNode() -> StationNode? {
        return stationsTree.item(atRow: stationsTree.selectedRow) as? StationNode
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func doubleClickRow(sender: AnyObject) {
        guard let station = selectedNode() as? Station else { return }

        if player.station?.id == station.id && player.isPlaying {
            return
        }

        player.station = station
        player.play()
    }

    /* ****************************************
     *
     * ****************************************/
    private func addNode(newNode: StationNode) {
        guard let stations = stations as? LocalStationList else { return }
        if !isEditable { return }

        let node = selectedNode()

        // ::::::::::::::::::::::::::::::
        // No items selected, we append to endo of top items
        if node == nil {
            stations.append(newNode)
        }

        // ::::::::::::::::::::::::::::::
        // A group is selected, we add to its end
        if let group = node as? StationGroup {
            group.append(newNode)
        }

        // ::::::::::::::::::::::::::::::
        // A station is selected, we after it
        if let station = node as? Station, let group = station.parent {
            group.insert(newNode, after: station)
        }

        stations.save()

        if let index = newNode.parent?.index(newNode)! {
            stationsTree.beginUpdates()
            stationsTree.insertItems(
                at: IndexSet(integer: index),
                inParent: newNode.parent !== stations ? newNode.parent : nil,
                withAnimation: .effectFade
            )
            stationsTree.endUpdates()
        }

        stationsTree.expandItem(newNode.parent)

        // Select new item
        let row = stationsTree.row(forItem: newNode)
        if row > -1 {
            stationsTree.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func addStation(_ sender: Any) {
        let dialog = AddStationDialog()
        window?.beginSheet(dialog.window!, completionHandler: { response in
            if response != NSApplication.ModalResponse.OK || dialog.url.isEmpty {
                return
            }

            self.addNode(newNode: Station(title: dialog.title, url: dialog.url))
        })
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func addGroup(_ sender: Any) {
        let dialog = AddGroupDialog()
        window?.beginSheet(dialog.window!, completionHandler: { response in
            if response != NSApplication.ModalResponse.OK {
                return
            }

            self.addNode(newNode: StationGroup(title: dialog.title))
        })
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func removeStation(_ sender: Any) {
        guard let stations = stations as? LocalStationList else { return }
        if !isEditable { return }

        guard let wnd = window else { return }
        guard let node = selectedNode() else { return }
        guard let parent = node.parent else { return }

        let alert = NSAlert()
        alert.informativeText = "This operation cannot be undone."
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "Cancel")

        if let station = node as? Station {
            alert.messageText = "Are you sure you want to remove the station \"\(station.title)\"?"
        }

        if let group = node as? StationGroup {
            if group.nodes.isEmpty {
                alert.messageText = "Are you sure you want to remove the group \"\(group.title)\"?"
            } else {
                alert.messageText = "Are you sure you want to remove the group \"\(group.title)\", and all of its children?"
            }
        }

        alert.beginSheetModal(for: wnd, completionHandler: { response in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                let n = parent.index(node) ?? 0
                parent.remove(node)
                stations.save()

                self.stationsTree.beginUpdates()
                self.stationsTree.removeItems(
                    at: IndexSet(integer: n),
                    inParent: parent !== stations ? parent : nil,
                    withAnimation: .effectFade)
                self.stationsTree.endUpdates()
                self.stationsTree.reloadItem(parent !== stations ? parent : nil)

                if !parent.nodes.isEmpty {
                    let row = self.stationsTree.row(forItem: parent.nodes[min(n, parent.nodes.count - 1)])
                    self.stationsTree.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                } else {
                    let row = self.stationsTree.row(forItem: parent)
                    self.stationsTree.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                }
            }
        })
    }
}

/* ****************************************
 *
 * ****************************************/
extension StationView: NSOutlineViewDelegate {
    /* ****************************************
     *
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let group = item as? StationGroup {
            return GroupRowView(group: group, stationView: self)
        }

        if let station = item as? Station {
            return StationRowView(station: station, stationView: self)
        }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let stations = stations else { return }
        StationView.selectedRows[stations.id] = stationsTree.selectedRowIndexes.first
    }
}

/* ****************************************
 *
 * ****************************************/
extension StationView: NSOutlineViewDataSource {
    /* ****************************************
     * Returns the number of child items each item in the outline
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let stations = stations else { return 0 }

        // Root item
        if item == nil {
            return stations.nodes.count
        }

        if let group = item as? StationGroup {
            return group.nodes.count
        }

        return 0
    }

    /* ****************************************
     * Returns the actual item
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let stations = stations else { return item! }

        // Root item
        if item == nil {
            return stations.nodes[index]
        }

        if let group = item as? StationGroup {
            if index < group.nodes.count {
                return group.nodes[index]
            }
        }

        return item!
    }

    /* ****************************************
     * We must specify if a given item should be expandable or not.
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let group = item as? StationGroup {
            return !group.nodes.isEmpty
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
        if !isEditable { return nil }

        let pasteboardItem: NSPasteboardItem = NSPasteboardItem()
        let index: Int = outlineView.row(forItem: item)

        if item is StationNode {
            pasteboardItem.setString(String(index), forType: nodePasteboardType)
        }

        return pasteboardItem
    }

    /* ****************************************
     *
     * ****************************************/
    private func draggedNode(info: NSDraggingInfo) -> StationNode? {
        guard
            let str = info.draggingPasteboard.pasteboardItems?.first?.string(forType: nodePasteboardType),
            let row = Int(str),
            let res = stationsTree.item(atRow: row) as? StationNode
        else {
            return nil
        }

        return res
    }

    /* ****************************************
     *
     * ****************************************/
    private func canDragAndDrop(src: StationNode, dest: StationNode) -> Bool {
        if !isEditable { return false }

        var node: StationNode? = dest
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
        if item is Station && index == NSOutlineViewDropOnItemIndex {
            return []
        }

        return .move
    }

    /* ****************************************
     *
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        guard let stations = stations as? LocalStationList else { return false }
        if !isEditable { return false }

        func getDestParent() -> StationGroup? {
            if item == nil { return stations }
            if let group = item as? StationGroup { return group }
            if let station = item as? Station { return station.parent }
            return nil
        }

        guard
            let srcNode = draggedNode(info: info),
            let srcParent = srcNode.parent,
            let srcIndex = srcParent.index(srcNode),

            let destParent = getDestParent()
        else {
            return false
        }

        if !canDragAndDrop(src: srcNode, dest: destParent) {
            return false
        }

        var destIndex = index
        if srcParent !== destParent {
            let node = srcParent.nodes.remove(at: srcIndex)

            if index > -1 && index < destParent.nodes.count {
                destParent.nodes.insert(node, at: index)
            } else {
                destParent.nodes.append(node)
                destIndex = destParent.nodes.count - 1
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

            let node = srcParent.nodes.remove(at: srcIndex)
            destParent.nodes.insert(node, at: destIndex)
        }

        stations.save()

        // Animate the rows .......................
        outlineView.beginUpdates()
        outlineView.moveItem(
            at: srcIndex,
            inParent: srcParent === stations ? nil : srcParent,
            to: destIndex,
            inParent: destParent === stations ? nil : destParent
        )
        outlineView.endUpdates()
        outlineView.reloadItem(destParent)
        outlineView.expandItem(destParent)

        // stationsStore.dump()
        return true
    }
}
