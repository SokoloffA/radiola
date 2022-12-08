//
//  RowView.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 22.06.2022.
//  Copyright © 2022 Alex Sokolov. All rights reserved.
//

import Cocoa

class StationRowView: NSView  {

    @IBOutlet var contentView: NSView!
    @IBOutlet weak var nameEdit: NSTextField!
    @IBOutlet weak var urledit: NSTextField!
    @IBOutlet weak var favoriteButton: NSButton!

    private let favoriteIcons = [
        false: NSImage(named: NSImage.Name("star-empty"))?.tint(color: .lightGray),
        true: NSImage(named: NSImage.Name("star-filled"))?.tint(color: .systemYellow),
    ]
    
    private let station: Station
    
    var mainView: NSView?
    
    init(station: Station) {
        self.station = station
        super.init(frame: NSRect.zero)
        _ = load(fromNIBNamed: "StationRowView")
        
        nameEdit.stringValue = station.name
        nameEdit.tag = station.id
        nameEdit.target = self
        nameEdit.action = #selector(nameEdited(sender:))

        urledit.stringValue = station.url
        urledit.tag = station.id
        urledit.target = self
        urledit.action = #selector(urlEdited(sender:))

        favoriteButton.tag = station.id
        favoriteButton.image = favoriteIcons[station.isFavorite]!
        favoriteButton.target = self
        favoriteButton.action = #selector(favClicked(sender:))
    }
       
    required init?(coder: NSCoder) {
        station = Station(name: "", url: "")
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
    @IBAction func nameEdited(sender: NSTextField) {
        station.name = sender.stringValue
        stationsStore.write()
        stationsStore.emitChanged()
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction private func urlEdited(sender: NSTextField) {
        station.url = sender.stringValue
        stationsStore.write()
        stationsStore.emitChanged()
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction private func favClicked(sender: NSButton) {
        station.isFavorite = !station.isFavorite
        sender.image = favoriteIcons[station.isFavorite]!
        stationsStore.write()
        stationsStore.emitChanged()
    }

}
