//
//  AnimateIcon.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 13.03.2021.
//  Copyright © 2021 Alex Sokolov. All rights reserved.
//

import Cocoa

class AnimatedIcon {
    var frames: [NSImage] = []
    let size: Int
    var statusItem : NSStatusItem? = nil
    private var timer : Timer? = nil
    var framesPerSecond  = 5
    private var currentFrame = 0;
    
    init (size: Int = 16) {
        self.size = size
    }
    
    init (size: Int = 16, frames: [String]) {
        self.size = size
        for name in frames {
            addFrame(name: name)
        }
    }
    
    func addFrame(name: String) {
        guard let img = NSImage(named:NSImage.Name(name)) else { return }
        img.size = NSSize(width: size, height: size)
        img.isTemplate = true
        frames.append(img)
    }
    
    func start(startFrame: Int) {
        if statusItem == nil {
            return
        }
        if timer == nil {
            currentFrame = startFrame
            timer = Timer.scheduledTimer(timeInterval: 1.0 / Double(framesPerSecond),
                                         target: self,
                                         selector: #selector(changeIcon),
                                         userInfo: nil,
                                         repeats: true)
        }
    }
    
    func stop() {
        currentFrame = 0;
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func changeIcon(_ sender: Timer) {
        guard let item = statusItem else { return }
        let cnt = frames.count
        item.button?.image = frames[currentFrame]
        currentFrame = (currentFrame + 1) % cnt
    }
}
