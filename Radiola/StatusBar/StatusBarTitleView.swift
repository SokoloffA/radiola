//
//  StatusBarTitleView.swift
//  Radiola
//
//  Created by Thomas Werner on 17.09.2026.
//

import Cocoa

/* ****************************************
 * Draws the song title over the status bar button and scrolls it
 * if it doesn't fit into the available width.
 *
 * The button keeps an invisible copy of the title, so AppKit still
 * calculates the item width and the icon position as usual. This view
 * only renders the text to the left of the icon.
 *
 * The text is drawn with AppKit in draw(_:), so it looks the same as the
 * native button title (CATextLayer renders glyphs noticeably thinner).
 * ****************************************/
class StatusBarTitleView: NSView {
    private let pointsPerSecond: CGFloat = 30
    private let pauseSeconds: TimeInterval = 3
    private let framesPerSecond: TimeInterval = 60
    private let fadeWidth: CGFloat = 8
    private let startOffset: CGFloat = -0.5 // lines the resting text up with the native title
    private let separator = "   •   "

    private var title = ""
    private var visibleWidth: CGFloat = 0
    private var textWidth: CGFloat = 0
    private var scrollDistance: CGFloat = 0

    private var clipRect = NSRect.zero
    private var textY: CGFloat = 0

    private var offset: CGFloat = 0
    private var scrollStart: TimeInterval = 0
    private var pauseTimer: Timer?
    private var scrollTimer: Timer?

    /// Distance between the end of the text and the icon.
    var spacing: CGFloat = 0 { didSet { needsLayout = true } }

    private var isScrolling: Bool { scrollDistance > 0 }

    private var textAttributes: [NSAttributedString.Key: Any] {
        [.font: NSFont.menuBarFont(ofSize: 0), .foregroundColor: NSColor.labelColor]
    }

    /* ****************************************
     *
     * ****************************************/
    override init(frame: NSRect) {
        super.init(frame: frame)
        // Own layer, so the edge fade (destinationOut) only erases this view's text.
        wantsLayer = true
        isHidden = true
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
    deinit {
        stopTimers()
    }

    /* ****************************************
     * Clicks go to the status bar button
     * ****************************************/
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }

    /* ****************************************
     * visibleWidth is the width of the invisible title in the button.
     * An empty title hides the view.
     * ****************************************/
    func setTitle(_ title: String, visibleWidth: CGFloat) {
        if title == self.title && visibleWidth == self.visibleWidth {
            return
        }

        self.title = title
        self.visibleWidth = visibleWidth

        stopTimers()
        offset = 0
        isHidden = title.isEmpty
        if title.isEmpty {
            return
        }

        textWidth = ceil((title as NSString).size(withAttributes: textAttributes).width)

        if textWidth <= visibleWidth {
            scrollDistance = 0
        } else {
            scrollDistance = ceil(((title + separator) as NSString).size(withAttributes: textAttributes).width)
            beginPause()
        }

        needsLayout = true
        needsDisplay = true
    }

    /* ****************************************
     *
     * ****************************************/
    override func layout() {
        super.layout()

        guard
            !title.isEmpty,
            let button = superview as? NSButton,
            let imageRect = button.cell?.imageRect(forBounds: button.bounds)
        else {
            return
        }

        let iconX = convert(imageRect, from: button).minX
        clipRect = backingAlignedRect(
            NSRect(x: iconX - spacing - visibleWidth, y: 0, width: visibleWidth, height: bounds.height),
            options: .alignAllEdgesNearest)

        // Center the text on the same line as the native (invisible) button title.
        var midY = bounds.midY
        if let titleRect = button.cell?.titleRect(forBounds: button.bounds) {
            midY = convert(titleRect, from: button).midY
        }

        let textHeight = (title as NSString).size(withAttributes: textAttributes).height
        textY = backingAlignedRect(
            NSRect(x: 0, y: midY - textHeight / 2, width: 1, height: textHeight),
            options: .alignAllEdgesNearest).minY

        needsDisplay = true
    }

    /* ****************************************
     *
     * ****************************************/
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        needsLayout = true
    }

    /* ****************************************
     *
     * ****************************************/
    override func draw(_ dirtyRect: NSRect) {
        guard !title.isEmpty, clipRect.width > 0, let context = NSGraphicsContext.current else { return }

        context.saveGraphicsState()
        defer { context.restoreGraphicsState() }

        clipRect.clip()

        if !isScrolling {
            (title as NSString).draw(at: NSPoint(x: clipRect.minX, y: textY), withAttributes: textAttributes)
            return
        }

        // The title followed by its next copy, so the text runs in seamlessly from the right.
        let x = clipRect.minX + fadeWidth + startOffset - offset
        ((title + separator) as NSString).draw(at: NSPoint(x: x, y: textY), withAttributes: textAttributes)
        (title as NSString).draw(at: NSPoint(x: x + scrollDistance, y: textY), withAttributes: textAttributes)

        // Fade out both edges.
        context.compositingOperation = .destinationOut
        let fade = NSGradient(starting: NSColor.black, ending: NSColor.black.withAlphaComponent(0))
        fade?.draw(in: NSRect(x: clipRect.minX, y: clipRect.minY, width: fadeWidth, height: clipRect.height), angle: 0)
        fade?.draw(in: NSRect(x: clipRect.maxX - fadeWidth, y: clipRect.minY, width: fadeWidth, height: clipRect.height), angle: 180)
    }

    /* ****************************************
     *
     * ****************************************/
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    /* ****************************************
     *
     * ****************************************/
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopTimers()
        offset = 0
        if window != nil && isScrolling {
            beginPause()
        }
    }

    /* ****************************************
     * Marquee: pause, scroll by one "title + separator", pause again...
     * ****************************************/
    private func beginPause() {
        stopTimers()
        offset = 0
        needsDisplay = true

        let timer = Timer(timeInterval: pauseSeconds, repeats: false) { [weak self] _ in
            self?.beginScroll()
        }
        RunLoop.main.add(timer, forMode: .common)
        pauseTimer = timer
    }

    /* ****************************************
     *
     * ****************************************/
    private func beginScroll() {
        stopTimers()
        scrollStart = ProcessInfo.processInfo.systemUptime

        let timer = Timer(timeInterval: 1.0 / framesPerSecond, repeats: true) { [weak self] _ in
            self?.scrollStep()
        }
        RunLoop.main.add(timer, forMode: .common)
        scrollTimer = timer
    }

    /* ****************************************
     *
     * ****************************************/
    private func scrollStep() {
        let elapsed = ProcessInfo.processInfo.systemUptime - scrollStart
        offset = CGFloat(elapsed) * pointsPerSecond

        if offset >= scrollDistance {
            // The next copy of the title is now exactly at the start position.
            beginPause()
            return
        }

        needsDisplay = true
    }

    /* ****************************************
     *
     * ****************************************/
    private func stopTimers() {
        pauseTimer?.invalidate()
        pauseTimer = nil
        scrollTimer?.invalidate()
        scrollTimer = nil
    }
}
