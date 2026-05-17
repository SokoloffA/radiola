//
//  PopoverItem.swift
//  Radiola
//
//  Created by Alex Sokolov on 11.05.2026.
//

import Cocoa

// MARK: - PopoverItem

class PopoverItem: NSControl, NSValidatedUserInterfaceItem {
    private let titleLabel = NSTextField(labelWithString: "")
    private let keyLabel = NSTextField(labelWithString: "")
    private var submenuTimer: Timer?

    var representedObject: Any?

    var title: String {
        get { titleLabel.stringValue }
        set { titleLabel.stringValue = newValue }
    }

    var keyEquivalent: String { didSet { keyEquivalentDidSet() }}

    private func keyEquivalentDidSet() {
        keyLabel.stringValue = keyEquivalent.isEmpty ? "" : "⌘ " + keyEquivalent.uppercased()
    }

    override var menu: NSMenu? {
        didSet {
            updateAppearance()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    init(title: String, action selector: Selector? = nil, keyEquivalent: String = "") {
        self.keyEquivalent = keyEquivalent
        super.init(frame: .zero)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.stringValue = title
        titleLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        titleLabel.textColor = .labelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        keyLabel.translatesAutoresizingMaskIntoConstraints = false

        keyLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        keyLabel.textColor = .secondaryLabelColor
        keyLabel.translatesAutoresizingMaskIntoConstraints = false
        keyEquivalentDidSet()

        addSubview(titleLabel)
        addSubview(keyLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 23),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            keyLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 25),
            keyLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            keyLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        action = selector

        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
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
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard !keyEquivalent.isEmpty else { return false }

        let match = event.charactersIgnoringModifiers?.lowercased() == keyEquivalent.lowercased()
            && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command // keyEquivalentModifierMask

        if match {
            isHighlighted = true
            sendAction(action, to: target)
            return true
        }

        return false
    }

    /* ****************************************
     *
     * ****************************************/
    override func mouseEntered(with event: NSEvent) {
        guard isEnabled else { return }
        isHighlighted = true

        guard menu != nil else { return }
        submenuTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.showSubmenu()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    override func mouseExited(with event: NSEvent) {
        isHighlighted = false
        submenuTimer?.invalidate()
        submenuTimer = nil
    }

    /* ****************************************
     *
     * ****************************************/
    override var isHighlighted: Bool {
        didSet { updateAppearance() }
    }

    /* ****************************************
     *
     * ****************************************/
    override var isEnabled: Bool {
        didSet { updateAppearance() }
    }

    /* ****************************************
     *
     * ****************************************/
    func validate() {
        if menu != nil {
            isEnabled = true
            return
        }

        guard let action else {
            isEnabled = false
            return
        }

        if let validator = NSApp.target(forAction: action, to: target, from: self) as? NSUserInterfaceValidations {
            isEnabled = validator.validateUserInterfaceItem(self)
        } else {
            isEnabled = NSApp.target(forAction: action, to: target, from: self) != nil
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func updateAppearance() {
        if menu?.numberOfItems ?? 0 > 0 {
        }

        if isEnabled {
            titleLabel.textColor = isHighlighted ? .selectedMenuItemTextColor : .labelColor
            keyLabel.textColor = isHighlighted ? .selectedMenuItemTextColor : .secondaryLabelColor
        } else {
            titleLabel.textColor = .disabledControlTextColor
            keyLabel.textColor = .disabledControlTextColor
        }
    }

    /* ****************************************
     *
     * ****************************************/
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if isHighlighted {
            let rect = bounds.insetBy(dx: -10, dy: 0)
            let path = NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5)
            NSColor.controlAccentColor.setFill()
            path.fill()
        }

        if menu != nil {
            drawSubmenuMark()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func drawSubmenuMark() {
        let color: NSColor = isHighlighted ? .selectedMenuItemTextColor : .textColor
        let config = NSImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        let image = NSImage(systemSymbolName: "chevron.right", accessibilityDescription: nil)?.withSymbolConfiguration(config)?.tint(color: color)

        guard let image else { return }
        let size = image.size
        let x = bounds.maxX - size.width
        let y = bounds.midY - size.height / 2
        image.draw(in: NSRect(x: x, y: y, width: size.width, height: size.height))
    }

    /* ****************************************
     *
     * ****************************************/
    override func mouseUp(with event: NSEvent) {
        guard isEnabled else { return }
        let point = convert(event.locationInWindow, from: nil)
        if bounds.contains(point) {
            sendAction(action, to: target)
            window?.close()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func showSubmenu() {
        guard let menu, let window else { return }
        menu.update()
        let menuWidth = menu.size.width

        let targetRect = NSRect(
            x: bounds.minX - menuWidth - 8,
            y: bounds.minY,
            width: 0,
            height: bounds.height
        )

        let rectInWindow = convert(targetRect, to: nil)
        let screenRect = window.convertToScreen(rectInWindow)

        menu.popUp(
            positioning: menu.items.first,
            at: NSPoint(x: screenRect.minX, y: screenRect.maxY),
            in: nil
        )
    }
}
