//
//  MenuHandler.swift
//  Goofy
//
//  Created by Daniel Büchele on 09/04/15.
//  Copyright (c) 2015 Daniel Büchele. All rights reserved.
//

import Foundation

class MenuHandler: NSObject {

    // MARK: - Main Menu

	// MARK: Preferences

    @IBAction func preferences(_ sender: AnyObject) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        appDelegate.webView.evaluateJavaScript("preferences()", completionHandler: nil);
    }

    // MARK: Logout

    @IBAction func logout(_ sender: AnyObject) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        appDelegate.webView.evaluateJavaScript("logout()", completionHandler: nil);
        appDelegate.hideMenuBar()
    }

	// MARK: Clipboard: Paste

    @IBAction func handlePaste(_ sender: NSMenuItem) {
        let pasteboard = NSPasteboard.general()

        let classArray : Array<AnyClass> = [NSImage.self]
        let canReadData = pasteboard.canReadObject(forClasses: classArray, options: nil)

        if (canReadData) {
            var objectsToPaste = pasteboard.readObjects(forClasses: classArray, options: nil) as! Array<NSImage>
            let image = objectsToPaste[0];
            self.uploadimage(image)
        } else {
            // Forward any non-image pastes (text) to the webview as a standard paste event.
            NSApp.sendAction(#selector(WebView.paste(_:)), to:nil, from:self)
        }
    }

	// MARK: Attach Image

    @IBAction func sendImage(_ sender: NSMenuItem?) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["png","jpg","jpeg","gif"]
        openPanel.begin { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                let image = NSImage(contentsOf: openPanel.url!);
                self.uploadimage(image!)
            }
        }
    }

    func uploadimage(_ image: NSImage) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        image.lockFocus();
        let bitmapRep = NSBitmapImageRep(focusedViewRect: NSMakeRect(0, 0, image.size.width, image.size.height));
        image.unlockFocus();
        let imageData = bitmapRep?.representation(using: NSBitmapImageFileType.PNG, properties: [:]);
        let base64String = imageData?.base64EncodedString(options: NSData.Base64EncodingOptions.endLineWithLineFeed);
        //println(base64String!)
        appDelegate.webView.evaluateJavaScript("pasteImage('\(base64String!)')", completionHandler: nil);
    }

    // MARK: Search

    @IBAction func search(_ sender: AnyObject) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        appDelegate.webView.evaluateJavaScript("search()", completionHandler: nil);
    }

    // MARK: Conversation Navigation

    @IBAction func newConversation(_ sender: AnyObject) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        appDelegate.webView.evaluateJavaScript("newConversation()", completionHandler: nil);
    }
    
    @IBAction func gotoConversation(_ sender: AnyObject) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        appDelegate.webView.evaluateJavaScript("gotoConversation("+String(sender.tag)+")", completionHandler: nil);
    }
    
    @IBAction func gotoConversationAtIndex(_ sender: AnyObject) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        appDelegate.webView.evaluateJavaScript("gotoConversationAtIndex("+String(sender.tag)+")", completionHandler: nil);
    }

    @IBAction func plus(_ sender: AnyObject) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        appDelegate.webView.evaluateJavaScript("plus()", completionHandler: nil);
    }

	// MARK: Fullscreen
    
    @IBAction func fullscreen(_ sender: AnyObject) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        appDelegate.window.toggleFullScreen(self)
    }

    // MARK: Reload

    @IBAction func reload(_ sender: AnyObject) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        appDelegate.startLoading()
        appDelegate.webView.reload()
    }


    // MARK: - Toolbar

    // MARK: "Information" Button

    @IBAction func info(_ sender: AnyObject) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        appDelegate.webView.evaluateJavaScript("info()", completionHandler: nil);
    }

    // MARK: "Report Issue" Button

    @IBAction func reportIssue(_ sender: NSMenuItem) {
        let reportIssueURL = URL(string: "https://github.com/danielbuechele/goofy/issues/new")
        NSWorkspace.shared().open(reportIssueURL!)
    }

}


