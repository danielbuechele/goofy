//
//  AppDelegate.swift
//  Goofy
//
//  Created by Daniel Büchele on 11/29/14.
//  Copyright (c) 2014 Daniel Büchele. All rights reserved.
//

import Cocoa
import WebKit
import Quartz

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate, NSWindowDelegate {

    // MARK: Views

    @IBOutlet var window : NSWindow!
    @IBOutlet var view : NSView!
    @IBOutlet var loadingView : NSImageView?
    @IBOutlet var spinner : NSProgressIndicator!
    @IBOutlet var longLoading : NSTextField!
    @IBOutlet var reactivationMenuItem : NSMenuItem!
    @IBOutlet var statusItemMenuItem : NSMenuItem!
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet var toolbarTrenner : NSToolbarItem!
    @IBOutlet var toolbarSpacing : NSToolbarItem!
    @IBOutlet var toolbar : NSToolbar!
    @IBOutlet var titleLabel : TitleLabel!
    @IBOutlet var menuHandler : MenuHandler!
    var webView : WKWebView!


    // MARK: Properties

    var timer : NSTimer!
    var activatedFromBackground = false
    var isFullscreen = false

    var statusItem = NSStatusItem()
    var statusItemConfigurationKey = "showStatusItem"
    var statusItemDefault = true


    // MARK: - NSApplication
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
		// Init Window
        initWindow(window)
        sizeWindow(window)

        // Start Loading
        startLoading()

		// Create Webview
        webView = createWebview(createContentController())
        view.addSubview(webView, positioned: NSWindowOrderingMode.Below, relativeTo: view);

		// Load URL
        let url : String = "https://messenger.com/login"
        let req = NSMutableURLRequest(URL: NSURL(string: url)!)
        webView.loadRequest(req);
    }

    func applicationDidBecomeActive(aNotification: NSNotification) {
        NSApplication.sharedApplication().dockTile.badgeLabel = ""
        if (self.activatedFromBackground) {
            if (self.reactivationMenuItem.state == 1) {
                webView.evaluateJavaScript("reactivation()", completionHandler: nil)
            }

        } else {
            self.activatedFromBackground = true;
        }
        reopenWindow(self)
    }

    func applicationShouldOpenUntitledFile(sender: NSApplication) -> Bool {
        return true
    }

    func applicationOpenUntitledFile(sender: NSApplication) -> Bool {
        reopenWindow(self)
        return true
    }


    // MARK: - WKWebView

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: Selector("endLoading"), userInfo: nil, repeats: false)
        if webView.URL!.absoluteString!.rangeOfString("messenger.com/login") == nil{
            showMenuBar()
        }
    }
    
    func webView(webView: WKWebView,
                 createWebViewWithConfiguration configuration: WKWebViewConfiguration,
                                                forNavigationAction navigationAction: WKNavigationAction,
                                                                    windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Handle video playback and links opened in a new window.
        if navigationAction.targetFrame == nil {
            var url = navigationAction.request.URL!
            if url.description.lowercaseString.rangeOfString("http://") != nil || url.description.lowercaseString.rangeOfString("https://") != nil || url.description.lowercaseString.rangeOfString("mailto:") != nil  {

                NSWorkspace.sharedWorkspace().openURL(url)
            }
        }
        return nil
    }

    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: ((WKNavigationActionPolicy) -> Void)) {
        
        if let url = navigationAction.request.URL {
            if let host = url.host {
                let inApp = host.hasSuffix("messenger.com") && !url.path!.hasPrefix("/l.php");
                let isLogin = host.hasSuffix("facebook.com") && (url.path!.hasPrefix("/login") || url.path!.hasPrefix("/checkpoint"));
                
                if inApp || isLogin {
                    decisionHandler(.Allow)
                } else {

                    // Check if the host is l.messenger.com
                    let facebookFormattedLink = (url.host! == "l.messenger.com");

                    // If such is the case...
                    if facebookFormattedLink {
                        do {
                            // Generate a NSRegularExpression to match our url, extracting the value of u= into it own regex group.
                            let regex = try NSRegularExpression(pattern: "(https?://l.messenger.com/l.php\\?u=)(.+)(&h=.+)", options: [])
                            let nsString = url.absoluteString! as NSString
                            let results = regex.firstMatchInString(url.absoluteString!, options: [], range: NSMakeRange(0, nsString.length))

                            // Take the result, pull it out of our string, and decode the url string
                            let referenceString = nsString.substringWithRange(results!.rangeAtIndex(2)).stringByRemovingPercentEncoding!

                            // Open it up as a normal url
                            NSWorkspace.sharedWorkspace().openURL(NSURL(string: referenceString)!)
                            decisionHandler(.Cancel)
                        } catch {
                            NSWorkspace.sharedWorkspace().openURL(url)
                            decisionHandler(.Cancel)
                        }
                    } else {
                        NSWorkspace.sharedWorkspace().openURL(url)
                        decisionHandler(.Cancel)
                    }
                }
            } else {
                decisionHandler(.Cancel)
            }
        } else {
            decisionHandler(.Cancel)
        }
    }

    func createWebview(contentController: WKUserContentController) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController

        let wv = WKWebView(frame: self.view.bounds, configuration: configuration)
        wv.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        wv.navigationDelegate = self
        wv.UIDelegate = self
        wv.autoresizingMask = [NSAutoresizingMaskOptions.ViewWidthSizable, NSAutoresizingMaskOptions.ViewHeightSizable]

        return wv
    }


    // MARK: - NSWindow

    func windowDidEnterFullScreen(notification: NSNotification) {
        isFullscreen = true
        sizeWindow(window)
    }
    
    func windowDidExitFullScreen(notification: NSNotification) {
        isFullscreen = false
        sizeWindow(window)
    }

    func windowDidResize(notification: NSNotification) {
        sizeWindow(notification.object as! NSWindow)
    }

    func initWindow(window: NSWindow) {
        window.backgroundColor = NSColor.whiteColor()
        window.minSize = NSSize(width: 380,height: 376)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .Hidden
        window.delegate = self
	}

    func sizeWindow(window: NSWindow) {

        if window.frame.width > 640.0 && !self.isFullscreen {
            toolbarTrenner.minSize = NSSize(width: 1, height: 100)
            toolbarTrenner.maxSize = NSSize(width: 1, height: 100)
            toolbarTrenner.view?.frame = CGRectMake(0, 0, 1, 100)
            toolbarTrenner.view?.layer?.backgroundColor = NSColor(white: 0.9, alpha: 1.0).CGColor


            toolbarSpacing.minSize = NSSize(width: 157, height: 100)
            toolbarSpacing.maxSize = NSSize(width: 157, height: 100)
            toolbarSpacing.view = NSView(frame: CGRectMake(0, 0, 157, 100))
        } else {
            toolbarTrenner.view?.layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.0).CGColor

            toolbarSpacing.minSize = NSSize(width: 0, height: 100)
            toolbarSpacing.maxSize = NSSize(width: 0, height: 100)
        }

        titleLabel.windowDidResize()
    }


    // MARK: - Main Menu

    func showMenuBar() {
        for item in toolbar.items {
            let i = item 
            i.view?.hidden = false
            i.image = NSImage(named: i.label)
        }
        sizeWindow(window)
    }
    
    func hideMenuBar() {
        for item in toolbar.items {
            let i = item 
            i.view?.hidden = true
            i.image = NSImage(named: "White")
        }
    }


    // MARK: - ContentController (JavaScript Injection)

    func createContentController() -> WKUserContentController {

        let userContentController = WKUserContentController()

        #if DEBUG
            let path = NSBundle.mainBundle().objectForInfoDictionaryKey("PROJECT_DIR") as! String
            let source = (try! String(contentsOfFile: path+"/server/dist/fb.js", encoding: NSUTF8StringEncoding))+"init();"
        #else
            let version = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
            var jsurl = "https://dani.taurus.uberspace.de/goofyapp/fb" + version + ".js"
            if (NSBundle.mainBundle().objectForInfoDictionaryKey("GoofyJavaScriptURL") != nil) {
                jsurl = NSBundle.mainBundle().objectForInfoDictionaryKey("GoofyJavaScriptURL") as! String
            }
            let source = "function getScript(url,success){ var script = document.createElement('script'); script.src = url; var head = document.getElementsByTagName('head')[0], done=false; script.onload = script.onreadystatechange = function(){ if (!done && (!this.readyState || this.readyState == 'loaded' || this.readyState == 'complete')) { done=true; success(); script.onload = script.onreadystatechange = null; head.removeChild(script); } }; head.appendChild(script); }" +
                "getScript('" + jsurl + "', function() {init();});"
        #endif

        let reactivationToggle : Bool? = NSUserDefaults.standardUserDefaults().objectForKey("reactivationToggle") as? Bool
        if (reactivationToggle != nil && reactivationToggle==true) {
            self.reactivationMenuItem.state = 1
        }

        let userScript = WKUserScript(source: source, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
        let reactDevTools = WKUserScript(source: "Object.defineProperty(window, '__REACT_DEVTOOLS_GLOBAL_HOOK__', {value: {_renderers: {},helpers: {},inject: function(renderer) {var id = Math.random().toString(16).slice(2);this._renderers[id] = renderer;this.emit('renderer', {id, renderer});},_listeners: {},sub: function(evt, fn) {this.on(evt, fn);return function () {this.off(evt, fn)};},on: function(evt, fn) {if (!this._listeners[evt]) {this._listeners[evt] = [];}this._listeners[evt].push(fn);},off: function(evt, fn) {if (!this._listeners[evt]) {return;}var ix = this._listeners[evt].indexOf(fn);if (ix !== -1) {this._listeners[evt].splice(ix, 1);}if (!this._listeners[evt].length) {this._listeners[evt] = null;}},emit: function(evt, data) {if (this._listeners[evt]) {this._listeners[evt].map(function fn() {fn(data)});}}}});", injectionTime: .AtDocumentStart, forMainFrameOnly: true)


        userContentController.addUserScript(userScript)
        userContentController.addUserScript(reactDevTools)

        let handler = NotificationScriptMessageHandler()
        userContentController.addScriptMessageHandler(handler, name: "notification")

        return userContentController
    }


    // MARK: - Content Loading
    
    func startLoading() {
        loadingView?.layer?.backgroundColor = NSColor.whiteColor().CGColor

        loadingView?.hidden = false
        spinner.startAnimation(self)
        spinner.hidden = false
        longLoading.hidden = true
        timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: Selector("longLoadingMessage"), userInfo: nil, repeats: false)
        
        hideMenuBar()
    }

    func endLoading() {
        timer.invalidate()
        loadingView?.hidden = true
        spinner.stopAnimation(self)
        spinner.hidden = true
        longLoading.hidden = true

        sizeWindow(window)
    }

    func longLoadingMessage() {
        if (loadingView?.hidden == false) {
            longLoading.hidden = false
        }
    }


    // MARK: - Dock Icon

    func changeDockIcon() {
        NSApplication.sharedApplication().applicationIconImage = NSImage(named: "Image")
    }


    // MARK: - Status Item

    func statusBarItemClicked() {
        webView.evaluateJavaScript("reactivation()", completionHandler: nil);
        
        let currentEvent    = NSApp.currentEvent!
        let isRightClicked  = (currentEvent.type == NSEventType.RightMouseUp) ? true : false
        
        if isRightClicked {
            // Set up the statusMenu and show it.
            statusItem.menu = statusMenu
            statusItem.popUpStatusItemMenu(statusMenu)
            statusItem.menu = nil
        } else {
            // A left click on the statusItem shows/hides the window
            if !window.visible {
                reopenWindow(self)
                NSApp.activateIgnoringOtherApps(true)
            } else {
                window.setIsVisible(false)
            }
        }
    }

    func addStatusItem() {
        statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
        
        
        if let button = statusItem.button {
			changeStatusItemImage("StatusItem")
            NSApp.setActivationPolicy(.Accessory) // Hide dock icon and menu bar
            button.action = #selector(self.statusBarItemClicked)
            button.sendActionOn([.LeftMouseUp, .RightMouseUp])
        }
    }

    func hideStatusItem() {
    	NSStatusBar.systemStatusBar().removeStatusItem(statusItem)
        NSApp.setActivationPolicy(.Regular)
        
        if !window.visible {
            reopenWindow(self)
            NSApp.activateIgnoringOtherApps(true)
            // Or could be just use to not show the window window.makeKeyWindow()
        }
    }

    func changeStatusItemImage(newImage: String) {
        if let button = statusItem.button {
            let image = NSImage(named: newImage)
            image!.template = true
            button.image = image
        }
    }

    func initStatusItem() {
        if ((NSUserDefaults.standardUserDefaults().objectForKey(statusItemConfigurationKey)) == nil) {
            NSUserDefaults.standardUserDefaults().setObject(statusItemDefault, forKey: statusItemConfigurationKey)
        } else {
			updateStatusItemVisibility()
        }
    }

    func toggleStatusItemConfiguration() {
        print (NSUserDefaults.standardUserDefaults().boolForKey(statusItemConfigurationKey) )
        if (NSUserDefaults.standardUserDefaults().boolForKey(statusItemConfigurationKey) == true) {
            NSUserDefaults.standardUserDefaults().setObject(false, forKey: statusItemConfigurationKey)
        } else {
            NSUserDefaults.standardUserDefaults().setObject(true, forKey: statusItemConfigurationKey)
        }

    }

    func updateStatusItemVisibility() {
        if (NSUserDefaults.standardUserDefaults().boolForKey(statusItemConfigurationKey) == true) {
            addStatusItem()
        } else {
            hideStatusItem()
        }
    }

    @IBAction func toggleStatusItem(sender: AnyObject) {
        
		toggleStatusItemConfiguration()
        updateStatusItemVisibility()
    }


    // MARK: - Interface Builder interface

    @IBAction func reopenWindow(sender: AnyObject) {
        window.makeKeyAndOrderFront(self)
    }

    @IBAction func toggleReactivation(sender: AnyObject) {
        let i : NSMenuItem = sender as! NSMenuItem

        if (i.state == 0) {
            i.state = NSOnState
            NSUserDefaults.standardUserDefaults().setObject(true, forKey: "reactivationToggle")
        } else {
            i.state = NSOffState
            NSUserDefaults.standardUserDefaults().setObject(false, forKey: "reactivationToggle")
        }
        NSUserDefaults.standardUserDefaults().synchronize()
    }


    // MARK: - URL handlers

    var quicklookMediaURL: NSURL? {
        didSet {
            if quicklookMediaURL != nil {
                QLPreviewPanel.sharedPreviewPanel().makeKeyAndOrderFront(nil);
            }
        }
    }

}
