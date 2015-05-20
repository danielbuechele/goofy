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
    
    @IBAction func gotoConversationAtIndex(sender: AnyObject) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.webView.evaluateJavaScript("gotoConversationAtIndex("+String(sender.tag())+")", completionHandler: nil);
    }
    
    @IBAction func logout(sender: AnyObject) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.webView.evaluateJavaScript("logout()", completionHandler: nil);
        appDelegate.hideMenuBar()
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
    
    @IBAction func handlePaste(sender: NSMenuItem) {
        var pasteboard = NSPasteboard.generalPasteboard()
        
        var classArray : Array<AnyObject> = [NSImage.self]
        var canReadData = pasteboard.canReadObjectForClasses(classArray, options: nil)
        
        if (canReadData) {
            var objectsToPaste = pasteboard.readObjectsForClasses(classArray, options: nil) as! Array<NSImage>
            var image = objectsToPaste[0];
            println(image)
            self.uploadimage(image)
        } else {
            // Forward any non-image pastes (text) to the webview as a standard paste event.
            NSApp.sendAction("paste:", to:nil, from:self)
        }
    }
    
    @IBAction func sendImage(sender: NSMenuItem?) {
        var openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["png","jpg","gif"]
        openPanel.beginWithCompletionHandler { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                var image = NSImage(contentsOfURL: openPanel.URL!);
                self.uploadimage(image!)
            }
        }
    }
    
    func uploadimage(image: NSImage) {
        println(image)
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        image.lockFocus();
        var bitmapRep = NSBitmapImageRep(focusedViewRect: NSMakeRect(0, 0, image.size.width, image.size.height));
        image.unlockFocus();
        var imageData = bitmapRep?.representationUsingType(NSBitmapImageFileType.NSPNGFileType, properties: [:]);
        var base64String = imageData?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.EncodingEndLineWithLineFeed);
        appDelegate.webView.evaluateJavaScript("pasteImage('\(base64String!)')", completionHandler: nil);
    }
}


