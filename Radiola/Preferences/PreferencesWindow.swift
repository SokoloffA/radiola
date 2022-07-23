//
//  PreferencesWindow.swift
//  Radiola
//
//  Created by Alex Sokolov on 23.07.2022.
//

import Cocoa

class PreferencesWindow: NSWindowController, NSTabViewDelegate {
    private class ViewController: NSTabViewController {
        weak var wnd: NSWindow?
        override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
            wnd?.title = tabViewItem?.label ?? ""
        }
    }

    private var viewController: ViewController!
    init() {
        viewController = ViewController()
        super.init(window: NSWindow(contentViewController: viewController))
        self.windowFrameAutosaveName = "PreferencesWindow"
        
        var tab = NSTabViewItem(viewController: GeneralPage())
        tab.label = "General"
        tab.image = NSImage(named: NSImage.preferencesGeneralName)
        viewController.addTabViewItem(tab)

        tab = NSTabViewItem(viewController: UpdatePanel())
        tab.label = "Update"
        tab.image = NSImage(named: NSImage.networkName)// touchBarDownloadTemplateName)
        viewController.addTabViewItem(tab)
        
        viewController.tabStyle = .toolbar
        contentViewController = viewController
        viewController.wnd = window
    }
    
    /* ****************************************
     *
     * ****************************************/
    func windowWillClose(_ notification: Notification) {
        PreferencesWindow.instance = nil
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private static var instance: PreferencesWindow?
    class func show() -> PreferencesWindow {
        if instance == nil {
            instance = PreferencesWindow()
        }

        NSApp.setActivationPolicy(.regular)
        instance?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        return instance!
    }
    
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
            print("QQQQQ")
    }
//    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?){
//        print(tabViewItem?.label)
//        window?.title = "wwww"
//    }
//    private refresh() {
//        viewController.   viewController.selectedTabViewItemIndex
//    }
}

class PreferencesViewController: NSTabViewController {
    override func viewDidLoad() {
        tabStyle = .toolbar
        addChild(UpdatePanel())
    }
}
