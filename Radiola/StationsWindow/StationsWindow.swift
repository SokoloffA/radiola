//
//  StationsWindow.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 05.07.2022.
//

import Cocoa

extension NSImage {
    func tint(color: NSColor) -> NSImage {
        if self.isTemplate == false {
            return self
        }
        
        let image = self.copy() as! NSImage
        image.lockFocus()
        
        color.set()
        
        let imageRect = NSRect(origin: .zero, size: image.size)
        imageRect.fill(using: .sourceIn)
        
        image.unlockFocus()
        image.isTemplate = false
        
        return image
    }
}

	
class StationsWindow: NSWindowController {

    private let player : Player? = (NSApp.delegate as? AppDelegate)?.player
    
    private let favoriteIcons = [
        false: NSImage(named:NSImage.Name("star-empty"))?.tint(color: .lightGray),
        true:  NSImage(named:NSImage.Name("star-filled"))?.tint(color: .systemYellow),
    ]
    
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var playButton: NSToolbarItem!

    
    /* ****************************************
     *
     * ****************************************/
    private static var instance: StationsWindow?
    class func show() -> StationsWindow {
        if (instance == nil) {
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
    override var windowNibName: String! {
        return "StationsWindow"
    }
    
    
    /* ****************************************
     *
     * ****************************************/
    override func windowDidLoad() {
        super.windowDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerStatusChanged),
            name: Notification.Name.PlayerStatusChanged,
            object: nil)

        tableView.doubleAction = #selector(doubleClickRow)
        
        playerStatusChanged()
    }
    
    /* ****************************************
     *
     * ****************************************/
    func selectedRow() -> Int? {
        let row = self.tableView.selectedRow
        if row > -1 && row < stationsStore.stations.count {
            return row
        }
        return nil
    }
    
    /* ****************************************
     *
     * ****************************************/
    @IBAction func playPouseClicked(_ sender: Any) {
        player?.toggle()
    }

    
    /* ****************************************
     *
     * ****************************************/
    @objc func playerStatusChanged() {
        if (player?.status == Player.Status.playing) {
            playButton?.image = NSImage(named:NSImage.Name("NSTouchBarPauseTemplate"))
            playButton?.label = "Pause".tr(withComment: "Toolbar button label")
            playButton?.toolTip = "Pause".tr(withComment: "Toolbar button toolTip")
        }
        else {
            playButton?.image = NSImage(named:NSImage.Name("NSTouchBarPlayTemplate"))
            playButton?.label = "Play".tr(withComment: "Toolbar button label")
            playButton?.toolTip = "Play".tr(withComment: "Toolbar button toolTip")
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
        if player?.station != stationsStore.stations[row] {
            player?.station = stationsStore.stations[row]
            player?.play()
        }
    }
    

    @IBAction func addStation(_ sender: Any) {
        let dialog = AddStationDialog()
        window?.beginSheet(dialog.window!, completionHandler: { (response) in
            if response == NSApplication.ModalResponse.OK {
                if dialog.url.isEmpty {
                    return
                }
                
                let station =  Station (
                    id:   stationsStore.stations.count,
                    name: dialog.title,
                    url:  dialog.url
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
    
    
    @IBAction func removeSttion(_ sender: Any) {
        guard let row = selectedRow() else { return }
        guard let wnd = self.window else { return }
        
        let alert = NSAlert()
        alert.messageText = "Do you want to remove station?"
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: wnd, completionHandler: { (response) in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                stationsStore.stations.remove(at: row);
                self.tableView.reloadData()
                self.emitChanged()
                stationsStore.write()
            }
        })
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
    @IBAction func favClicked(sender: NSButton){
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
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return stationsStore.stations.count
    }
}
