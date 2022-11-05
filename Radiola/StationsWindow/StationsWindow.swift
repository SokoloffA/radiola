//
//  StationsWindow.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 05.07.2022.
//

import Cocoa

let stationPasteboardType = NSPasteboard.PasteboardType(rawValue: "Station.row")

class StationsWindow: NSWindowController, NSWindowDelegate {
    @IBOutlet var stationsView: NSOutlineView!
    @IBOutlet var playButton: NSButton!
    @IBOutlet var songLabel: NSTextField!
    @IBOutlet var stationLabel: NSTextField!
    @IBOutlet var addStationButton: NSButton!
    @IBOutlet var removeStationButton: NSButton!
    @IBOutlet var volumeControl: NSSlider!
    @IBOutlet var volumeDownButton: NSButton!
    @IBOutlet var volumeUpButton: NSButton!
    @IBOutlet var titleBar: NSView!

    /* ****************************************
     *
     * ****************************************/
    override var windowNibName: String! {
        return "StationsWindow"
    }

    /* ****************************************
     *
     * ****************************************/
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.delegate = self

        playButton.bezelStyle = NSButton.BezelStyle.regularSquare
        playButton.setButtonType(NSButton.ButtonType.momentaryPushIn)
        playButton.imagePosition = NSControl.ImagePosition.imageOnly
        playButton.alignment = NSTextAlignment.center
        playButton.lineBreakMode = NSLineBreakMode.byTruncatingTail
        playButton.state = NSControl.StateValue.on
        playButton.isBordered = false
        playButton.imageScaling = NSImageScaling.scaleNone
        playButton.font = NSFont.systemFont(ofSize: 24)
        playButton.image?.isTemplate = true

        stationsView.rowHeight = 48
        stationsView.delegate = self
        stationsView.dataSource = self
        stationsView.doubleAction = #selector(doubleClickRow)
        stationsView.registerForDraggedTypes([stationPasteboardType])
        stationsView.expandItem(nil, expandChildren: true)
        stationsView.selectRowIndexes(IndexSet(arrayLiteral: 0), byExtendingSelection: true)

        playButton.target = player
        playButton.action = #selector(Player.toggle)

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

        volumeControl.minValue = 0
        volumeControl.maxValue = 1
        volumeControl.doubleValue = Double(player.volume)

        refresh()
    }

    func windowWillClose(_ notification: Notification) {
        StationsWindow.instance = nil
    }

    /* ****************************************
     *
     * ****************************************/
    private static var instance: StationsWindow?
    class func show() -> StationsWindow {
        if instance == nil {
            instance = StationsWindow()
        }

        NSApp.setActivationPolicy(.regular)
        instance?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        return instance!
    }

    /* ****************************************
     *
     * ****************************************/
    override public func mouseDown(with event: NSEvent) {
        if NSPointInRect(event.locationInWindow, titleBar.frame) {
            window?.performDrag(with: event)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func selectedNode() -> StationsStore.Node? {
        return stationsView.item(atRow: stationsView.selectedRow) as? StationsStore.Node
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func refresh() {
        switch player.status {
        case Player.Status.paused:
            stationLabel.stringValue = player.stationName
            songLabel.stringValue = ""

        case Player.Status.connecting:
            stationLabel.stringValue = player.stationName
            songLabel.stringValue = "Connecting...".tr(withComment: "Station label text")

        case Player.Status.playing:
            stationLabel.stringValue = player.stationName
            songLabel.stringValue = player.title
        }

        switch player.status {
        case Player.Status.paused:
            playButton.image = NSImage(named: NSImage.Name("NSTouchBarPlayTemplate"))
            playButton.image?.isTemplate = true
            playButton.toolTip = "Play".tr(withComment: "Toolbar button toolTip")

        case Player.Status.connecting:
            playButton.image = NSImage(named: NSImage.Name("NSTouchBarPauseTemplate"))
            playButton.image?.isTemplate = true
            playButton.toolTip = "Pause".tr(withComment: "Toolbar button toolTip")

        case Player.Status.playing:
            playButton.image = NSImage(named: NSImage.Name("NSTouchBarPauseTemplate"))
            playButton.image?.isTemplate = true
            playButton.toolTip = "Pause".tr(withComment: "Toolbar button toolTip")
        }

        let selNode = selectedNode()
        print(#function, selNode != nil)
        removeStationButton.isEnabled = (selNode != nil)
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

        stationsView.reloadData()
        stationsView.expandItem(newNode.parent())
        // Select new item
        let row = stationsView.row(forItem: newNode)
        if row > -1 {
            stationsView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: true)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func addStation(_ sender: Any) {
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
    @IBAction func addGroup(_ sender: Any) {
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
    @IBAction func removeStation(_ sender: Any) {
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
                parent.remove(node)
                self.stationsView.reloadData()
                stationsStore.emitChanged()
                stationsStore.write()
            }
        })
    }

    @IBAction func volumeChanged(_ sender: Any) {
        player.volume = Float(volumeControl.doubleValue)
    }

    @IBAction func volumeUp(_ sender: Any) {
        volumeControl.doubleValue += 0.05
        volumeChanged(0)
    }

    @IBAction func volumeDown(_ sender: Any) {
        volumeControl.doubleValue -= 0.05
        volumeChanged(0)
    }
}

/* ****************************************
 *
 * ****************************************/
extension StationsWindow: NSOutlineViewDelegate {
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
extension StationsWindow: NSOutlineViewDataSource {
    /* ****************************************
     * Returns the number of child items each item in the outline
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        // Root item
        if item == nil {
            return stationsStore.root.nodes.count
        }

        if item is Station {
            return 1
        }

        if let group = item as? Group {
            return max(1, group.nodes.count)
        }

        return 0
    }

    /* ****************************************
     * Returns the actual item
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        // Root item
        if item == nil {
            return stationsStore.root.nodes[index]
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
}

// extension StationsWindow: NSTableViewDataSource {
//
//    /* ****************************************
//     *
//     * ****************************************/
//    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
//        let pasteboardItem = NSPasteboardItem()
//        pasteboardItem.setString(String(row), forType: stationPasteboardType)
//        return pasteboardItem
//    }
//
//    /* ****************************************
//     *
//     * ****************************************/
//    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
//        if dropOperation == .above {
//            return .move
//        } else {
//            return []
//        }
//    }
//
//    /* ****************************************
//     *
//     * ****************************************/
//    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
//        guard
//            let str = info.draggingPasteboard.pasteboardItems?.first?.string(forType: stationPasteboardType),
//            let srcRow = Int(str)
//        else { return false }
//
//        // When you drag an item downwards, the "new row" index is actually --1. Remember dragging operation is `.above`.
//        var newRow = row
//        if srcRow < newRow {
//            newRow = row - 1
//        }
//
//        if srcRow == newRow {
//            return false
//        }
//
//        // Animate the rows .......................
//        tableView.beginUpdates()
//        tableView.moveRow(at: srcRow, to: newRow)
//        tableView.endUpdates()
//
//        let station = stationsStore.stations[srcRow]
//        stationsStore.stations.remove(at: srcRow)
//        stationsStore.stations.insert(station, at: newRow)
//
//        emitChanged()
//        stationsStore.write()
//
//        return true
//    }
// }
