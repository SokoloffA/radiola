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
    @IBOutlet var onlyFavoriteCheckbox: NSButton!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!

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

        window?.title = NSLocalizedString("History", comment: "History window title")
        placeholderLabel.stringValue = NSLocalizedString("No records yet", comment: "History window placeholder")
        onlyFavoriteCheckbox.title = NSLocalizedString("Show only your favorite songs", comment: "History window checkbox title")

        tableView.delegate = self
        tableView.dataSource = self
        tableView.style = .inset

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: Notification.Name.PlayerMetadataChanged,
            object: nil)

        onlyFavoriteCheckbox.target = self
        onlyFavoriteCheckbox.action = #selector(refresh)

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
    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        bottomConstraint.isActive = window.frame.height > 250
        onlyFavoriteCheckbox.isHidden = !bottomConstraint.isActive
    }

    /* ****************************************
     *
     * ****************************************/
    private static var instance: HistoryWindow?
    class func show() -> HistoryWindow {
        if instance == nil {
            instance = HistoryWindow()
        }

        instance?.window?.show()
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
        let list = onlyFavoriteCheckbox.state == .on ?
            AppState.shared.history.favorites() :
            AppState.shared.history.records

        if row >= list.count {
            return nil
        }

        return HistoryRow(history: list[list.count - row - 1])
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func exportHistory(_ sender: Any?) {
        guard
            let window = window
        else {
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd-HH.mm.ss"
        let dateStr = formatter.string(from: Date())

        let dialog = NSSavePanel()
        dialog.allowedFileTypes = ["csv"]
        dialog.allowsOtherFileTypes = true
        dialog.canCreateDirectories = true
        dialog.isExtensionHidden = false
        dialog.nameFieldStringValue = "RadiolaHistory-\(dateStr)"

        dialog.beginSheetModal(for: window) { result in
            guard result == .OK, let url = dialog.url else { return }
            do {
                try AppState.shared.history.exportToCSV(file: url)
            } catch {
                error.show()
            }
        }
    }
}

extension HistoryWindow: NSTableViewDataSource {
    /* ****************************************
     *
     * ****************************************/
    func numberOfRows(in tableView: NSTableView) -> Int {
        return onlyFavoriteCheckbox.state == .on ?
            AppState.shared.history.favorites().count :
            AppState.shared.history.records.count
    }
}
