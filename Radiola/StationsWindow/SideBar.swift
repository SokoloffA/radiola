//
//  SideBar.swift
//  Radiola
//
//  Created by Alex Sokolov on 20.08.2023.
//

import Cocoa

class SideBarView: NSView {
    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _ = load(fromNIBNamed: "SideBar")

        // self.wantsLayer = true
//        print(self.wantsLayer, self.layer,         treeView.layer,         treeView.layer?.backgroundColor)

        //      self.layer?.backgroundColor = treeView.backgroundColor.cgColor // NSColor.green.cgColor
//
        // self.layer?.backgroundColor = NSColor.green.cgColor
//        self.view
        // NSColor._sourceListBackgroundColor
        // let c   = _sourceListBackgroundColor
        //    print(type(of:  treeView.backgroundColor),  treeView.backgroundColor)
    }

    /* ****************************************
     *
     * ****************************************/
//    init() {
//        super.init(frame: NSRect.zero)
//        print(#function)
//        print("QQQQQQQ")
//
//    }
}

class SideBarController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        print(#function)
        // Do view setup here.
    }
}
