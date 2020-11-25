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


//extension NSTextField{ func controlTextDidChange(obj: NSNotification){} }
//
//class SomeViewController:NSViewController,NSTextFieldDelegate {
//
//    //optional func controlTextDidBeginEditing(_ obj: Notification)
//
//    //  optional func controlTextDidEndEditing(_ obj: Notification)
//
//    //optional func controlTextDidChange(_ obj: Notification)
//    override func controlTextDidChange(_ obj: Notification)
//    {
//        let object = obj.object as! NSTextField
//        let value = object.stringValue
//        print(value)
//    }
//}

class StationsViewController: NSViewController {
    let player : Player? = (NSApp.delegate as? AppDelegate)?.player
    
    @IBOutlet weak var tableView: NSTableView!

    
    fileprivate enum Identifiers   {
        static let NameColumn = NSUserInterfaceItemIdentifier(rawValue: "nameColumn")
        static let UrlColumn  = NSUserInterfaceItemIdentifier(rawValue: "urlColumn")
        static let NameCell   = NSUserInterfaceItemIdentifier(rawValue: "nameCell")
        static let UrlCell    = NSUserInterfaceItemIdentifier(rawValue: "urlCell")
    }
    
    private let favoriteOnImage  = NSImage(named:NSImage.Name("star-filled"))?.tint(color: .systemYellow)
    private let favoriteOffImage = NSImage(named:NSImage.Name("star-empty"))?.tint(color: .lightGray)

        
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
        guard let row = selectedRow() else { return }
        stationsStore.stations[row].isFavorite = !stationsStore.stations[row].isFavorite
        self.tableView.reloadData(forRowIndexes: [row], columnIndexes: [0])
        emitChanged()
        stationsStore.write()
    }
    
    /* ****************************************
     *
     * ****************************************/
    func setPlayPauseMenu(isPlaing: Bool) {
        guard
            let mainMenu = (NSApp.delegate as? AppDelegate)?.mainMenu,
            let stationsMenu = mainMenu.item(withTitle: "Stations")?.submenu
            else {
                return
        }
        
        stationsMenu.item(withTag: 1)?.isHidden = !isPlaing
        stationsMenu.item(withTag: 2)?.isHidden = isPlaing
    }

//    @IBAction func togglePlay(_ sender: Any) {
//        player?.toggle()
//    }
 
    /* ****************************************
     *
     * ****************************************/
    @objc func playerStatusChanged() {
        setPlayPauseMenu(isPlaing: player?.status == Player.Status.playing)
   //     NotificationCenter.default.post(name: Notification.Name("PlayerStatusChangedzz"), object: nil)
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
    @IBAction func stationNameEdited(_ sender: NSTextField) {
        guard let row = selectedRow() else { return }
        stationsStore.stations[row].name = sender.stringValue
        emitChanged()
        stationsStore.write()
    }
    
    
    /* ****************************************
     *
     * ****************************************/
    @IBAction func stationUrlEdited(_ sender: NSTextField) {
        guard let row = selectedRow() else { return }
        stationsStore.stations[row].url = sender.stringValue
        emitChanged()
        stationsStore.write()
    }
    
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

//    //func itemTextFieldUpdated
//     @IBAction func onEnterInTextField(_ sender: Any) {
//         print("onEnterInTextField")
//     }
    
    //func itemTextFieldUpdated
     @IBAction func textEdited(_ sender: Any) {
         print("textEdited")
     }
}



fileprivate let NAME_COLUMN_ID = NSUserInterfaceItemIdentifier(rawValue: "nameColumn")
/* ****************************************
 *
 * ****************************************/
extension StationsViewController: NSTableViewDelegate {
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let station = stationsStore.stations[row]

        guard let column = tableColumn else { return nil }

        if column.identifier == Identifiers.NameColumn {
            guard let cellView = tableView.makeView(withIdentifier: Identifiers.NameCell, owner: self) as? StationNameCellView else { return nil }
            cellView.textField?.stringValue = station.name
            

            
            cellView.favoriteButton?.action = #selector(favClicked(sender:))
            if station.isFavorite {
                cellView.favoriteButton?.image = favoriteOnImage
            } else {
                cellView.favoriteButton?.image = favoriteOffImage
            }
            
            
            //cellView.textField?.isEditable = true
            //cellView.textField?.delegate = self
           
//            cellView.imageView?.image = NSImage(named:NSImage.Name(station.isFavorite ? "star-filled" : "star-empty"))
            return cellView

        } else if tableColumn?.identifier == Identifiers.UrlColumn {
            guard let cellView = tableView.makeView(withIdentifier: Identifiers.UrlCell, owner: self) as? NSTableCellView else { return nil }
            cellView.textField?.stringValue = station.url
            return cellView
        }
        
        return nil
    }
    
    
 
    
//    @IBAction func favClicked(sender: NSButton){
//        let row = self.tableView.row(for: sender)
//        if row > -1 && row < stationsStore.stations.count {
//            stationsStore.stations[row].isFavorite = !stationsStore.stations[row].isFavorite
//            self.tableView.reloadData(forRowIndexes: [row], columnIndexes: [0])
////            self.tableView.reloadData()
//        }
//    }
}

//extension StationsViewController: NSTextFieldDelegate {
//    func controlTextDidChange(_ notification: NSNotification) {
//    print("controlTextDidChange")
//  }
//}

class StationNameCellView: NSTableCellView {

    @IBOutlet weak var favoriteButton: NSButton?

 
}
