//
//  AlarmPopover.swift
//  Radiola
//
//  Created by Alex Sokolov on 21.01.2024.
//

import Cocoa

// MARK: - AlarmPopover

class AlarmPopover: NSViewController {
    var messageText = String()
    var informativeText = String()

    private var imageView = NSImageView()
    private var messageTextLabel = Label()
    private var informativeTextLabel = Label()
    private var okButton = NSButton()

    /* ****************************************
     *
     * ****************************************/
    override func viewDidLoad() {
        imageView.image = NSImage(named: NSImage.cautionName)
        imageView.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 251), for: .vertical)
        imageView.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 252), for: .horizontal)

        messageTextLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        messageTextLabel.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 251), for: .horizontal)
        messageTextLabel.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 750), for: .vertical)
        messageTextLabel.setFontWeight(.bold)

        informativeTextLabel.lineBreakMode = .byClipping

        okButton.bezelStyle = .rounded
        okButton.setButtonType(.momentaryPushIn)
        okButton.title = "Close"
        okButton.keyEquivalent = "\r"
        okButton.focusRingType = .default

        view.addSubview(imageView)
        view.addSubview(messageTextLabel)
        view.addSubview(informativeTextLabel)
        view.addSubview(okButton)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        messageTextLabel.translatesAutoresizingMaskIntoConstraints = false
        informativeTextLabel.translatesAutoresizingMaskIntoConstraints = false
        okButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -5),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 1 / 1),

            messageTextLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            messageTextLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16),
            messageTextLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            messageTextLabel.trailingAnchor.constraint(equalTo: informativeTextLabel.trailingAnchor),

            informativeTextLabel.topAnchor.constraint(equalTo: messageTextLabel.bottomAnchor, constant: 8),
            informativeTextLabel.leadingAnchor.constraint(equalTo: messageTextLabel.leadingAnchor),

            okButton.topAnchor.constraint(equalTo: informativeTextLabel.bottomAnchor, constant: 8),
            okButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15),
            okButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),

        ])
    }

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
