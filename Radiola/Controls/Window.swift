//
//  Window.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 23.06.2026.
//

import Cocoa

// MARK: - Window

class Window: NSWindowController {
    /* ****************************************
     *
     * ****************************************/
    init(contentView: NSView, size: NSSize? = nil) {
        let window = NSWindow(
            contentRect: contentView.bounds,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        super.init(window: window)
        contentViewController = WindowViewController(contentView: contentView)
        window.contentViewController = contentViewController

        if let size = size {
            window.setContentSize(size)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - WindowViewController

fileprivate class WindowViewController: NSViewController {
    private let contentView: NSView

    /* ****************************************
     *
     * ****************************************/
    init(contentView: NSView) {
        self.contentView = contentView
        super.init(nibName: nil, bundle: nil)
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /* ****************************************
     *
     * ****************************************/
    override func loadView() {
        view = contentView
    }
}

// MARK: - OkCancelDialog

class OkCancelDialog: Window {
    let messageLabel = Label()
    let okButton = NSButton()
    let cancelButton = NSButton()
    let gridView = FormLayout() //NSGridView(numberOfColumns: 2, rows: 0)
    private let view = NSView()

    init(size: NSSize? = nil) {
        super.init(contentView: view, size: size)
        initView()
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initView() {
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageLabel)

        gridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)

        okButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(okButton)

        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)

        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.title = NSLocalizedString("Cancel", comment: "Cancel button")
        cancelButton.target = self
        cancelButton.action = #selector(cancelClicked(_:))
        cancelButton.keyEquivalent = "\u{1B}"

        okButton.title = NSLocalizedString("OK", comment: "OK button")
        okButton.target = self
        okButton.action = #selector(okClick(_:))
        okButton.keyEquivalent = "\r"

        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalToSystemSpacingBelow: view.topAnchor, multiplier: 1),
            gridView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 25),
            okButton.topAnchor.constraint(equalTo: gridView.bottomAnchor, constant: 35),
            view.bottomAnchor.constraint(equalToSystemSpacingBelow: okButton.bottomAnchor, multiplier: 1),
            cancelButton.centerYAnchor.constraint(equalTo: okButton.centerYAnchor),
        ])

        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 1),
            view.trailingAnchor.constraint(equalToSystemSpacingAfter: messageLabel.trailingAnchor, multiplier: 1),

            gridView.leadingAnchor.constraint(equalTo: messageLabel.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor),
            gridView.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),

            okButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cancelButton.trailingAnchor.constraint(equalTo: okButton.leadingAnchor, constant: -12),
        ])
        
        gridView.setContentHuggingPriority(.required, for: .vertical)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func cancelClicked(_ sender: Any) {
        guard let window = window else { return }
        window.sheetParent?.endSheet(window, returnCode: .cancel)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func okClick(_ sender: Any) {
        guard let window = window else { return }
        window.sheetParent?.endSheet(window, returnCode: .OK)
    }
}
