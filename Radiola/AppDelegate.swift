//
//  AppDelegate.swift
//  Radiola
//
//  Created by Alex Sokolov on 26.05.2020.
//  Copyright © 2020 Alex Sokolov. All rights reserved.
//

import Cocoa

extension String {
    var tr: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}

extension String {
    func tr(withComment:String) -> String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: withComment)
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private let oplDirectoryName = "com.github.SokoloffA.Radiola/"
    private let oplFileName = "bookmarks.opml"
    
    private let lastStationKey    = "Url"
    private let recentStationsKey = "RecentStations"
    private let recentStationsLengt = 5

    private var recentStations: [String] = []
    
    @IBOutlet weak var mainMenu: NSMenu!
    
    let player = Player()
    private let settings = UserDefaults.standard
    
    private let menuItem =
        NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    
    func applicationWillFinishLaunching(_ aNotification: Notification) {
        //NSApp.setActivationPolicy(.prohibited)
    }
    
    
    /* ****************************************
     *
     * ****************************************/
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        let dirName = URL(
            fileURLWithPath: oplDirectoryName,
            relativeTo: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first)
        
        let fileName = URL(
            fileURLWithPath: oplDirectoryName + "/" + oplFileName,
            relativeTo: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first)
        
        if !FileManager.default.fileExists(atPath: dirName.absoluteString) {
            do {
                try FileManager.default.createDirectory(at: dirName, withIntermediateDirectories: true)
            }
            catch {
                fatalError(error.localizedDescription)
            }
        }
        
        stationsStore.load(file: fileName)

        
        setIcon(item: menuItem, icon: "MenuButtonImage", size: 16)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerStatusChanged),
                                               name: Notification.Name.PlayerStatusChanged,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateTooltip),
                                               name: Notification.Name.PlayerMetadataChanged,
                                               object: nil)
    
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(rebuildMenu),
                                               name: Notification.Name.StationsChanged,
                                               object: nil)
        
        let favorites = stationsStore.favorites()
        if let last = settings.string(forKey: lastStationKey) {
            for s in favorites {
                if s.url == last {
                    player.station = s
                    break
                }
            }
        } else {
            if !favorites.isEmpty {
                player.station = favorites.first!
            }
        }
        
        playerStatusChanged()
        rebuildMenu()
    }
    
    
    /* ****************************************
     *
     * ****************************************/
    @objc func rebuildMenu() {
        let menu = NSMenu()
       
        let item = NSMenuItem()
        item.target = self
        item.isEnabled = true
        let playItemView = PlayItemView()//(frame: NSRect(x: 0, y: 0, width: 400, height: 44))
        item.view = playItemView
        menu.addItem(item)

        menu.addItem(NSMenuItem.separator())
        
//        buildRecentMenu(menu: menu)
//        menu.addItem(NSMenuItem.separator())
        buildFavoritesMenu(menu: menu)

        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(
            title: "Open Radiola",
            action: #selector(showStationView(_:)),
            keyEquivalent: ""))
        
        menu.addItem(NSMenuItem(
            title: "Quit".tr,
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"))
        
        menuItem.menu = menu
    }
    
    
    /* ****************************************
     *
     * ****************************************/
/*    func buildRecentMenu(menu: NSMenu) {
            
        guard let recentStations = settings.stringArray(forKey: recentStationsKey) else { return }
        if recentStations.isEmpty  {
            return
        }
        menu.addItem(NSMenuItem(title: "Recent stations".tr, action: nil, keyEquivalent: ""))

        for url in recentStations {
            if let station = stationsStore.station(byUrl: url) {
                let item = NSMenuItem(
                    title: "  " + station.name,
                    action:  #selector(AppDelegate.stationClicked(_:)),
                    keyEquivalent: "")
                item.tag = station.id
                
//                if station.url == player.station.url {
//                    item.state = NSControl.StateValue.on
//                }
                menu.addItem(item)
            }
        }
    }
*/
    /* ****************************************
     *
     * ****************************************/
    func buildFavoritesMenu(menu: NSMenu) {
        menu.addItem(NSMenuItem(title: "Favorite stations".tr, action: nil, keyEquivalent: ""))
        
        for station in stationsStore.favorites() {
            let item = NSMenuItem(
                title: "  " + station.name,
                action:  #selector(AppDelegate.stationClicked(_:)),
                keyEquivalent: "")

            item.tag = station.id
            
            menu.addItem(item)
        }
    }
        
    /* ****************************************
     *
     * ****************************************/
    private func setIcon(item: NSStatusItem, icon: String, size: Int = 12) {
        let img = NSImage(named:NSImage.Name(icon))
        img?.size = NSSize(width: size, height: size)
        img?.isTemplate = true
        item.button?.image = img
    }
    
    
    /* ****************************************
     *
     * ****************************************/
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    /* ****************************************
     *
     * ****************************************/
    @objc func togglePlay(_ sender: NSMenuItem) {
        player.toggle()
    }
    
    
    /* ****************************************
     *
     * ****************************************/
    @objc func stationClicked(_ sender: NSMenuItem) {
        guard let station = stationsStore.station(byId: sender.tag) else {
            return
        }
        
        if player.station == station && player.isPlaying {
            player.stop()
            return
        }
        
        player.station = station
        settings.set(station.url, forKey: lastStationKey)
        player.play()
    }
    
    
    
    /* ****************************************
     *
     * ****************************************/
    @objc func playerStatusChanged() {
        switch player.status {
        case Player.Status.paused:
            setIcon(item: menuItem, icon: "MenuButtonImage", size: 16)

        case Player.Status.connecting:
            setIcon(item: menuItem, icon: "MenuButtonImage", size: 16)

        case Player.Status.playing:
            setIcon(item: menuItem, icon: "MenuButtonPlay", size: 16)
        }
  
        updateTooltip()
    }
    
    /* ****************************************
     *
     * ****************************************/
    func addRecentStation(url: String) {
        if url.isEmpty {
            return
        }

        let old = settings.stringArray(forKey: recentStationsKey) ?? []
        if old.first == url {
            return
        }

        let new = Array(([url] + old.filter{$0 != url}).prefix(recentStationsLengt))
        settings.set(new, forKey: recentStationsKey)
    }
    
    
    /* ****************************************
     *
     * ****************************************/
    @objc func updateTooltip() {
        
        switch player.status {
        case Player.Status.paused:
            menuItem.button?.toolTip = player.station.name
            
        case Player.Status.connecting:
            menuItem.button?.toolTip =
                player.station.name +
                "\n⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯\n" +
                "Connecting...".tr(withComment: "Tooltip text")

        case Player.Status.playing:
            menuItem.button?.toolTip =
                player.station.name +
                "\n⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯\n" +
                player.title;
        }
    }
    
    var stationsWindowController : StationsWindowController? = nil
    
    /* ****************************************
     *
     * ****************************************/
//    private var window: NSWindow?
    @objc func showStationView(_ sender: Any?) {

        NSApp.setActivationPolicy(.regular)
        let storyboard = NSStoryboard(name: "Main", bundle: nil)

        if (stationsWindowController == nil) {
            guard let wc = storyboard.instantiateController(withIdentifier: "StationsWindowController") as? StationsWindowController    else {
                fatalError("Error getting main window controller")
            }
    
            stationsWindowController = wc
        }
        
        stationsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        NSApp.setActivationPolicy(.accessory)
        return false
    }

}

