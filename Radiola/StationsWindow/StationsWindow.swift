//
//  StationsWindow.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 05.07.2022.
//

import Cocoa

fileprivate var selectedListId: UUID? = AppState.shared.localStations.first?.id
fileprivate var selectedRows: [UUID: Int] = [:]

class StationsWindow: NSWindowController, NSWindowDelegate, NSSplitViewDelegate {
    private static var instance: StationsWindow?
    var sideBar = SideBar()
    var sideBarWidth: CGFloat = 0.0
    private var searchPanelHeight: CGFloat = 0.0
    // private var searchPanel = SearchPanel()
    private let toolbarPlayView = ToolbarPlayView()
    private let toolbarVolumeView = ToolbarVolumeView()
    private let toolbarLeftMargin = 145.0

    @IBOutlet var stationsTree: NSOutlineView!
    @IBOutlet var playtoolbar: NSView!
    @IBOutlet var stationToolbar: NSToolbar!
    @IBOutlet var searchViewPlace: NSView!
    @IBOutlet var stationsViewPlace: NSView!
    @IBOutlet var splitView: NSSplitView!
    @IBOutlet var toggleSideBarItem: NSToolbarItem!
    @IBOutlet var searchPanelHeightConstraint: NSLayoutConstraint!
    @IBOutlet var toolBoxPlace: NSView!

    private var localStationsDelegate: LocalStationDelegate!
    private var toolBox: NSView? { didSet { placeToolbox() } }

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

        localStationsDelegate = LocalStationDelegate(outlineView: stationsTree)

        // localStationsDelegate
        //

        stationsTree.doubleAction = #selector(doubleClickRow)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(selectionChanged),
                                               name: NSOutlineView.selectionDidChangeNotification,
                                               object: nil)

        splitView.delegate = self

        initSideBar()
        initPlaytoolbar()
        initSearchPanel()

        sidebarChanged()
    }

    /* ****************************************
     *
     * ****************************************/
    private func initSideBar() {
        let appState = AppState.shared

        sideBar.addGroup(title: "My lists")
        for list in appState.localStations {
            sideBar.addItem(id: list.id, title: list.title, icon: list.icon)
        }

        sideBar.addGroup(title: "Radio browser")
        for list in appState.internetStations {
            sideBar.addItem(id: list.id, title: list.title, icon: list.icon)
        }

        sideBar.selectedListId = selectedListId
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
//        searchViewPlace.addSubview(searchPanel.view)
//        searchPanel.view.topAnchor.constraint(equalTo: searchViewPlace.topAnchor).isActive = true
//        searchPanel.view.bottomAnchor.constraint(equalTo: searchViewPlace.bottomAnchor).isActive = true
//        searchPanel.view.leadingAnchor.constraint(equalTo: searchViewPlace.leadingAnchor).isActive = true
//        searchPanel.view.trailingAnchor.constraint(equalTo: searchViewPlace.trailingAnchor).isActive = true
    }

    /* ****************************************
     *
     * ****************************************/
    private func placeToolbox() {
        for v in toolBoxPlace.subviews {
            v.removeFromSuperview()
        }

        if let toolBox = toolBox {
            toolBoxPlace.addSubview(toolBox)
            toolBox.frame = toolBoxPlace.frame
            toolBox.autoresizingMask = [.height, .width]
        }
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
    @objc func selectionChanged() {
        if let listId = sideBar.selectedListId {
            selectedRows[listId] = stationsTree.selectedRowIndexes.first
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func sidebarChanged() {
        selectedListId = sideBar.selectedListId
        stationsTree.delegate = nil
        stationsTree.dataSource = nil
        toolBox = nil

        guard let listId = selectedListId else {
            return
        }

        if let list = AppState.shared.localStations.find(byId: listId) {
            setLocalStationList(list: list)
        } else {
            toolBox = nil
            return
        }
//        stationsView.stations = sideBar.currentStations()
//
//        if let provider = sideBar.currentStations() as? InternetStationList_OLD {
//            stationsTree.delegate = nil
//            stationsTree.dataSource = nil
        ////            searchPanelHeightConstraint.constant = searchPanelHeight
        ////            searchPanel.provider = provider
        ////            provider.fetchHandler = stationsFound
        ////            if provider.nodes.isEmpty {
        ////                _ = searchPanel.becomeFirstResponder()
        ////            } else {
        ////                _ = stationsView.becomeFirstResponder()
        ////            }
//        } else {
//            setLocalStationList(list: sideBar.currentStations()!)
//        }
//
//        let n = selectedRows[list.id] ?? max(0, stationsTree.row(forItem: player.station))
//        stationsTree.selectRowIndexes(IndexSet(arrayLiteral: n), byExtendingSelection: true)
//        stationsTree.scrollRowToVisible(stationsTree.selectedRow)
    }

    /* ****************************************
     *
     * ****************************************/
    private func setLocalStationList(list: LocalStationList) {
        stationsTree.delegate = localStationsDelegate
        stationsTree.dataSource = localStationsDelegate
        localStationsDelegate.list = list
        stationsTree.reloadItem(nil, reloadChildren: true)
        stationsTree.expandItem(nil, expandChildren: true)

        searchViewPlace.isHidden = true
        searchPanelHeightConstraint.constant = 0
//            searchPanel.provider = nil
//        stationsTree.registerForDraggedTypes([localStationsDelegate.nodePasteboardType])
//        stationsTree.selectionHighlightStyle = .regular

        // stationsTree.superview?.becomeFirstResponder()

        toolBox = LocalStationToolBox()

        // localStationToolBox.nextResponder = toolBoxPlace
//        print(toolBoxPlace.nextResponder, toolBoxPlace.superview)
        // self.nextResponder = localStationToolBox
    }

    /* ****************************************
     *
     * ****************************************/
//    private func stationsFound(stations: InternetStationList_OLD) {
//        if stations !== sideBar.currentStations() {
//            return
//        }
//
    ////        stationsView.stations = stations
    ////        _ = stationsView.becomeFirstResponder()
//    }

    /* ****************************************
     *
     * ****************************************/
    @objc func doubleClickRow(sender: AnyObject) {
        guard let station = stationsTree.item(atRow: stationsTree.selectedRow) as? Station else { return }

        if player.station?.id == station.id && player.isPlaying {
            return
        }

        player.station = station
        player.play()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func addStation(_ sender: Any) {
        guard let delegate = stationsTree.delegate as? LocalStationDelegate else { return }

        let dialog = AddStationDialog()
        window?.beginSheet(dialog.window!, completionHandler: { response in
            if response != NSApplication.ModalResponse.OK || dialog.url.isEmpty {
                return
            }

            delegate.addStation(title: dialog.title, url: dialog.url)
        })
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func addGroup(_ sender: Any) {
        guard let delegate = stationsTree.delegate as? LocalStationDelegate else { return }

        let dialog = AddGroupDialog()
        window?.beginSheet(dialog.window!, completionHandler: { response in
            if response != NSApplication.ModalResponse.OK {
                return
            }

            delegate.addGroup(title: dialog.title)
        })
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func removeStation(_ sender: Any) {
        /*
         guard let stations = stations as? LocalStationList else { return }
         if !isEditable { return }

         guard let wnd = window else { return }
         guard let node = selectedNode() else { return }
         guard let parent = node.parent else { return }

         let alert = NSAlert()
         alert.informativeText = "This operation cannot be undone."
         alert.addButton(withTitle: "Yes")
         alert.addButton(withTitle: "Cancel")

         if let station = node as? Station {
             alert.messageText = "Are you sure you want to remove the station \"\(station.title)\"?"
         }

         if let group = node as? StationGroup {
             if group.nodes.isEmpty {
                 alert.messageText = "Are you sure you want to remove the group \"\(group.title)\"?"
             } else {
                 alert.messageText = "Are you sure you want to remove the group \"\(group.title)\", and all of its children?"
             }
         }

         alert.beginSheetModal(for: wnd, completionHandler: { response in
             if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                 let n = parent.index(node) ?? 0
                 parent.remove(node)
                 stations.save()

                 self.stationsTree.beginUpdates()
                 self.stationsTree.removeItems(
                     at: IndexSet(integer: n),
                     inParent: parent !== stations ? parent : nil,
                     withAnimation: .effectFade)
                 self.stationsTree.endUpdates()
                 self.stationsTree.reloadItem(parent !== stations ? parent : nil)

                 if !parent.nodes.isEmpty {
                     let row = self.stationsTree.row(forItem: parent.nodes[min(n, parent.nodes.count - 1)])
                     self.stationsTree.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                 } else {
                     let row = self.stationsTree.row(forItem: parent)
                     self.stationsTree.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                 }
             }
         })
          */
    }
}

extension StationsWindow: NSUserInterfaceValidations {
    /* ****************************************
     *
     * ****************************************/
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        switch item.action {
            case #selector(addStation): return stationsTree.delegate is LocalStationDelegate
            case #selector(addGroup): return stationsTree.delegate is LocalStationDelegate
            case #selector(removeStation): return stationsTree.delegate is LocalStationDelegate
            //      case #selector(addStationToLocalList): return stationsTree.delegate is LocalStationDelegate
            default: return true
        }
    }

    /* ****************************************
     *
     * ****************************************/
//    @objc func addStationToLocalList(_ sender: Any) {
//        guard let src = selectedStation() else { return }
//
//        let destTitle = stationsStore.localStations.title
//
//        if stationsStore.localStations.station(byUrl: src.url) != nil {
//            NSAlert.showWarning(message: "Looks like such station is already on \"\(destTitle)\" list.")
//            return
//        }
//        let station = Station(title: src.title, url: src.url)
//        stationsStore.localStations.append(station)
//        stationsStore.localStations.save()
//
//        NSAlert.showInfo(message: "Station \"\(station.title)\" has been successfully added to the \"\(destTitle)\".")
//    }
}
