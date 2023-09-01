//
//  StationView.swift
//  Radiola
//
//  Created by Alex Sokolov on 20.08.2023.
//

import Cocoa

class StationView: NSView {
    private let nodePasteboardType = NSPasteboard.PasteboardType(rawValue: "Station.row")
    private var searchView: SearchView?

    @IBOutlet var stationsTree: NSOutlineView!
    @IBOutlet var addStationButton: NSButton!
    @IBOutlet var removeStationButton: NSButton!
    @IBOutlet var splitView: NSSplitView!
    @IBOutlet var bottomBar: NSView!
    @IBOutlet var bottomBarHeight: NSLayoutConstraint!

    var stations: Group = Group(name: "") {
        didSet {
            stationsTree.reloadData()
            let n = max(0, stationsTree.row(forItem: player.station))
            stationsTree.selectRowIndexes(IndexSet(arrayLiteral: n), byExtendingSelection: true)
            stationsTree.scrollRowToVisible(stationsTree.selectedRow)
        }
    }

    var item: SideBar.Item? {
        didSet {
            switch item?.type {
            case nil: return
            case .local: showLocalStations(item!)
            case .radioBrowser: showRadioBrowserSearch(item!)
            }
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
    @objc func refresh() {
        let selNode = selectedNode()
        removeStationButton.isEnabled = (selNode != nil)
    }

    /* ****************************************
     *
     * ****************************************/
    func selectedNode() -> StationsStore.Node? {
        return stationsTree.item(atRow: stationsTree.selectedRow) as? StationsStore.Node
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
    private func addNode(newNode: StationsStore.Node) {
        let node = selectedNode()

        // ::::::::::::::::::::::::::::::
        // No items selected, we append to endo of top items
        if node == nil {
            stationsStore.root.append(newNode)
        }

        // ::::::::::::::::::::::::::::::
        // A group is selected, we add to its end
        if let group = node as? Group {
            group.append(newNode)
        }

        // ::::::::::::::::::::::::::::::
        // A station is selected, we after it
        if let station = node as? Station, let group = station.parent() {
            group.insert(newNode, after: station)
        }

        stationsStore.emitChanged()
        stationsStore.write()

        if let index = newNode.parent()?.index(newNode)! {
            stationsTree.beginUpdates()
            stationsTree.insertItems(
                at: IndexSet(integer: index),
                inParent: newNode.parent() !== stationsStore.root ? newNode.parent() : nil,
                withAnimation: .effectFade
            )
            stationsTree.endUpdates()
        }

        stationsTree.expandItem(newNode.parent())

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

            self.addNode(newNode: Station(name: dialog.title, url: dialog.url))
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

            self.addNode(newNode: Group(name: dialog.title))
        })
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func removeStation(_ sender: Any) {
        guard let wnd = window else { return }
        guard let node = selectedNode() else { return }
        guard let parent = node.parent() else { return }

        let alert = NSAlert()
        alert.informativeText = "This operation cannot be undone."
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "Cancel")

        if let station = node as? Station {
            alert.messageText = "Are you sure you want to remove the station \"\(station.name)\"?"
        }

        if let group = node as? Group {
            if group.nodes.isEmpty {
                alert.messageText = "Are you sure you want to remove the group \"\(group.name)\"?"
            } else {
                alert.messageText = "Are you sure you want to remove the group \"\(group.name)\", and all of its children?"
            }
        }

        alert.beginSheetModal(for: wnd, completionHandler: { response in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                let n = parent.index(node) ?? 0
                parent.remove(node)
                stationsStore.emitChanged()
                stationsStore.write()

                self.stationsTree.beginUpdates()
                self.stationsTree.removeItems(
                    at: IndexSet(integer: n),
                    inParent: parent !== stationsStore.root ? parent : nil,
                    withAnimation: .effectFade)
                self.stationsTree.endUpdates()
                self.stationsTree.reloadItem(parent !== stationsStore.root ? parent : nil)

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

    private func showLocalStations(_ item: SideBar.Item) {
        stations = stationsStore.root
        searchView?.view.removeFromSuperview()
        searchView?.removeFromParent()
        searchView = nil
    }

    private func showRadioBrowserSearch(_ item: SideBar.Item) {
        if searchView == nil {
            searchView = SearchView()
            searchView?.stationsView = self
        }

        bottomBarHeight.constant = 0
//        bottomBar.frame.size.height = 200
//        bottomBar.isHidden = true
        searchView!.item = item
        // searchVie
        stations = Group(name: "")
        updateLayer()

        guard let view = searchView?.view else { return }
        splitView.insertArrangedSubview(view, at: 0)
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
        if let group = item as? Group {
            return GroupRowView(group: group)
        }

        if let station = item as? Station {
            return StationRowView(station: station)
        }

        return nil
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
        // Root item
        if item == nil {
            return stations.nodes.count
        }

        if let group = item as? Group {
            return group.nodes.count
        }

        return 0
    }

    /* ****************************************
     * Returns the actual item
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        // Root item
        if item == nil {
            return stations.nodes[index]
        }

        if let group = item as? Group {
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
        if let group = item as? Group {
            return !group.nodes.isEmpty
        }

        return false
    }

    /* ****************************************
     * Variable Row Heights
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if item is Group {
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
        let pasteboardItem: NSPasteboardItem = NSPasteboardItem()
        let index: Int = outlineView.row(forItem: item)

        if item is StationsStore.Node {
            pasteboardItem.setString(String(index), forType: nodePasteboardType)
        }

        return pasteboardItem
    }

    /* ****************************************
     *
     * ****************************************/
    private func draggedNode(info: NSDraggingInfo) -> StationsStore.Node? {
        guard
            let str = info.draggingPasteboard.pasteboardItems?.first?.string(forType: nodePasteboardType),
            let row = Int(str),
            let res = stationsTree.item(atRow: row) as? StationsStore.Node
        else {
            return nil
        }

        return res
    }

    /* ****************************************
     *
     * ****************************************/
    private func canDragAndDrop(src: StationsStore.Node, dest: StationsStore.Node) -> Bool {
        var node: StationsStore.Node? = dest
        while node != nil {
            if node?.id == src.id {
                return false
            }

            node = node?.parent()
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
        func getDestParent() -> Group? {
            if item == nil { return stations }
            if let group = item as? Group { return group }
            if let station = item as? Station { return station.parent() }
            return nil
        }

        guard
            let srcNode = draggedNode(info: info),
            let srcParent = srcNode.parent(),
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

        // stationsStore.emitChanged()
        // stationsStore.write()

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

class StationViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
}