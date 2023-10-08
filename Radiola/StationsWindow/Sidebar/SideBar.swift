//
//  SideBar.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 23.08.2023.
//

import Cocoa

class SideBar: NSViewController {
    private class Item {
        var title: String
        var icon: String = ""
        let stations: StationList?
        let provider: SearchProvider?

        init(title: String, icon: String = "") {
            self.title = title
            self.icon = icon
            stations = nil
            provider = nil
        }

        init(title: String, icon: String, stations: StationList) {
            self.title = title
            self.icon = icon
            self.stations = stations
            provider = nil
        }

        init(title: String, icon: String, provider: SearchProvider) {
            self.title = title
            self.icon = icon
            stations = provider.stations
            self.provider = provider
        }

        func isGroup() -> Bool {
            return stations == nil && provider == nil
        }
    }

    private var items: [Item] = {
        var res: [Item] = []

        res.append(Item(title: "My lists"))
        res.append(Item(title: "Local stations", icon: "star", stations: stationsStore.localStations))

        res.append(Item(title: "Radio Browser"))
        for p in stationsStore.providers {
            res.append(Item(title: p.title, icon: "globe", provider: p))
        }

        return res
    }()

    @IBOutlet var outlineView: NSOutlineView!

    /* ****************************************
     *
     * ****************************************/
    override func viewDidLoad() {
        super.viewDidLoad()

        outlineView.delegate = self
        outlineView.dataSource = self
        outlineView.expandItem(nil, expandChildren: true)

        let indexSet = IndexSet(integer: findActiveIndex())
        outlineView.selectRowIndexes(indexSet, byExtendingSelection: false)
        outlineView.scrollRowToVisible(outlineView.selectedRow)
    }

    /* ****************************************
     *
     * ****************************************/
    private func findActiveIndex() -> Int {
        guard let cur = player.station else { return 1 }

        var n = 0
        for item in items {
            if item.stations?.contains(cur) ?? false {
                return n
            }
            n += 1
        }

        return 1
    }

    /* ****************************************
     *
     * ****************************************/
    public func currentStations() -> StationList? {
        guard let item = outlineView.item(atRow: outlineView.selectedRow) as? Item else { return nil }
        return item.stations
    }

    /* ****************************************
     *
     * ****************************************/
    public func currentProvider() -> SearchProvider? {
        guard let item = outlineView.item(atRow: outlineView.selectedRow) as? Item else { return nil }
        return item.provider
    }
}

extension SideBar: NSOutlineViewDataSource {
    /* ****************************************
     * Returns the number of child items each item in the outline
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item != nil {
            return 0
        }

        return items.count
    }

    /* ****************************************
     * Returns the actual item
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item != nil {
            return item!
        }

        return items[index]
    }

    /* ****************************************
     * We must specify if a given item should be expandable or not.
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
}

extension SideBar: NSOutlineViewDelegate {
    /* ****************************************
     *
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let item = item as? Item else { return nil }

        if item.isGroup() {
            return SidebarTopLevelView(title: item.title)
        } else {
            return SidebarSecondLevelView(title: item.title, icon: item.icon)
        }
    }

    /* ****************************************
     * Variable Row Heights
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        guard let item = item as? Item else { return 0.0 }

        if item.isGroup() {
            if item === items.first {
                return CGFloat(15)
            } else {
                return CGFloat(30.0)
            }
        }

        return CGFloat(28.0)
    }

    /* ****************************************
     *
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem: Any) -> Bool {
        return shouldSelectItem is Item
    }
}
