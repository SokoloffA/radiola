//
//  SideBar.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 23.08.2023.
//

import Cocoa

class SideBar: NSViewController {
    struct Group {
        let title: String
        var items: [Item]
    }

    struct Item {
        let title: String
        let icon: String
        let stations: StationList
    }

    private var groups: [Group] = {
        var res = [
            Group(title: "My lists",
                  items: [
                      Item(title: stationsStore.localStations.title, icon: "star", stations: stationsStore.localStations),
                  ]),

            Group(title: "Radio Browser",
                  items: [
//                      Item(title: "By tag", icon: "globe", stations: localStations),
//                      Item(title: "By genre", icon: "globe", stations: localStations),
//                      Item(title: "By language", icon: "globe", stations: localStations),
                  ]),
        ]

//        for it in savedRequests {
//            res[0].items.append(Item(title: it.title, icon: "globe", source: it))
//        }
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
    }

    /* ****************************************
     *
     * ****************************************/
    public func currentStations() -> StationList? {
        if let item = outlineView.item(atRow: outlineView.clickedRow) as? Item {
            return item.stations
        }
        return nil
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

        var res = 0
        for g in groups {
            res += 1 + g.items.count
        }

        return res
    }

    /* ****************************************
     * Returns the actual item
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item != nil {
            return item!
        }

        var n = index
        for g in groups {
            if n == 0 {
                return g
            }
            n -= 1

            if n < g.items.count {
                return g.items[n]
            }

            n -= g.items.count
        }
        return item!
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
        if let item = item as? Item {
            return SidebarSecondLevelView(title: item.title, icon: item.icon)
        }

        if let group = item as? Group {
            return SidebarTopLevelView(title: group.title)
        }

        return nil
    }

    /* ****************************************
     * Variable Row Heights
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if item is Item {
            return CGFloat(28.0)
        }

        if let group = item as? Group {
            if group.title == groups.first?.title {
                return CGFloat(14)
            }
            return CGFloat(32.0)
        }

        return 0
    }

    /* ****************************************
     *
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem: Any) -> Bool {
        return shouldSelectItem is Item
    }
}
