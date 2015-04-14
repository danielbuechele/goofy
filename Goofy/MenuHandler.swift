//
//  MenuHandler.swift
//  Goofy
//
//  Created by Daniel Büchele on 09/04/15.
//  Copyright (c) 2015 Daniel Büchele. All rights reserved.
//

import Foundation

class MenuHandler: NSObject {

    @IBAction func reload(sender: AnyObject) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.startLoading()
        appDelegate.webView.reload()
    }
    
    @IBAction func newConversation(sender: AnyObject) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.webView.evaluateJavaScript("newConversation()", completionHandler: nil);
    }
    
    @IBAction func gotoConversation(sender: AnyObject) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.webView.evaluateJavaScript("gotoConversation("+String(sender.tag())+")", completionHandler: nil);
    }
    
    @IBAction func logout(sender: AnyObject) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.webView.evaluateJavaScript("logout()", completionHandler: nil);
    }
    
    @IBAction func plus(sender: AnyObject) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.webView.evaluateJavaScript("plus()", completionHandler: nil);
    }
    
    @IBAction func info(sender: AnyObject) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.webView.evaluateJavaScript("info()", completionHandler: nil);
    }
    
    @IBAction func preferences(sender: AnyObject) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.webView.evaluateJavaScript("preferences()", completionHandler: nil);
    }
    
    @IBAction func fullscreen(sender: AnyObject) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window.toggleFullScreen(self)
    }
}


