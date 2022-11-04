//
//  StationsWindow.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 05.07.2022.
//

import Cocoa

let stationPasteboardType = NSPasteboard.PasteboardType(rawValue: "Station.row")

class StationsWindow: NSWindowController, NSWindowDelegate {


    @IBOutlet weak var stationsView: NSOutlineView!
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

//        playButton.image = NSImage(named:NSImage.Name("NSTouchBarPlayTemplate"))
        //  playButton.contentTintColor = NSColor.systemGray4
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
//    func selectedRow() -> Int? {
//        let row = stationsView.selectedRow
//        if row > -1 && row < stationsStore.stations.count {
//            return row
//        }
//        return nil
//    }

    /* ****************************************
     *
//     * ****************************************/
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
    }

    /* ****************************************
     *
     * ****************************************/
//    func emitChanged() {
//        NotificationCenter.default.post(
//            name: Notification.Name.StationsChanged,
//            object: nil)
//    }

    /* ****************************************
     *
     * ****************************************/
    @objc func doubleClickRow(sender: AnyObject) {
//        guard let station = selectedStation() else { return }
//        if player.station == station && player.isPlaying {
//            return
//        }
//
//        player.station = station
//        player.play()
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func addStation(_ sender: Any) {
        func doAdd(name: String, url: String) {
            if url.isEmpty {
                return
            }

            let newStation = Station(name: name, url: url)
            let node = selectedNode()

            // ::::::::::::::::::::::::::::::
            // No items selected, we append to endo of top items
            if node == nil {
                stationsStore.root.append(newStation)
            }
            
            // ::::::::::::::::::::::::::::::
            // A group is selected, we add to its end
            if let group = node as? Group {
                group.append(newStation)
            }

            // ::::::::::::::::::::::::::::::
            // A station is selected, we after it
            if let station = node as? Station, let group = station.parent() {
                group.insert(newStation, after: station)
            }
            
            stationsStore.emitChanged()
            stationsStore.write()
            
            stationsView.reloadData()
            let row = stationsView.row(forItem: newStation)
            if row > -1 {
                print("ROW: \(row)")
                stationsView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: true)
            }
        }


        let dialog = AddStationDialog()
        window?.beginSheet(dialog.window!, completionHandler: { response in
            if response == NSApplication.ModalResponse.OK {
                doAdd(name: dialog.title, url: dialog.url)
            }
        })
//                let station = Station(
//                    name: dialog.title,
//                    url: dialog.url
//                )
//
//                let node = self.selectedNode()
//
////                if let g = node?.group() {
////                        stationsStore.addStation(toGroup: g, station: station)
////                }
//
////                stationsStore.addStation(after: node, station: station)
//
////                stationsStore.addStation(station, parent)
//
////                let row = max(0, self.stationsView.selectedRow + 1)
////                stationsStore.stations.insert(station, at: row)
//                self.stationsView.reloadData()
////                self.stationsView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
//                stationsStore.emitChanged()
//                stationsStore.write()
//            }
//        })
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func removeStation(_ sender: Any) {
//        guard let row = selectedRow() else { return }
//        guard let wnd = window else { return }
//
//        let alert = NSAlert()
//        alert.messageText = String(format: "Do you want to remove the station %@?", stationsStore.stations[row].name)
//        alert.informativeText = "This operation cannot be undone."
//        alert.addButton(withTitle: "Yes")
//        alert.addButton(withTitle: "Cancel")
//
//        alert.beginSheetModal(for: wnd, completionHandler: { response in
//            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
//                stationsStore.stations.remove(at: row)
//                self.stationsView.reloadData()
//                self.emitChanged()
//                stationsStore.write()
//            }
//        })
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
extension StationsWindow:  NSOutlineViewDataSource {

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
//extension StationsWindow: NSTableViewDataSource {
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
//}
