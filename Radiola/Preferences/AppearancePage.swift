//
//  AppearancePage.swift
//  Radiola
//
//  Created by Alex Sokolov on 03.12.2022.
//

import Cocoa

class AppearancePage: NSViewController {

    @IBOutlet weak var showVolumeInMenuCheckbox: NSButton!
    @IBOutlet weak var favoritesMenuGroupTypeCbx: NSPopUpButton!
    @IBOutlet weak var showVolume: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Appearance"
        
        showVolume.state = settings.showVolumeInMenu ? .on : .off
        
        favoritesMenuGroupTypeCbx.removeAllItems()
        
        favoritesMenuGroupTypeCbx.addItem(withTitle:  "as a flat list")
        favoritesMenuGroupTypeCbx.lastItem?.tag = Settings.FavoritesMenuType.flat.rawValue

        favoritesMenuGroupTypeCbx.addItem(withTitle:  "with margins")
        favoritesMenuGroupTypeCbx.lastItem?.tag = Settings.FavoritesMenuType.margin.rawValue

        favoritesMenuGroupTypeCbx.addItem(withTitle:  "as a submenu")
        favoritesMenuGroupTypeCbx.lastItem?.tag = Settings.FavoritesMenuType.submenu.rawValue
    }
    
    @IBAction func showVolumeChanged(_ sender: NSButton) {
        settings.showVolumeInMenu =  showVolume.state == .on
        NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
    }
    
    @IBAction func favoritesMenuGroupTypeChanged(_ sender: Any) {
        if let type =  Settings.FavoritesMenuType(rawValue: favoritesMenuGroupTypeCbx.selectedItem?.tag ?? 0) {
            settings.favoritesMenuType = type
            NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
        }
    }
    
}
