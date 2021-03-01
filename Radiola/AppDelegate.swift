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
    
    private let oplFileName = "com.github.SokoloffA.Radiola/bookmarks.opml"

    private let lastStationKey    = "Url"
    private let recentStationsKey = "RecentStations"
    private let recentStationsLengt = 5

    private var recentStations: [String] = []
    
    @IBOutlet weak var mainMenu: NSMenu!
    //var mainWindowController: NSWindowController!
    
    let player = Player()
    private let settings = UserDefaults.standard
    
    private let playItem =
        NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    
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
        
        let fileName = URL(
            fileURLWithPath: oplFileName,
            relativeTo: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first)
        
        stationsStore.load(file: fileName)

        
        setIcon(item: menuItem, icon: "MenuButtonImage", size: 16)
        rebuildMenu()
        
        playerStatusChanged()
//        setIcon(item: playItem, icon: "StatusBarPlay")
        playItem.button?.action = #selector(togglePlay(_:))
        
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
        
    }
    
    
    
    /* ****************************************
     *
     * ****************************************/
    @objc func rebuildMenu() {
        let menu = NSMenu()
        buildRecentMenu(menu: menu)
        menu.addItem(NSMenuItem.separator())
        buildFavoritesMenu(menu: menu)
        

        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(
            title: "Open Radiola",
            action: #selector(showStationView(_:)),
            keyEquivalent: ""))
        
//        menu.addItem(NSMenuItem(
//            title: "About Radiola".tr,
//            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
//            keyEquivalent: ""))
        
        menu.addItem(NSMenuItem(
            title: "Quit".tr,
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"))
        
        menuItem.menu = menu
    }
    
    
    /* ****************************************
     *
     * ****************************************/
    func buildRecentMenu(menu: NSMenu) {
            
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
            
            //if station.url == player.station.url {
            //    item.state = NSControl.StateValue.on
           // }
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
        /*       let n = sender.tag
         if n >= stationsStore.favorites().count {
         return
         }
         let station = favorites[n]
         */
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
        guard let playButton = playItem.button else {
            return
        }
                
        addRecentStation(url: player.station.url)
        
        if player.status == Player.Status.playing {
            setIcon(item: playItem, icon: "StatusBarPause")
        } else {
            setIcon(item: playItem, icon: "StatusBarPlay")
            playButton.isEnabled  = !player.station.isEmpty
        }

        rebuildMenu()
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
        if player.isPlaying {
            playItem.button?.toolTip = player.station.name + "\n⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯\n" + player.title;
        } else {
            playItem.button?.toolTip = player.station.name
        }
        menuItem.button?.toolTip = playItem.button?.toolTip
    }
    
    var stationsWindowController : StationsWindowController? = nil
    
    /* ****************************************
     *
     * ****************************************/
//    private var window: NSWindow?
    @objc func showStationView(_ sender: Any?) {

        NSApp.setActivationPolicy(.regular)
        let storyboard = NSStoryboard(name: "Main", bundle: nil)

        
        
//        guard let viewController = storyboard.instantiateController(withIdentifier: "StationsViewController") as? StationsViewController else {
//            fatalError("Error getting view controller")
//        }
//
//        viewController.player = player
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

