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
    private let fadeWidth: CGFloat = 8
    private let startOffset: CGFloat = -0.5 // lines the resting text up with the native title
    private let separator = "   •   "

    private var title = ""
    private var visibleWidth: CGFloat = 0
    private var textWidth: CGFloat = 0
    private var scrollDistance: CGFloat = 0

    private var clipRect = NSRect.zero
    private var textY: CGFloat = 0

    private let containerLayer = CALayer()
    private let textLayer = CALayer()
    private let maskLayer = CAGradientLayer()

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

        guard let layer = layer else { return }
        containerLayer.masksToBounds = true
        layer.addSublayer(containerLayer)

        maskLayer.colors = [
            NSColor.clear.cgColor,
            NSColor.black.cgColor,
            NSColor.black.cgColor,
            NSColor.clear.cgColor,
        ]
        maskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        maskLayer.endPoint = CGPoint(x: 1, y: 0.5)

        textLayer.anchorPoint = CGPoint(x: 0, y: 0)
        containerLayer.addSublayer(textLayer)
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        textLayer.removeAllAnimations()

        isHidden = title.isEmpty
        if isHidden {
            return
        }

        textWidth = ceil((title as NSString).size(withAttributes: textAttributes).width)

        if textWidth <= visibleWidth {
            scrollDistance = 0
            renderText(string: title)
        } else {
            scrollDistance = ceil(((title + separator) as NSString).size(withAttributes: textAttributes).width)
            renderText(string: title + separator + title)
        }

        needsLayout = true
    }

    /* ****************************************
     *
     * ****************************************/
    private func renderText(string: String) {
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0
        let size = (string as NSString).size(withAttributes: textAttributes)
        let imageSize = CGSize(width: ceil(size.width), height: ceil(size.height))

        guard imageSize.width > 0 && imageSize.height > 0 else {
            textLayer.contents = nil
            return
        }

        let image = NSImage(size: imageSize, flipped: false) { rect in
            self.effectiveAppearance.performAsCurrentDrawingAppearance {
                guard let context = NSGraphicsContext.current?.cgContext else { return }
                context.setShouldSmoothFonts(true)
                context.setAllowsFontSmoothing(true)
                (string as NSString).draw(in: rect, withAttributes: self.textAttributes)
            }
            return true
        }

        textLayer.contentsScale = scale
        textLayer.contents = image.layerContents(forContentsScale: scale)
        textLayer.bounds = CGRect(origin: .zero, size: imageSize)
    }

    /* ****************************************
     *
     * ****************************************/
    private func startAnimation() {
        guard isScrolling, scrollDistance > 0 else { return }
        if textLayer.animation(forKey: "marquee") != nil { return }

        let scrollDuration = Double(scrollDistance / pointsPerSecond)
        let totalDuration = scrollDuration + pauseSeconds
        let pauseFraction = pauseSeconds / totalDuration

        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [0, 0, -scrollDistance]
        animation.keyTimes = [0, NSNumber(value: pauseFraction), 1.0]
        animation.duration = totalDuration
        animation.repeatCount = .infinity
        animation.timingFunctions = [
            CAMediaTimingFunction(name: .linear),
            CAMediaTimingFunction(name: .linear),
        ]

        textLayer.add(animation, forKey: "marquee")
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

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        containerLayer.frame = clipRect

        if isScrolling {
            containerLayer.mask = maskLayer
            maskLayer.frame = containerLayer.bounds
            if containerLayer.bounds.width > 0 {
                let fadeFraction = fadeWidth / containerLayer.bounds.width
                maskLayer.locations = [
                    0,
                    NSNumber(value: fadeFraction),
                    NSNumber(value: 1.0 - fadeFraction),
                    1.0,
                ]
            }

            textLayer.position = CGPoint(x: fadeWidth + startOffset, y: textY)
            startAnimation()
        } else {
            containerLayer.mask = nil
            textLayer.position = CGPoint(x: 0, y: textY)
            textLayer.removeAllAnimations()
        }

        CATransaction.commit()
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
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        // Render the text again when the theme changes (Dark/Light)
        if !title.isEmpty {
            let currentTitle = title
            let currentWidth = visibleWidth
            title = ""
            setTitle(currentTitle, visibleWidth: currentWidth)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil && !title.isEmpty {
            needsLayout = true
        }
    }
}
