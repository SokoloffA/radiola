//
//  HistoryRow.swift
//  Radiola
//
//  Created by Alex Sokolov on 10.07.2022.
//

import Cocoa

class HistoryRow: NSView {

    @IBOutlet weak var songLabel: NSTextField!
    @IBOutlet weak var stationLabel: NSTextField!
    @IBOutlet weak var dateLabel: NSTextField!
    
    var mainView: NSView?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        _ = load(fromNIBNamed: "HistoryRow")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func load(fromNIBNamed nibName: String) -> Bool {
            var nibObjects: NSArray?
            let nibName = NSNib.Name(stringLiteral: nibName)
            
            if Bundle.main.loadNibNamed(nibName, owner: self, topLevelObjects: &nibObjects) {
                guard let nibObjects = nibObjects else { return false }
                
                let viewObjects = nibObjects.filter { $0 is NSView }
                
                if viewObjects.count > 0 {
                    guard let view = viewObjects[0] as? NSView else { return false }
                    mainView = view
                    self.addSubview(mainView!)
                    
                    mainView?.translatesAutoresizingMaskIntoConstraints = false
                    mainView?.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
                    mainView?.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
                    mainView?.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
                    mainView?.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
                    
                    return true
                }
            }
            
            return false
        }

    
}
