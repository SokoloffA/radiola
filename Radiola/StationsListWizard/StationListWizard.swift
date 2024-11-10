//
//  StationListWizard.swift
//  Radiola
//
//  Created by Alex Sokolov on 10.11.2024.
//

import Cocoa

// MARK: - StationListWizard

class StationListWizard: NSWindowController {
    private let topLabel = Label()
    private let bottomLabel = Label()
    private var cloudRadioButton = NSButton(radioButtonWithTitle: "", target: nil, action: nil)
    private var opmlRadioButton = NSButton(radioButtonWithTitle: "", target: nil, action: nil)
    private var bothRadioButton = NSButton(radioButtonWithTitle: "", target: nil, action: nil)
    private let okButton = NSButton()

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(window: nil)

        let window = NSWindow(contentRect: NSMakeRect(0, 0, 0, 0),
                              styleMask: [.titled],
                              backing: .buffered, defer: false)
        self.window = window
        window.title = "Radiola"

        createViews()

        cloudRadioButton.target = self
        cloudRadioButton.action = #selector(radioButtonChanged)

        opmlRadioButton.target = self
        opmlRadioButton.action = #selector(radioButtonChanged)

        bothRadioButton.target = self
        bothRadioButton.action = #selector(radioButtonChanged)

        okButton.target = self
        okButton.action = #selector(closeWizard)

        cloudRadioButton.state = .on
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        fatalError()
    }

    /* ****************************************
     *
     * ****************************************/
    private func createViews() {
        guard let windowContentView = window?.contentView else { return }

        windowContentView.autoresizingMask = [.maxXMargin, .minYMargin]

        windowContentView.addSubview(topLabel)
        windowContentView.addSubview(bottomLabel)
        windowContentView.addSubview(cloudRadioButton)
        windowContentView.addSubview(opmlRadioButton)
        windowContentView.addSubview(bothRadioButton)
        windowContentView.addSubview(okButton)

        topLabel.stringValue = NSLocalizedString(
            "New versions of the program allow you to store radio station lists in the cloud.\n" +
                "This will allow you to have the same lists on several computers.\n" +
                "Lists are stored in your personal iCloud and are not available to outsiders.",
            comment: "List mode wizard text")

        bottomLabel.stringValue = NSLocalizedString(
            "In any case, you can change your choice later in the settings dialog.",
            comment: "List mode wizard text")
        bottomLabel.textColor = .secondaryLabelColor

        cloudRadioButton.title = NSLocalizedString(
            "Use the cloud (recommended). The lists are stored in your personal iCloud cloud and are not accessible to outsiders.\n" +
                "If you select this option, stations that were on this computer will be copied to the cloud.",
            comment: "List mode wizard option")

        opmlRadioButton.title = NSLocalizedString(
            "Use a local file on this computer. Lists will not be synchronized between your computers.",
            comment: "List mode wizard option")

        bothRadioButton.title = NSLocalizedString(
            "Use both, cloud and local file. This will allow you to copy radio stations one by one, or by using the export and import functions.",
            comment: "List mode wizard option")

        okButton.title = "OK"
        okButton.keyEquivalent = "\r"

        topLabel.translatesAutoresizingMaskIntoConstraints = false
        topLabel.topAnchor.constraint(equalToSystemSpacingBelow: windowContentView.topAnchor, multiplier: 1).isActive = true
        topLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: windowContentView.leadingAnchor, multiplier: 1).isActive = true
        windowContentView.trailingAnchor.constraint(equalToSystemSpacingAfter: topLabel.trailingAnchor, multiplier: 1).isActive = true

        cloudRadioButton.translatesAutoresizingMaskIntoConstraints = false
        cloudRadioButton.topAnchor.constraint(equalToSystemSpacingBelow: topLabel.bottomAnchor, multiplier: 2).isActive = true
        cloudRadioButton.leadingAnchor.constraint(equalToSystemSpacingAfter: windowContentView.leadingAnchor, multiplier: 1).isActive = true
        windowContentView.trailingAnchor.constraint(equalToSystemSpacingAfter: cloudRadioButton.trailingAnchor, multiplier: 1).isActive = true

        opmlRadioButton.translatesAutoresizingMaskIntoConstraints = false
        opmlRadioButton.topAnchor.constraint(equalToSystemSpacingBelow: cloudRadioButton.bottomAnchor, multiplier: 2).isActive = true
        opmlRadioButton.leadingAnchor.constraint(equalTo: cloudRadioButton.leadingAnchor).isActive = true
        opmlRadioButton.trailingAnchor.constraint(equalTo: cloudRadioButton.trailingAnchor).isActive = true

        bothRadioButton.translatesAutoresizingMaskIntoConstraints = false
        bothRadioButton.topAnchor.constraint(equalToSystemSpacingBelow: opmlRadioButton.bottomAnchor, multiplier: 2).isActive = true
        bothRadioButton.leadingAnchor.constraint(equalTo: cloudRadioButton.leadingAnchor).isActive = true
        bothRadioButton.trailingAnchor.constraint(equalTo: cloudRadioButton.trailingAnchor).isActive = true

        bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomLabel.topAnchor.constraint(equalToSystemSpacingBelow: bothRadioButton.bottomAnchor, multiplier: 3).isActive = true
        bottomLabel.leadingAnchor.constraint(equalTo: topLabel.leadingAnchor).isActive = true
        bottomLabel.trailingAnchor.constraint(equalTo: topLabel.trailingAnchor).isActive = true

        okButton.translatesAutoresizingMaskIntoConstraints = false
        okButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        okButton.topAnchor.constraint(equalToSystemSpacingBelow: bottomLabel.bottomAnchor, multiplier: 3).isActive = true
        windowContentView.bottomAnchor.constraint(equalToSystemSpacingBelow: okButton.bottomAnchor, multiplier: 1).isActive = true
        windowContentView.trailingAnchor.constraint(equalToSystemSpacingAfter: okButton.trailingAnchor, multiplier: 1).isActive = true

        print(windowContentView.frame.size)
    }

    /* ****************************************
     *
     * ****************************************/
    class func show() {
        let wizard = StationListWizard()
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.runModal(for: wizard.window!)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func radioButtonChanged() {
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func closeWizard() {
        if cloudRadioButton.state == .on { settings.stationsListMode = .cloud }
        if opmlRadioButton.state == .on { settings.stationsListMode = .opml }
        if bothRadioButton.state == .on { settings.stationsListMode = .both }

        NSApplication.shared.stopModal()
        window?.close()
    }
}
