//
//  StationsWindow.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 05.07.2022.
//

import Cocoa

class StationsWindow: NSWindowController, NSWindowDelegate, NSSplitViewDelegate {
    private static var instance: StationsWindow?
    var sideBar = SideBar()
    var sideBarWidth: CGFloat = 0.0
    private let stationsView = StationView()
    private var searchView: SearchView?
    private let toolbarPlayView = ToolbarPlayView()
    private let toolbarVolumeView = ToolbarVolumeView()
    private let toolbarLeftMargin = 145.0

    @IBOutlet var splitView: NSSplitView!
    @IBOutlet var rightView: NSView!
    @IBOutlet var toggleSideBarItem: NSToolbarItem!

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

        splitView.insertArrangedSubview(sideBar.view, at: 0)
        splitView.setHoldingPriority(NSLayoutConstraint.Priority(260), forSubviewAt: 0)
        splitView.autosaveName = "Stations Splitter"

        initStationsPanel()
    }

    /* ****************************************
     *
     * ****************************************/
    func initStationsPanel() {
        let toolbarHeight = window?.contentView?.safeAreaInsets.top ?? 52

        let playView = toolbarPlayView.view
        let volumeView = toolbarVolumeView.view
        rightView.addSubview(playView)
        rightView.addSubview(volumeView)
        rightView.addSubview(stationsView)

        playView.translatesAutoresizingMaskIntoConstraints = false
        volumeView.translatesAutoresizingMaskIntoConstraints = false
        stationsView.translatesAutoresizingMaskIntoConstraints = false

        playView.topAnchor.constraint(equalTo: rightView.topAnchor).isActive = true
        playView.bottomAnchor.constraint(equalTo: rightView.topAnchor, constant: toolbarHeight).isActive = true
        volumeView.topAnchor.constraint(equalTo: playView.topAnchor).isActive = true
        volumeView.bottomAnchor.constraint(equalTo: playView.bottomAnchor).isActive = true

        let cnst = playView.leadingAnchor.constraint(equalTo: rightView.leadingAnchor)
        cnst.priority = NSLayoutConstraint.Priority(999)
        cnst.isActive = true
        if let contentView = window?.contentView {
            playView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: toolbarLeftMargin).isActive = true
        }
        volumeView.leadingAnchor.constraint(equalTo: playView.trailingAnchor).isActive = true
        volumeView.trailingAnchor.constraint(equalTo: rightView.trailingAnchor).isActive = true

        stationsView.topAnchor.constraint(equalTo: playView.bottomAnchor).isActive = true
        stationsView.bottomAnchor.constraint(equalTo: rightView.bottomAnchor).isActive = true
        stationsView.leadingAnchor.constraint(equalTo: rightView.leadingAnchor).isActive = true
        stationsView.trailingAnchor.constraint(equalTo: rightView.trailingAnchor).isActive = true
    }

    /* ****************************************
     *
     * ****************************************/
    func windowWillClose(_ notification: Notification) {
        StationsWindow.instance = nil
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
    func splitViewDidResizeSubviews(_ notification: Notification) {
//        guard let window = window else { return }
//
//        if toolbarLeftMargin == nil {
//            return
//        }
//        let pos = toolbarPlayView.view.convert(toolbarPlayView.view.frame, to: nil).minX
//        print(toggleSideBarItem.view?.frame)
//        if sideBar.view.frame.size.width < toolbarLeftMarginMin {
//            toolbarLeftMargin.constant = toolbarLeftMarginMin// - pos
//
//            print("POS:", pos)
//            print("WINDOW:", window.frame, window.frame.minX)
//            print("VIEW:", toolbarPlayView.view.frame, toolbarPlayView.view.frame.minX)
//            print("SCREEN:", window.convertToScreen(toolbarPlayView.view.frame), window.convertToScreen(toolbarPlayView.view.frame).minX)
//            //        print(#function)
//        }
//        else {
//            toolbarLeftMargin.constant = toolbarLeftMarginMin2// - pos
//        }
    }

    /* ****************************************
     *
     * ****************************************/
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return subview == sideBar.view
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func sidebarChanged(_ sender: NSOutlineView) {
//        stationsView.item = sideBar.currentItem(); return
//
//        guard let item = sideBar.currentItem() else { return }
//
//        switch item.type {
//            case .local: showLocalItem(item)
//            case .radioBrowser: showInternetItem(item)
//        }
    }

    /* ****************************************
     *
     * ****************************************/
//    private func showLocalItem(_ item: SideBar.Item) {
//        if searchView != nil {
//            print("DELETING. BEFORE:", searchView)
//            searchView?.view.removeFromSuperview()
//            searchView?.removeFromParent()
//            searchView = nil
//            print("DELETING. AFTER:", searchView)
//        }
//
//        stationsView.stations = stationsStore.root
//    }

    /* ****************************************
     *
     * ****************************************/
//    private func showInternetItem(_ item: SideBar.Item) {
//        if searchView == nil {
//            searchView = SearchView()
//        }
//
//        searchView!.item = item
//        stationsView.stations = Group(name: "")
//
//        guard let view = searchView?.view else { return }
//        splitView.insertArrangedSubview(view, at: 1)
//
//
//    }

//    private func loadRadioBrowser(_ item: SideBar.Item) {
//        Task {
//            do {
//                let request = RadioBrowser.StationsRequest()
//                request.hidebroken = true
//                request.order = .votes
//
//                let res = try await request.get(bytag: "Classic Rock")
//                requestDone(res)
//
//            } catch {
//                print("Request failed with error: \(error)")
//            }
//        }
//    }

//    private func requestDone(_ resp: [RadioBrowser.Station]) {
//        print("DONE", resp.count)
//        var root = Group(name: "")
//        for r in resp {
//            var s = Station(name: r.name, url: r.url)
//            root.append(s)
//        }
//
//        stationsView.stations = root
//    }

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
