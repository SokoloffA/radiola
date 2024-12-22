//
//  MainMenuDelegate.swift
//  Radiola
//
//  Created by Alex Sokolov on 22.12.2024.
//

import Cocoa

// MARK: - MainMenuDelegate

class MainMenuDelegate: NSObject, NSMenuDelegate {
    static let Window = NSUserInterfaceItemIdentifier("window")
    static let Window_FloatOnTop = NSUserInterfaceItemIdentifier("window_floatOnTop")

    func menuNeedsUpdate(_ menu: NSMenu) {
        updateFloatOnTopItem(menu)
    }

    private func updateFloatOnTopItem(_ menu: NSMenu) {
        if let floatOnTopItem = menu.item(withIdentifier: MainMenuDelegate.Window_FloatOnTop) {
            floatOnTopItem.state = NSApp.keyWindow?.level == .floating ? .on : .off
        }
    }
}
