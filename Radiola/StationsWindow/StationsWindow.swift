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
    private var searchPanelHeight: CGFloat = 0.0
    private let stationsView = StationView()
    private var searchPanel = SearchPanel()
    private let toolbarPlayView = ToolbarPlayView()
    private let toolbarVolumeView = ToolbarVolumeView()
    private let toolbarLeftMargin = 145.0

    @IBOutlet var playtoolbar: NSView!
    @IBOutlet var stationToolbar: NSToolbar!
    @IBOutlet var searchViewPlace: NSView!
    @IBOutlet var stationsViewPlace: NSView!
    @IBOutlet var splitView: NSSplitView!
    @IBOutlet var toggleSideBarItem: NSToolbarItem!
    @IBOutlet var searchPanelHeightConstraint: NSLayoutConstraint!

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

        initSideBar()
        initPlaytoolbar()
        initSearchPanel()
        initStationsView()

        sidebarChanged()
    }

    /* ****************************************
     *
     * ****************************************/
    private func initSideBar() {
        toggleSideBarItem.target = self
        toggleSideBarItem.action = #selector(toggleSideBar)

        splitView.insertArrangedSubview(sideBar.view, at: 0)
        splitView.setHoldingPriority(NSLayoutConstraint.Priority(260), forSubviewAt: 0)
        splitView.autosaveName = "Stations Splitter"

        sideBar.outlineView.target = self
        sideBar.outlineView.action = #selector(sidebarChanged)
    }

    /* ****************************************
     *
     * ****************************************/
    private func initPlaytoolbar() {
        let playView = toolbarPlayView.view
        let volumeView = toolbarVolumeView.view
        playtoolbar.addSubview(playView)
        playtoolbar.addSubview(volumeView)

        playView.translatesAutoresizingMaskIntoConstraints = false
        volumeView.translatesAutoresizingMaskIntoConstraints = false
        playtoolbar.translatesAutoresizingMaskIntoConstraints = false

        playView.topAnchor.constraint(equalTo: playtoolbar.topAnchor).isActive = true
        playView.bottomAnchor.constraint(equalTo: playtoolbar.bottomAnchor).isActive = true
        volumeView.topAnchor.constraint(equalTo: playView.topAnchor).isActive = true
        volumeView.bottomAnchor.constraint(equalTo: playView.bottomAnchor).isActive = true

        let cnst = playView.leadingAnchor.constraint(equalTo: playtoolbar.leadingAnchor)
        cnst.priority = NSLayoutConstraint.Priority(999)
        cnst.isActive = true
        if let contentView = window?.contentView {
            playView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: toolbarLeftMargin).isActive = true
        }

        playView.trailingAnchor.constraint(equalTo: volumeView.leadingAnchor).isActive = true
        volumeView.leadingAnchor.constraint(equalTo: playView.trailingAnchor).isActive = true
        volumeView.trailingAnchor.constraint(equalTo: playtoolbar.trailingAnchor).isActive = true
    }

    /* ****************************************
     *
     * ****************************************/
    private func initSearchPanel() {
        searchPanelHeight = searchViewPlace.frame.height
        searchViewPlace.addSubview(searchPanel.view)
        searchPanel.view.topAnchor.constraint(equalTo: searchViewPlace.topAnchor).isActive = true
        searchPanel.view.bottomAnchor.constraint(equalTo: searchViewPlace.bottomAnchor).isActive = true
        searchPanel.view.leadingAnchor.constraint(equalTo: searchViewPlace.leadingAnchor).isActive = true
        searchPanel.view.trailingAnchor.constraint(equalTo: searchViewPlace.trailingAnchor).isActive = true
    }

    /* ****************************************
     *
     * ****************************************/
    private func initStationsView() {
        stationsView.translatesAutoresizingMaskIntoConstraints = false
        stationsViewPlace.addSubview(stationsView)
        stationsView.topAnchor.constraint(equalTo: stationsViewPlace.topAnchor).isActive = true
        stationsView.bottomAnchor.constraint(equalTo: stationsViewPlace.bottomAnchor).isActive = true
        stationsView.leadingAnchor.constraint(equalTo: stationsViewPlace.leadingAnchor).isActive = true
        stationsView.trailingAnchor.constraint(equalTo: stationsViewPlace.trailingAnchor).isActive = true
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
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return subview == sideBar.view
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func sidebarChanged() {
        stationsView.stations = sideBar.currentStations()

        if let provider = sideBar.currentStations() as? SearchableStationList {
            searchPanelHeightConstraint.constant = searchPanelHeight
            searchPanel.provider = provider
            provider.fetchHandler = stationsFound
            if provider.nodes.isEmpty {
                _ = searchPanel.becomeFirstResponder()
            }
            else {
                _ = stationsView.becomeFirstResponder()
            }
        } else {
            searchPanelHeightConstraint.constant = 0
            searchPanel.provider = nil
            _ = stationsView.becomeFirstResponder()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func stationsFound(stations: SearchableStationList) {
        if stations !== sideBar.currentStations() {
            return
        }

        stationsView.stations = stations
        _ = stationsView.becomeFirstResponder()
    }
}
