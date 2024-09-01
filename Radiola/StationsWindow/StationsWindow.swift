//
//  StationsWindow.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 05.07.2022.
//

import Cocoa
import Combine

fileprivate var selectedListId: UUID? = AppState.shared.localStations.first?.id
fileprivate var selectedRows: [UUID: Int] = [:]

class StationsWindow: NSWindowController, NSWindowDelegate, NSSplitViewDelegate {
    private static var instance: StationsWindow?
    var sideBar = SideBar()
    var sideBarWidth: CGFloat = 0.0
    private var searchPanelHeight: CGFloat = 0.0
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
    @IBOutlet var stateIndicator: NSView!
    @IBOutlet var stateIndicatorText: NSTextField!
    @IBOutlet var stateIndicatorSpinner: NSProgressIndicator!

    private var localStationsDelegate: LocalStationDelegate!
    private var internetStationsDelegate: InternetStationDelegate!

    private var toolBox: NSView? { didSet { placeToolbox() } }
    private var searchPanel: NSView? { didSet { placeSearchPanel() }}

    private var listStateSink: AnyCancellable?

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

        window?.toolbar?.allowsUserCustomization = false

        localStationsDelegate = LocalStationDelegate(outlineView: stationsTree)
        internetStationsDelegate = InternetStationDelegate(outlineView: stationsTree)

        stationsTree.doubleAction = #selector(doubleClickRow)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(selectionChanged),
                                               name: NSOutlineView.selectionDidChangeNotification,
                                               object: nil)

        splitView.delegate = self

        initSideBar()
        initPlaytoolbar()
        searchPanelHeight = searchViewPlace.frame.height

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
    private func placeSearchPanel() {
        for v in searchViewPlace.subviews {
            v.removeFromSuperview()
        }

        guard let searchPanel = searchPanel else {
            searchViewPlace.isHidden = true
            searchPanelHeightConstraint.constant = 0
            return
        }

        searchViewPlace.addSubview(searchPanel)

        searchPanel.translatesAutoresizingMaskIntoConstraints = false
        searchPanel.leadingAnchor.constraint(equalTo: searchViewPlace.leadingAnchor).isActive = true
        searchPanel.trailingAnchor.constraint(equalTo: searchViewPlace.trailingAnchor).isActive = true
        searchPanel.topAnchor.constraint(equalTo: searchViewPlace.topAnchor).isActive = true
        searchPanel.bottomAnchor.constraint(equalTo: searchViewPlace.bottomAnchor).isActive = true

        searchViewPlace.isHidden = false
        searchPanelHeightConstraint.constant = searchPanelHeight
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

        instance?.window?.show()
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
    private func setFocus(listId: UUID, toTree: Bool) {
        if toTree {
            // Move focus to stationsTree
            let n = selectedRows[listId] ?? max(0, stationsTree.row(forItem: player.station))
            stationsTree.selectRowIndexes(IndexSet(arrayLiteral: n), byExtendingSelection: true)
            stationsTree.scrollRowToVisible(stationsTree.selectedRow)
            stationsTree.superview?.becomeFirstResponder()
            return
        }

        if let searchPanel = searchPanel {
            searchPanel.becomeFirstResponder()
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
            setFocus(listId: listId, toTree: true)
            updateStateIndicator(state: .notLoaded)
        } else if let list = AppState.shared.internetStations.find(byId: listId) {
            setInternetStationList(list: list)
            setFocus(listId: listId, toTree: !list.items.isEmpty)
            updateStateIndicator(state: list.state)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func setLocalStationList(list: any StationList) {
        stationsTree.delegate = localStationsDelegate
        stationsTree.dataSource = localStationsDelegate
        localStationsDelegate.list = list

        stationsTree.reloadItem(nil, reloadChildren: true)
        stationsTree.expandItem(nil, expandChildren: true)

        searchPanel = nil

        let toolBox = LocalStationToolBox()
        toolBox.addStationButton.target = self
        toolBox.addStationButton.action = #selector(addStation)

        toolBox.addGroupButton.target = self
        toolBox.addGroupButton.action = #selector(addGroup)

        toolBox.delButton.target = self
        toolBox.delButton.action = #selector(removeStation)

        self.toolBox = toolBox
    }

    /* ****************************************
     *
     * ****************************************/
    private func setInternetStationList(list: InternetStationList) {
        stationsTree.delegate = internetStationsDelegate
        stationsTree.dataSource = internetStationsDelegate
        internetStationsDelegate.list = list

        stationsTree.reloadItem(nil, reloadChildren: true)

        let searchPanel = InternetStationSearchPanel(provider: list.provider)
        searchPanel.target = internetStationsDelegate
        searchPanel.action = #selector(internetStationsDelegate.search)

        listStateSink?.cancel()
        listStateSink = list.$state.sink(receiveValue: updateStateIndicator)

        self.searchPanel = searchPanel
    }

    /* ****************************************
     *
     * ****************************************/
    private func updateStateIndicator(state: InternetStationList.State) {
        guard
            let delegate = stationsTree.delegate as? InternetStationDelegate,
            let list = delegate.list
        else {
            stateIndicator.isHidden = true
            stateIndicatorSpinner.stopAnimation(nil)
            return
        }

        switch (state, list.items.isEmpty) {
            case (.notLoaded, _):
                stateIndicator.isHidden = true
                stateIndicatorSpinner.stopAnimation(nil)

            case (.loading, _):
                stateIndicatorText.stringValue = "Loading"
                stateIndicator.isHidden = false
                stateIndicatorSpinner.isHidden = false
                stateIndicatorSpinner.startAnimation(nil)

            case (.error, _):
                stateIndicator.isHidden = true
                stateIndicatorSpinner.stopAnimation(nil)

            case (.loaded, true):
                stateIndicatorSpinner.stopAnimation(nil)
                stateIndicatorSpinner.isHidden = true
                stateIndicator.isHidden = false
                stateIndicatorText.stringValue = "No results"

            case (.loaded, false):
                stateIndicatorSpinner.stopAnimation(nil)
                stateIndicator.isHidden = true
        }
    }

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
            case #selector(exportStations): return stationsTree.delegate is LocalStationDelegate
            case #selector(importStations): return stationsTree.delegate is LocalStationDelegate
           // case #selector(copySongToClipboard): return player.songTitle != ""

            default: return true
        }
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
        guard
            let delegate = stationsTree.delegate as? LocalStationDelegate,
            let window = window,
            let item = stationsTree.item(atRow: stationsTree.selectedRow)
        else {
            return
        }

        var messageText = ""
        if let station = item as? Station {
            messageText = "Are you sure you want to remove the station \"\(station.title)\"?"
        } else if let group = item as? StationGroup {
            if group.items.isEmpty {
                messageText = "Are you sure you want to remove the group \"\(group.title)\"?"
            } else {
                messageText = "Are you sure you want to remove the group \"\(group.title)\", and all of its children?"
            }
        }

        let alert = NSAlert()
        alert.informativeText = "This operation cannot be undone."
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = messageText
        alert.beginSheetModal(for: window, completionHandler: { response in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                delegate.remove(item: item)
            }
        })
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func exportStations(_ sender: Any) {
        guard
            let window = window,
            let listID = sideBar.selectedListId,
            let stations = AppState.shared.localStations.find(byId: listID)
        else {
            return
        }

        let dialog = NSSavePanel()
        dialog.allowedFileTypes = ["opml"]
        dialog.allowsOtherFileTypes = true
        dialog.canCreateDirectories = true
        dialog.isExtensionHidden = false
        dialog.nameFieldStringValue = "RadiolaStations[\(stations.title)]"

        dialog.beginSheetModal(for: window) { result in
            guard result == .OK, let url = dialog.url else { return }
            do {
                try stations.saveAsOpml(file: url)
            } catch {
                error.show()
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func importStations(_ sender: Any) {
        guard
            let window = window,
            let listID = sideBar.selectedListId,
            let list = AppState.shared.localStations.find(byId: listID)
        else {
            return
        }

        let dialog = NSOpenPanel()
        dialog.allowedFileTypes = ["opml"]
        dialog.allowsOtherFileTypes = true
        dialog.isExtensionHidden = false
        dialog.nameFieldStringValue = "RadiolaStations"

        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = false
        dialog.canChooseFiles = true

        dialog.beginSheetModal(for: window) { result in
            guard result == .OK, let url = dialog.url else { return }

            dialog.close()
            self.doImportStations(url: url, list: list)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func doImportStations(url: URL, list: StationList) {
        guard let window = window else { return }

        let new = OpmlStations(title: "", icon: "")
        do {
            try new.load(file: url)
        } catch {
            error.show()
            return
        }

        let merger = StationsMerger(currentStations: list, newStations: new)
        if merger.statistics.isEmpty {
            NSAlert.showInfo(message: "The file does not contain any new or changed radio stations.", informativeText: "You may have already exported it before.")
            return
        }

        var message = ""
        if merger.statistics.insertedStations != 0 && merger.statistics.updatedStations != 0 {
            message = String(format: "%d stations will be added and %d stations will be updated.", merger.statistics.insertedStations, merger.statistics.updatedStations)
        } else if merger.statistics.insertedStations != 0 {
            message = String(format: "%d stations will be added.", merger.statistics.insertedStations)
        } else if merger.statistics.updatedStations != 0 {
            message = String(format: "%d stations will be updated.", merger.statistics.updatedStations)
        }

        let alert = NSAlert()
        alert.informativeText = message
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = "Are you sure you want to continue?"
        alert.beginSheetModal(for: window, completionHandler: { response in
            if response != NSApplication.ModalResponse.alertFirstButtonReturn {
                return
            }
            merger.run()
            list.dump()
            list.save()
            self.stationsTree.reloadData()
        })
    }
}
