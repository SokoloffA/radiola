//
//  Controls.swift
//  Radiola
//
//  Created by Alex Sokolov on 10.07.2022.
//

import Cocoa

extension NSImage {
    func tint(color: NSColor) -> NSImage {
        if isTemplate == false {
            return self
        }

        let image = copy() as! NSImage
        image.lockFocus()

        color.set()

        let imageRect = NSRect(origin: .zero, size: image.size)
        imageRect.fill(using: .sourceIn)

        image.unlockFocus()
        image.isTemplate = false

        return image
    }
}

class ScrollableSlider: NSSlider {
    override func scrollWheel(with event: NSEvent) {
        guard isEnabled else { return }

        let range = Float(maxValue - minValue)
        var delta = Float(0)

        // Allow horizontal scrolling on horizontal and circular sliders
        if _isVertical && sliderType == .linear {
            delta = Float(event.deltaY)
        } else if userInterfaceLayoutDirection == .rightToLeft {
            delta = Float(event.deltaY + event.deltaX)
        } else {
            delta = Float(event.deltaY - event.deltaX)
        }

        // Account for natural scrolling
        if event.isDirectionInvertedFromDevice {
            delta *= -1
        }

        let increment = range * delta / 100
        var value = floatValue + increment

        // Wrap around if slider is circular
        if sliderType == .circular {
            let minValue = Float(self.minValue)
            let maxValue = Float(self.maxValue)

            if value < minValue {
                value = maxValue - abs(increment)
            } else if value > maxValue {
                value = minValue + abs(increment)
            }
        }

        floatValue = value
        sendAction(action, to: target)
    }

    private var _isVertical: Bool {
        if #available(macOS 10.12, *) {
            return self.isVertical
        } else {
            // isVertical is an NSInteger in versions before 10.12
            return value(forKey: "isVertical") as! NSInteger == 1
        }
    }
}
