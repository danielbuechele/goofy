//
//  TitleLabel.swift
//  Goofy
//
//  Created by Daniel Büchele on 11/04/15.
//  Copyright (c) 2015 Daniel Büchele. All rights reserved.
//

import Cocoa

class TitleLabel: NSViewController {
    
    var titleLabel : NSTextField?
    var activeLabel : NSTextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        activeLabel = NSTextField(frame: CGRectMake(40, -18, self.view.frame.width, 36))
        activeLabel?.stringValue = ""
        activeLabel?.editable = false
        activeLabel?.bezeled = false
        activeLabel?.selectable = false
        activeLabel?.drawsBackground = false
        activeLabel?.alignment = .CenterTextAlignment
        activeLabel?.font = NSFont(name: "HelveticaNeue", size: 10.0)
        self.view.addSubview(activeLabel!)
        
        titleLabel = NSTextField(frame: CGRectMake(40, 0, self.view.frame.width, 36))
        titleLabel?.stringValue = ""
        titleLabel?.editable = false
        titleLabel?.bezeled = false
        titleLabel?.selectable = false
        titleLabel?.drawsBackground = false
        titleLabel?.alignment = .CenterTextAlignment
        titleLabel?.textColor = NSColor.blackColor()
        titleLabel?.font = NSFont(name: "HelveticaNeue", size: 14.0)
        self.view.addSubview(titleLabel!)
        
        
        
    }
    
    func setTitle(title: String, active: String) {
        
        var rect :CGRect? = titleLabel?.frame
        var y :CGFloat = 0.0
        if active=="" {
            y = -6
        }
        rect?.origin.y = y
        titleLabel?.frame = rect!
        titleLabel?.stringValue = title
        activeLabel?.stringValue = active
        
    }

    func windowDidResize() {
        
        var toolbarItem : NSToolbarItem!
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
        for item in appDelegate.toolbar.items {
            let i = item as! NSToolbarItem
            if i.view == self.view {
                toolbarItem = i
                break
            }
        }
        
        var rect :CGRect? = titleLabel?.frame
        var width = toolbarItem.view?.frame.width
        width = width!-40
        rect?.size.width = width!
        titleLabel?.frame = rect!
        
        var rect2 = activeLabel?.frame
        rect2?.size.width = width!
        activeLabel?.frame = rect2!
        
    }
    
    
}
