//
//  StationsViewController.swift
//  Radiola
//
//  Created by Alex Sokolov on 26.05.2020.
//  Copyright © 2020 Alex Sokolov. All rights reserved.
//

//import Foundation
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


class StationsViewController: NSViewController {
    let player : Player? = (NSApp.delegate as? AppDelegate)?.player
    
    @IBOutlet weak var tableView: NSTableView!
   
    private let favoriteIcons = [
        false: NSImage(named:NSImage.Name("star-empty"))?.tint(color: .lightGray),
        true:  NSImage(named:NSImage.Name("star-filled"))?.tint(color: .systemYellow),
    ]

        
    /* ****************************************
     *
     * ****************************************/
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerStatusChanged),
                                               name: Notification.Name.PlayerStatusChanged,
                                               object: nil)

        tableView.doubleAction = #selector(doubleClickRow)
        
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
    @IBAction func favClicked(sender: NSButton){
        let row = self.tableView.row(for: sender)
        if row < 0 && row >= stationsStore.stations.count {
            return
        }
        
        stationsStore.stations[row].isFavorite = !stationsStore.stations[row].isFavorite
        sender.image = favoriteIcons[stationsStore.stations[row].isFavorite]!
        emitChanged()
        stationsStore.write()
    }
    
    
 
    /* ****************************************
     *
     * ****************************************/
    @objc func playerStatusChanged() {
//        setPlayPauseMenu(isPlaing: player?.status == Player.Status.playing)
    }

    
    /* ****************************************
     *
     * ****************************************/
    @IBAction func addStation(_ sender: Any) {
        let storyboard = NSStoryboard(name: NSStoryboard.Name(stringLiteral: "Main"), bundle: nil)
        let sceneIdentifier = NSStoryboard.SceneIdentifier(stringLiteral: "AddStationWindowController")
        guard
            let windowController = storyboard.instantiateController(withIdentifier: sceneIdentifier) as? NSWindowController,
            let wnd = windowController.window,
            let addStationController = windowController.contentViewController as? AddStationController
        else { return }

        self.view.window?.beginSheet(wnd, completionHandler: { (response) in
            if response == NSApplication.ModalResponse.OK {
                if addStationController.url.isEmpty {
                    return
                }
                
                let station =  Station (
                    id:   stationsStore.stations.count,
                    name: addStationController.name,
                    url:  addStationController.url
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
        guard let wnd = self.view.window else { return }
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
    
    
    /* ****************************************
     *
     * ****************************************/
    @IBAction func stationNameEdited(sender: NSTextField) {
        guard let row = selectedRow() else { return }
        stationsStore.stations[row].name = sender.stringValue
        emitChanged()
        stationsStore.write()
    }
    
    
    /* ****************************************
     *
     * ****************************************/
    @IBAction func stationUrlEdited(sender: NSTextField) {
        guard let row = selectedRow() else { return }
        stationsStore.stations[row].url = sender.stringValue
        emitChanged()
        stationsStore.write()
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
}


/* ****************************************
 *
 * ****************************************/
extension StationsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return stationsStore.stations.count
    }
}


fileprivate let NAME_COLUMN_ID = NSUserInterfaceItemIdentifier(rawValue: "nameColumn")
/* ****************************************
 *
 * ****************************************/
extension StationsViewController: NSTableViewDelegate {
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let station = stationsStore.stations[row]
        
        let view = StationRowView()
        view.nameEdit.stringValue = station.name
        view.nameEdit.action = #selector(stationNameEdited(sender:))
            
        view.urledit.stringValue = station.url
        view.urledit.action = #selector(stationUrlEdited(sender:))
        
        view.favoriteButton.action = #selector(favClicked(sender:))
        view.favoriteButton.image = favoriteIcons[station.isFavorite]!
                
        return view
    }

}
