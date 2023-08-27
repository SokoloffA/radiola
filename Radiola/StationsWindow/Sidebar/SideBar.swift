//
//  SideBar.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 23.08.2023.
//

import Cocoa

class SideBar: NSViewController {
    struct Group {
        var title: String
        var items: [Item]
    }

    enum ItemType {
        case local
        case radioBrowser
    }

    struct Item {
        let type: ItemType
        let title: String
        let url: String
    }

    var groups: [Group] = [
        Group(title: "My lists", items: [
            Item(type: .local, title: "Local stations", url: "local://stations"),
        ]),

        Group(title: "Radio Browser", items: [
            Item(type: .radioBrowser, title: "By genre", url: "https://www.radio-browser.info/"),
            Item(type: .radioBrowser, title: "By language", url: "https://www.radio-browser.info/"),
        ]),
    ]

    @IBOutlet var outlineView: NSOutlineView!

    /* ****************************************
     *
     * ****************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        outlineView.delegate = self
        outlineView.dataSource = self
        outlineView.expandItem(nil, expandChildren: true)
    }

    /* ****************************************
     *
     * ****************************************/
    public func currentItem() -> Item? {
        if let item = outlineView.item(atRow: outlineView.clickedRow) as? Item {
            return item
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
            return SidebarSecondLevelView(item: item)
        }

        if let group = item as? Group {
            return SidebarTopLevelView(group: group)
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

    /* ****************************************
     *  Hide the disclosure triangle
     * ****************************************/
//    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
//        return false
//    }
}
