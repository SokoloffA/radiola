//
//  StationsWindow.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 05.07.2022.
//

import Cocoa

class StationsWindow: NSWindowController, NSWindowDelegate, NSSplitViewDelegate {
    private static var instance: StationsWindow?

    private let stationsView = StationView()

    @IBOutlet var splitView: NSSplitView!
    @IBOutlet var toolBar: NSToolbar!
    @IBOutlet var toggleSideBarItem: NSToolbarItem!

    var sideBar = SideBar()
//    var sideBarWidth: CGFloat = 0.0

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

        splitView.delegate = self

        toggleSideBarItem.target = self
        toggleSideBarItem.action = #selector(toggleSideBar)

        splitView.addArrangedSubview(sideBar.view)
        splitView.addArrangedSubview(stationsView)
        splitView.setHoldingPriority(NSLayoutConstraint.Priority(260), forSubviewAt: 0)
        splitView.autosaveName = "Stations Splitter"
    }

    /* ****************************************
     *
     * ****************************************/
    func windowWillClose(_ notification: Notification) {
        StationsWindow.instance = nil
        let settings = UserDefaults.standard
        settings.set(sideBar.view.frame.width, forKey: "StationsSplitter 0")
    }

    /* ****************************************
     *
     * ****************************************/
    class func isActie() -> Bool {
        return instance != nil
    }

    /* ****************************************
     *
     * ****************************************/
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
    @objc private func toggleSideBar() {
        func animatePanelChange(
            toPosition position: CGFloat,
            ofDividerAt dividerIndex: Int
        ) {
            NSAnimationContext.runAnimationGroup { context in
                context.allowsImplicitAnimation = true
                context.duration = 0.250

                splitView.setPosition(position, ofDividerAt: dividerIndex)
                //    splitView.layoutSubtreeIfNeeded()
            }
        }

        let width = splitView.isSubviewCollapsed(sideBar.view) ? sideBar.view.fittingSize.width : 0
        animatePanelChange(
            toPosition: width,
            ofDividerAt: 0
        )
    }

    /* ****************************************
     *
     * ****************************************/
//    func splitViewDidResizeSubviews(_ notification: Notification) {
//        print(#function)
//    }

    /* ****************************************
     *
     * ****************************************/
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return subview == sideBar.view
    }

    @IBAction func sidebarChanged(_ sender: NSOutlineView) {
        guard let item = sideBar.currentItem() else { return }

        switch item.type {
            case .local: loadLocalStations()
            case .radioBrowser: loadRadioBrowser(item)
        }
    }

    private func loadLocalStations() {
        stationsView.stations = stationsStore.root
    }

    private func loadRadioBrowser(_ item: SideBar.Item) {
        Task {
            do {
                let request = RadioBrowser.StationsRequest()
                request.hidebroken = true
                request.order = .votes

                let res = try await request.get(bytag: "Classic Rock")
                requestDone(res)

            } catch {
                print("Request failed with error: \(error)")
            }
        }
    }

    private func requestDone(_ resp: [RadioBrowser.Station]) {
        print("DONE", resp.count)
        var root = Group(name: "")
        for r in resp {
            var s = Station(name: r.name, url: r.url)
            root.append(s)
        }

        stationsView.stations = root
    }
//        //stationsView.stations = Group(name: "")
//        let req = RadioBrowserTagRequest()
//        print("SEND")
//        req.send(){(result) in
//            DispatchQueue.main.async {
//                switch result {
//                    case .success(let tags):
//                        print("RESULT", tags)
//                    self.stationsView.stations = Group(name: "")
//
//
//                    case .failure(let error):
//                        print("Request failed with error: \(error)")
//                    }
//
//
//            }
//        }
//        print("DONE")
//    }
}
