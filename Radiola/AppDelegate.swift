//
//  AppDelegate.swift
//  Radiola
//
//  Created by Alex Sokolov on 26.05.2020.
//  Copyright © 2020 Alex Sokolov. All rights reserved.
//

import Cocoa
import UIKitPlus

//class StatusItem2: StatusItem {
//    override init(_ statusBar: NSStatusBar = .system, length: CGFloat = NSStatusItem.squareLength) {
//
//    }
//}

extension String {
    var tr: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}

extension String {
    func tr(withComment: String) -> String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: withComment)
    }
}

//@NSApplicationMain
//class AppDelegate: NSObject, NSApplicationDelegate {
class RadiolaApplication: App {
    private let oplDirectoryName = "com.github.SokoloffA.Radiola/"
    private let oplFileName = "bookmarks.opml"
    private let audioSytstem = AudioSytstem()
    private let mediaKeys = MediaKeysController()

    var pauseMenuItem: NSMenuItem?
    var playMenuItem: NSMenuItem?
    var checkForUpdatesMenuItem: NSMenuItem?

    private var statusBar: StatusBarController!

    public override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /* ****************************************
     *
     * ****************************************/
    override func applicationDidFinishLaunching(_ aNotification: Notification) {
        print(#function)
        super.applicationDidFinishLaunching(aNotification)
        print(#function)
        /*
        NSApp.setActivationPolicy(.accessory)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(processError),
                                               name: Notification.Name.ErrorOccurred,
                                               object: nil)

        let dirName = URL(
            fileURLWithPath: oplDirectoryName,
            relativeTo: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first)

        if !FileManager.default.fileExists(atPath: dirName.absoluteString) {
            do {
                try FileManager.default.createDirectory(at: dirName, withIntermediateDirectories: true)
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerStatusChanged),
                                               name: Notification.Name.PlayerStatusChanged,
                                               object: nil)

        player.station = stationsStore.lastStation()

        statusBar = StatusBarController()

        playMenuItem?.target = player
        playMenuItem?.action = #selector(Player.play)

        pauseMenuItem?.target = player
        pauseMenuItem?.action = #selector(Player.stop)

        checkForUpdatesMenuItem?.target = updater
        checkForUpdatesMenuItem?.action = #selector(Updater.checkForUpdates)

        playerStatusChanged()

        if settings.playLastStation {
            #if DEBUG
                print(settings.lastStationUrl!)
            #endif
            player.play()
        }
        print(#function)*/
    }

    /* ****************************************
     *
     * ****************************************/
    @AppBuilder override var body: AppBuilderContent {
        StatusItem {
            MenuItem().view {
                UView().background(.purple).size(200, 44).edgesToSuperview()
            }
            MenuItem("Hey").submenu {
                MenuItem("Hey").onAction {

                }
                MenuItem("Clay").onAction {

                }
            }
            MenuItem("Hello").enabled(true).onAction {
                print("Hello world")
            }
            MenuItem.separator()
            MenuItem("Quit")
                .key("q")
                .onAction(selector: #selector(NSApplication.terminate))
        }
        .squareLength()
        .tint(.blue)
        .title("D")
        .menuTitle("Content")
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
    @IBAction func startPlay(_ sender: NSMenuItem) {
        player.play()
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func stopPlay(_ sender: NSMenuItem) {
        player.stop()
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
    @objc func playerStatusChanged() {
        switch player.status {
            case Player.Status.paused:
                playMenuItem?.isHidden = false
                pauseMenuItem?.isHidden = true

            case Player.Status.connecting:
                playMenuItem?.isHidden = true
                pauseMenuItem?.isHidden = false

            case Player.Status.playing:
                playMenuItem?.isHidden = true
                pauseMenuItem?.isHidden = false
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func showStationView(_ sender: Any?) {
        _ = StationsWindow.show()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func showHistory(_ sender: Any?) {
        _ = HistoryWindow.show()
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func showPreferences(_ sender: Any) {
        _ = PreferencesWindow.show()
    }

    /* ****************************************
     *
     * ****************************************/
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        NSApp.setActivationPolicy(.accessory)
        return false
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func processError(_ notification: Notification) {
        let msg = notification.userInfo?["message"] as? String ?? ""

        print("** ERROR ******************************")
        print("* \(msg)")
        print("* On: \(notification.object ?? "nil")")
        print("*******************************************")
    }
}
