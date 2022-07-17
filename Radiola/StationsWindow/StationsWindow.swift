//
//  StationsWindow.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 05.07.2022.
//

import Cocoa

let stationPasteboardType = NSPasteboard.PasteboardType(rawValue: "Station.row")

class StationsWindow: NSWindowController, NSWindowDelegate {
    private let favoriteIcons = [
        false: NSImage(named: NSImage.Name("star-empty"))?.tint(color: .lightGray),
        true: NSImage(named: NSImage.Name("star-filled"))?.tint(color: .systemYellow),
    ]

    @IBOutlet var tableView: NSTableView!
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

        tableView.delegate = self
        tableView.dataSource = self
        tableView.doubleAction = #selector(doubleClickRow)

        tableView.registerForDraggedTypes([stationPasteboardType])

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
    func selectedRow() -> Int? {
        let row = tableView.selectedRow
        if row > -1 && row < stationsStore.stations.count {
            return row
        }
        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    func selectedStation() -> Station? {
        guard let row = selectedRow() else { return nil }
        return stationsStore.stations[row]
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func refresh() {
        switch player.status {
        case Player.Status.paused:
            stationLabel.stringValue = player.station.name
            songLabel.stringValue = ""

        case Player.Status.connecting:
            stationLabel.stringValue = player.station.name
            songLabel.stringValue = "Connecting...".tr(withComment: "Station label text")

        case Player.Status.playing:
            stationLabel.stringValue = player.station.name
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
    func emitChanged() {
        NotificationCenter.default.post(
            name: Notification.Name.StationsChanged,
            object: nil)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func doubleClickRow(sender: AnyObject) {
        guard let row = selectedRow() else { return }
        if player.station == stationsStore.stations[row] && player.isPlaying {
            return
        }

        player.station = stationsStore.stations[row]
        player.play()
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func addStation(_ sender: Any) {
        let dialog = AddStationDialog()
        window?.beginSheet(dialog.window!, completionHandler: { response in
            if response == NSApplication.ModalResponse.OK {
                if dialog.url.isEmpty {
                    return
                }

                let station = Station(
                    id: stationsStore.stations.count,
                    name: dialog.title,
                    url: dialog.url
                )

                let row = max(0, self.tableView.selectedRow + 1)
                stationsStore.stations.insert(station, at: row)
                self.tableView.reloadData()
                self.tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                self.emitChanged()
                stationsStore.write()
            }
        })
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func removeStation(_ sender: Any) {
        guard let row = selectedRow() else { return }
        guard let wnd = window else { return }

        let alert = NSAlert()
        alert.messageText = String(format: "Do you want to remove the station %@?", stationsStore.stations[row].name)
        alert.informativeText = "This operation cannot be undone."
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "Cancel")

        alert.beginSheetModal(for: wnd, completionHandler: { response in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                stationsStore.stations.remove(at: row)
                self.tableView.reloadData()
                self.emitChanged()
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

extension StationsWindow: NSTableViewDelegate {
    /* ****************************************
     *
     * ****************************************/
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let station = stationsStore.stations[row]

        let view = StationRowView()
        view.nameEdit.stringValue = station.name
        view.nameEdit.tag = station.id
        view.nameEdit.action = #selector(stationNameEdited(sender:))

        view.urledit.stringValue = station.url
        view.urledit.tag = station.id
        view.urledit.action = #selector(stationUrlEdited(sender:))

        view.favoriteButton.action = #selector(favClicked(sender:))
        view.favoriteButton.tag = station.id
        view.favoriteButton.image = favoriteIcons[station.isFavorite]!

        return view
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func stationNameEdited(sender: NSTextField) {
        guard let n = stationsStore.index(byId: sender.tag) else { return }
        stationsStore.stations[n].name = sender.stringValue
        emitChanged()
        stationsStore.write()
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func stationUrlEdited(sender: NSTextField) {
        guard let n = stationsStore.index(byId: sender.tag) else { return }
        stationsStore.stations[n].url = sender.stringValue
        emitChanged()
        stationsStore.write()
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func favClicked(sender: NSButton) {
        guard let n = stationsStore.index(byId: sender.tag) else { return }
        stationsStore.stations[n].isFavorite = !stationsStore.stations[n].isFavorite
        sender.image = favoriteIcons[stationsStore.stations[n].isFavorite]!
        emitChanged()
        stationsStore.write()
    }
}

/* ****************************************
 *
 * ****************************************/
extension StationsWindow: NSTableViewDataSource {
    /* ****************************************
     *
     * ****************************************/
    func numberOfRows(in tableView: NSTableView) -> Int {
        return stationsStore.stations.count
    }

    /* ****************************************
     *
     * ****************************************/
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(String(row), forType: stationPasteboardType)
        return pasteboardItem
    }

    /* ****************************************
     *
     * ****************************************/
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if dropOperation == .above {
            return .move
        } else {
            return []
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard
            let str = info.draggingPasteboard.pasteboardItems?.first?.string(forType: stationPasteboardType),
            let srcRow = Int(str)
        else { return false }

        // When you drag an item downwards, the "new row" index is actually --1. Remember dragging operation is `.above`.
        var newRow = row
        if srcRow < newRow {
            newRow = row - 1
        }

        if srcRow == newRow {
            return false
        }

        // Animate the rows .......................
        tableView.beginUpdates()
        tableView.moveRow(at: srcRow, to: newRow)
        tableView.endUpdates()

        let station = stationsStore.stations[srcRow]
        stationsStore.stations.remove(at: srcRow)
        stationsStore.stations.insert(station, at: newRow)

        emitChanged()
        stationsStore.write()

        return true
    }
}
