//
//  AlarmPopover.swift
//  Radiola
//
//  Created by Alex Sokolov on 26.11.2023.
//

import Cocoa

class AlarmPopover: NSViewController {
    @IBOutlet private var messageTextLabel: NSTextField!
    @IBOutlet private var informativeTextLabel: NSTextField!
    @IBOutlet private var okButton: NSButton!

    var messageText = String()
    var informativeText = String()

    /* ****************************************
     *
     * ****************************************/
    open func show(relativeTo positioningRect: NSRect, of positioningView: NSView, preferredEdge: NSRectEdge = NSRectEdge.minY) {
        let popover = NSPopover()
        popover.contentViewController = self
        popover.contentSize = view.frame.size
        popover.behavior = .transient
        popover.animates = true

        messageTextLabel.stringValue = messageText
        informativeTextLabel.stringValue = informativeText
        okButton.target = popover
        okButton.action = #selector(NSPopover.performClose)

        popover.show(relativeTo: positioningRect, of: positioningView, preferredEdge: preferredEdge)
    }

    /* ****************************************
     *
     * ****************************************/
    open func show(of positioningView: NSView, preferredEdge: NSRectEdge = NSRectEdge.minY) {
        show(relativeTo: positioningView.bounds, of: positioningView, preferredEdge: preferredEdge)
    }
}
