//
//  SideBar.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 23.08.2023.
//

import Cocoa

// MARK: - SideBar

class SideBar: NSViewController {
    private var initListId: UUID?
    var selectedListId: UUID? {
        get { getSelectedListId() }
        set { setSelectedListId(newValue) }
    }

    struct Item {
        let id: UUID
        var title: String
        var icon: String = ""
        let isGroup: Bool
    }

    var items = [Item]()

    @IBOutlet var outlineView: NSOutlineView!

    /* ****************************************
     *
     * ****************************************/
    func addGroup(title: String, icon: String = "") {
        items.append(Item(id: UUID(), title: title, icon: icon, isGroup: true))
    }

    /* ****************************************
     *
     * ****************************************/
    func addItem(id: UUID, title: String, icon: String = "") {
        items.append(Item(id: id, title: title, icon: icon, isGroup: false))
    }

    /* ****************************************
     *
     * ****************************************/
    override func viewDidLoad() {
        super.viewDidLoad()

        outlineView.delegate = self
        outlineView.dataSource = self
        outlineView.expandItem(nil, expandChildren: true)

        setSelectedListId(initListId)
    }

    /* ****************************************
     *
     * ****************************************/
    private func getSelectedListId() -> UUID? {
        if outlineView == nil {
            return initListId
        }

        if outlineView.selectedRow < 0 {
            return initListId
        }

        return items[outlineView.selectedRow].id
    }

    /* ****************************************
     *
     * ****************************************/
    private func setSelectedListId(_ id: UUID?) {
        if outlineView == nil {
            initListId = id
            return
        }

        for (i, item) in items.enumerated() {
            if !item.isGroup && item.id == id {
                let indexSet = IndexSet(integer: i)
                outlineView.selectRowIndexes(indexSet, byExtendingSelection: false)
                outlineView.scrollRowToVisible(outlineView.selectedRow)
            }
        }
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

        if item.isGroup {
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

        if item.isGroup {
            if item.id == items.first?.id {
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
        guard let item = shouldSelectItem as? Item else { return false }
        return !item.isGroup
    }
}
