//
//  RowView.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 22.06.2022.
//  Copyright © 2022 Alex Sokolov. All rights reserved.
//

import Cocoa

class GroupRowView: NSView  {
    
    @IBOutlet weak var nameEdit: NSTextField!
    
    private let group: Group
    
    var mainView: NSView?
    
    init(group: Group) {
        self.group = group
        super.init(frame: NSRect.zero)
        _ = load(fromNIBNamed: "GroupRowView")
        
        nameEdit.stringValue = group.name
        nameEdit.tag = group.id
        nameEdit.target = self
        nameEdit.action = #selector(nameEdited(sender:))
    }
    
    required init?(coder: NSCoder) {
        self.group = Group(name: "")
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

    /* ****************************************
     *
     * ****************************************/
    @IBAction private func nameEdited(sender: NSTextField) {
        group.name = sender.stringValue
        stationsStore.emitChanged()
        stationsStore.write()
    }
    
}
