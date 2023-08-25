//
//  SideBar.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 23.08.2023.
//

import Cocoa

class SideBar: NSViewController {
    enum ItemType {
        case top
        case local
        case link
    }

    struct Item {
        var type: ItemType
        var title: String
        var url: String = ""
//        var items: [Item] = []
    }

    var items: [Item] = [
        Item(type: .top, title: "My lists"),
        Item(type: .local, title: "Local stations"),

        Item(type: .top,  title: "RadioBrowser"),
        Item(type: .link, title: "By genre"),
        Item(type: .link, title: "By language"),
    ]

    @IBOutlet var outlineView: NSOutlineView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        outlineView.delegate = self
        outlineView.dataSource = self
        outlineView.expandItem( nil, expandChildren: true)
    }
}

extension SideBar: NSOutlineViewDataSource {
    /* ****************************************
     * Returns the number of child items each item in the outline
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        // Root item
        //print(#function)

        if item == nil {
            return items.count
        }

//        if let item = item as? Item {
//            print(#function, #line, item.items.count)
//            return item.items.count
//        }

        return 0
    }

    /* ****************************************
     * Returns the actual item
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        //print(#function)
        // Root item
        if item == nil {
            return items[index]
        }

//        if let item = item as? Item {
//            return item.items[index]
//        }
//        if let group = item as? Group {
//            if index < group.nodes.count {
//                return group.nodes[index]
//            }
//        }

        return item!
    }

    /* ****************************************
     * We must specify if a given item should be expandable or not.
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
//        //print(#function)
//        if let item = item as? Item {
//            return !item.items.isEmpty
//        }
//
//        return false
    }
}

extension SideBar: NSOutlineViewDelegate {
    /* ****************************************
     *
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let item = item as? Item else { return nil }

        if item.type == .top {
            return SidebarTopLevelView(item: item)
        }

        return SidebarSecondLevelView(item: item)
    }
    
//    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem: Any) -> Bool {
//        //print(#function)
//        return true
////        if let item = item as? Item {
////            return
////        }
//    }
    
//    func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem: Any) -> Bool {
//        //print(#function)
//        return false
////        if let item = item as? Item {
////            return
////        }
//    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem: Any) -> Bool {
        //print(#function)
        guard let item = shouldSelectItem as? Item else { return false }

        return item.type != .top
//        if let item = item as? Item {
//            return
//        }

    }
    
    /* ****************************************
     *  Hide the disclosure triangle
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        print(#function)
        return false
    }
    
    /* ****************************************
     * Variable Row Heights
     * ****************************************/
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        guard let item = item as? Item else { return CGFloat(138.0) }
        
        if item.type == .top {
            return CGFloat(38.0)
        }
        else {
           return  CGFloat(28.0)
        }
    }
}
