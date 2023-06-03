//
//  HistoryWindow.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 05.07.2022.
//

import Cocoa

class HistoryWindow: NSWindowController, NSWindowDelegate {
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var placeholderLabel: NSTextField!

    /* ****************************************
     *
     * ****************************************/
    override var windowNibName: String! {
        return "HistoryWindow"
    }

    /* ****************************************
     *
     * ****************************************/
    override func windowDidLoad() {
        super.windowDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: Notification.Name.PlayerMetadataChanged,
            object: nil)

        refresh()
    }

    /* ****************************************
     *
     * ****************************************/
    func windowWillClose(_ notification: Notification) {
        HistoryWindow.instance = nil
    }

    /* ****************************************
     *
     * ****************************************/
    private static var instance: HistoryWindow?
    class func show() -> HistoryWindow {
        if instance == nil {
            instance = HistoryWindow()
        }

        NSApp.setActivationPolicy(.regular)
        instance?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        return instance!
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func refresh() {
        tableView.reloadData()

        if tableView.numberOfRows > 0 {
            placeholderLabel.isHidden = true
            let indexSet = IndexSet(integer: 0)
            tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
            tableView.scrollRowToVisible(tableView.selectedRow)
        } else {
            placeholderLabel.isHidden = false
            placeholderLabel.layer?.zPosition = 1
        }
    }
}

extension HistoryWindow: NSTableViewDelegate {
    /* ****************************************
     *
     * ****************************************/
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return HistoryRow(history: player.history[player.history.count - row - 1])
    }
}

extension HistoryWindow: NSTableViewDataSource {
    /* ****************************************
     *
     * ****************************************/
    func numberOfRows(in tableView: NSTableView) -> Int {
        return player.history.count
    }
}
