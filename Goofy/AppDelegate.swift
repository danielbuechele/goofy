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

    var timer : Timer!
    var activatedFromBackground = false
    var isFullscreen = false

    var statusItem = NSStatusItem()
    var statusItemConfigurationKey = "showStatusItem"
    var statusItemDefault = true


    // MARK: - NSApplication
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
		// Init Window
        initWindow(window)
        sizeWindow(window)

        // Start Loading
        startLoading()

		// Create Webview
        webView = createWebview(createContentController())
        view.addSubview(webView, positioned: NSWindowOrderingMode.below, relativeTo: view);

		// Load URL
        let url : String = "https://messenger.com/login"
        let req = NSMutableURLRequest(url: URL(string: url)!)
        webView.load(req as URLRequest);
    }

    func applicationDidBecomeActive(_ aNotification: Notification) {
        NSApplication.shared().dockTile.badgeLabel = ""
        if (self.activatedFromBackground) {
            if (self.reactivationMenuItem.state == 1) {
                webView.evaluateJavaScript("reactivation()", completionHandler: nil)
            }

        } else {
            self.activatedFromBackground = true;
        }
        reopenWindow(self)
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        reopenWindow(self)
        return true
    }


    // MARK: - WKWebView

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(AppDelegate.endLoading), userInfo: nil, repeats: false)
        if webView.url!.absoluteString.range(of: "messenger.com/login") == nil{
            showMenuBar()
        }
    }
    
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                                                for navigationAction: WKNavigationAction,
                                                                    windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Handle video playback and links opened in a new window.
        if navigationAction.targetFrame == nil {
            let url = navigationAction.request.url!
            if url.description.lowercased().range(of: "http://") != nil || url.description.lowercased().range(of: "https://") != nil || url.description.lowercased().range(of: "mailto:") != nil  {

                NSWorkspace.shared().open(url)
            }
        }
        return nil
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: (@escaping (WKNavigationActionPolicy) -> Void)) {
        
        if let url = navigationAction.request.url {
            if let host = url.host {
                let inApp = host.hasSuffix("messenger.com") && !url.path.hasPrefix("/l.php");
                let isLogin = host.hasSuffix("facebook.com") && (url.path.hasPrefix("/login") || url.path.hasPrefix("/checkpoint"));
                
                if inApp || isLogin {
                    decisionHandler(.allow)
                } else {

                    // Check if the host is l.messenger.com
                    let facebookFormattedLink = (url.host! == "l.messenger.com");

                    // If such is the case...
                    if facebookFormattedLink {
                        do {
                            // Generate a NSRegularExpression to match our url, extracting the value of u= into it own regex group.
                            let regex = try NSRegularExpression(pattern: "(https://l.messenger.com/l.php\\?u=)(.+)(&h=.+)", options: [])
                            let nsString = url.absoluteString as NSString
                            let results = regex.firstMatch(in: url.absoluteString, options: [], range: NSMakeRange(0, nsString.length))

                            // Take the result, pull it out of our string, and decode the url string
                            let referenceString = nsString.substring(with: results!.rangeAt(2)).removingPercentEncoding!

                            // Open it up as a normal url
                            NSWorkspace.shared().open(URL(string: referenceString)!)
                            decisionHandler(.cancel)
                        } catch {
                            NSWorkspace.shared().open(url)
                            decisionHandler(.cancel)
                        }
                    } else {
                        NSWorkspace.shared().open(url)
                        decisionHandler(.cancel)
                    }
                }
            } else {
                decisionHandler(.cancel)
            }
        } else {
            decisionHandler(.cancel)
        }
    }

    func createWebview(_ contentController: WKUserContentController) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController

        let wv = WKWebView(frame: self.view.bounds, configuration: configuration)
        wv.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        wv.navigationDelegate = self
        wv.uiDelegate = self
        wv.autoresizingMask = [NSAutoresizingMaskOptions.viewWidthSizable, NSAutoresizingMaskOptions.viewHeightSizable]

        return wv
    }


    // MARK: - NSWindow

    func windowDidEnterFullScreen(_ notification: Notification) {
        isFullscreen = true
        sizeWindow(window)
    }
    
    func windowDidExitFullScreen(_ notification: Notification) {
        isFullscreen = false
        sizeWindow(window)
    }

    func windowDidResize(_ notification: Notification) {
        sizeWindow(notification.object as! NSWindow)
    }

    func initWindow(_ window: NSWindow) {
        window.backgroundColor = NSColor.white
        window.minSize = NSSize(width: 380,height: 376)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.delegate = self
	}

    func sizeWindow(_ window: NSWindow) {

        if window.frame.width > 640.0 && !self.isFullscreen {
            toolbarTrenner.minSize = NSSize(width: 1, height: 100)
            toolbarTrenner.maxSize = NSSize(width: 1, height: 100)
            toolbarTrenner.view?.frame = CGRect(x: 0, y: 0, width: 1, height: 100)
            toolbarTrenner.view?.layer?.backgroundColor = NSColor(white: 0.9, alpha: 1.0).cgColor


            toolbarSpacing.minSize = NSSize(width: 157, height: 100)
            toolbarSpacing.maxSize = NSSize(width: 157, height: 100)
            toolbarSpacing.view = NSView(frame: CGRect(x: 0, y: 0, width: 157, height: 100))
        } else {
            toolbarTrenner.view?.layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.0).cgColor

            toolbarSpacing.minSize = NSSize(width: 0, height: 100)
            toolbarSpacing.maxSize = NSSize(width: 0, height: 100)
        }

        titleLabel.windowDidResize()
    }


    // MARK: - Main Menu

    func showMenuBar() {
        for item in toolbar.items {
            let i = item 
            i.view?.isHidden = false
            i.image = NSImage(named: i.label)
        }
        sizeWindow(window)
    }
    
    func hideMenuBar() {
        for item in toolbar.items {
            let i = item 
            i.view?.isHidden = true
            i.image = NSImage(named: "White")
        }
    }


    // MARK: - ContentController (JavaScript Injection)

    func createContentController() -> WKUserContentController {

        let userContentController = WKUserContentController()

        #if DEBUG
            let path = Bundle.main.object(forInfoDictionaryKey: "PROJECT_DIR") as! String
            let source = (try! String(contentsOfFile: path+"/server/dist/fb.js", encoding: String.Encoding.utf8))+"init();"
        #else
            let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
            var jsurl = "https://dani.taurus.uberspace.de/goofyapp/fb" + version + ".js"
            if (Bundle.main.object(forInfoDictionaryKey: "GoofyJavaScriptURL") != nil) {
                jsurl = Bundle.main.object(forInfoDictionaryKey: "GoofyJavaScriptURL") as! String
            }
            let source = "function getScript(url,success){ var script = document.createElement('script'); script.src = url; var head = document.getElementsByTagName('head')[0], done=false; script.onload = script.onreadystatechange = function(){ if (!done && (!this.readyState || this.readyState == 'loaded' || this.readyState == 'complete')) { done=true; success(); script.onload = script.onreadystatechange = null; head.removeChild(script); } }; head.appendChild(script); }" +
                "getScript('" + jsurl + "', function() {init();});"
        #endif

        let reactivationToggle : Bool? = UserDefaults.standard.object(forKey: "reactivationToggle") as? Bool
        if (reactivationToggle != nil && reactivationToggle==true) {
            self.reactivationMenuItem.state = 1
        }

        let userScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let reactDevTools = WKUserScript(source: "Object.defineProperty(window, '__REACT_DEVTOOLS_GLOBAL_HOOK__', {value: {_renderers: {},helpers: {},inject: function(renderer) {var id = Math.random().toString(16).slice(2);this._renderers[id] = renderer;this.emit('renderer', {id, renderer});},_listeners: {},sub: function(evt, fn) {this.on(evt, fn);return function () {this.off(evt, fn)};},on: function(evt, fn) {if (!this._listeners[evt]) {this._listeners[evt] = [];}this._listeners[evt].push(fn);},off: function(evt, fn) {if (!this._listeners[evt]) {return;}var ix = this._listeners[evt].indexOf(fn);if (ix !== -1) {this._listeners[evt].splice(ix, 1);}if (!this._listeners[evt].length) {this._listeners[evt] = null;}},emit: function(evt, data) {if (this._listeners[evt]) {this._listeners[evt].map(function fn() {fn(data)});}}}});", injectionTime: .atDocumentStart, forMainFrameOnly: true)


        userContentController.addUserScript(userScript)
        userContentController.addUserScript(reactDevTools)

        let handler = NotificationScriptMessageHandler()
        userContentController.add(handler, name: "notification")

        return userContentController
    }


    // MARK: - Content Loading
    
    func startLoading() {
        loadingView?.layer?.backgroundColor = NSColor.white.cgColor

        loadingView?.isHidden = false
        spinner.startAnimation(self)
        spinner.isHidden = false
        longLoading.isHidden = true
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(AppDelegate.longLoadingMessage), userInfo: nil, repeats: false)
        
        hideMenuBar()
    }

    func endLoading() {
        timer.invalidate()
        loadingView?.isHidden = true
        spinner.stopAnimation(self)
        spinner.isHidden = true
        longLoading.isHidden = true

        sizeWindow(window)
    }

    func longLoadingMessage() {
        if (loadingView?.isHidden == false) {
            longLoading.isHidden = false
        }
    }


    // MARK: - Dock Icon

    func changeDockIcon() {
        NSApplication.shared().applicationIconImage = NSImage(named: "Image")
    }


    // MARK: - Status Item

    func statusBarItemClicked() {
        webView.evaluateJavaScript("reactivation()", completionHandler: nil);
        
        let currentEvent    = NSApp.currentEvent!
        let isRightClicked  = (currentEvent.type == NSEventType.rightMouseUp) ? true : false
        
        if isRightClicked {
            // Set up the statusMenu and show it.
            statusItem.menu = statusMenu
            statusItem.popUpMenu(statusMenu)
            statusItem.menu = nil
        } else {
            // A left click on the statusItem shows/hides the window
            if !window.isVisible {
                reopenWindow(self)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                window.setIsVisible(false)
            }
        }
    }

    func addStatusItem() {
        statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
        
        
        if let button = statusItem.button {
			changeStatusItemImage("StatusItem")
            NSApp.setActivationPolicy(.accessory) // Hide dock icon and menu bar
            button.action = #selector(self.statusBarItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    func hideStatusItem() {
    	NSStatusBar.system().removeStatusItem(statusItem)
        NSApp.setActivationPolicy(.regular)
        
        if !window.isVisible {
            reopenWindow(self)
            NSApp.activate(ignoringOtherApps: true)
            // Or could be just use to not show the window window.makeKeyWindow()
        }
    }

    func changeStatusItemImage(_ newImage: String) {
        if let button = statusItem.button {
            let image = NSImage(named: newImage)
            image!.isTemplate = true
            button.image = image
        }
    }

    func initStatusItem() {
        if ((UserDefaults.standard.object(forKey: statusItemConfigurationKey)) == nil) {
            UserDefaults.standard.set(statusItemDefault, forKey: statusItemConfigurationKey)
        } else {
			updateStatusItemVisibility()
        }
    }

    func toggleStatusItemConfiguration() {
        print (UserDefaults.standard.bool(forKey: statusItemConfigurationKey) )
        if (UserDefaults.standard.bool(forKey: statusItemConfigurationKey) == true) {
            UserDefaults.standard.set(false, forKey: statusItemConfigurationKey)
        } else {
            UserDefaults.standard.set(true, forKey: statusItemConfigurationKey)
        }

    }

    func updateStatusItemVisibility() {
        if (UserDefaults.standard.bool(forKey: statusItemConfigurationKey) == true) {
            addStatusItem()
        } else {
            hideStatusItem()
        }
    }

    @IBAction func toggleStatusItem(_ sender: AnyObject) {
        
		toggleStatusItemConfiguration()
        updateStatusItemVisibility()
    }


    // MARK: - Interface Builder interface

    @IBAction func reopenWindow(_ sender: AnyObject) {
        window.makeKeyAndOrderFront(self)
    }

    @IBAction func toggleReactivation(_ sender: AnyObject) {
        let i : NSMenuItem = sender as! NSMenuItem

        if (i.state == 0) {
            i.state = NSOnState
            UserDefaults.standard.set(true, forKey: "reactivationToggle")
        } else {
            i.state = NSOffState
            UserDefaults.standard.set(false, forKey: "reactivationToggle")
        }
        UserDefaults.standard.synchronize()
    }


    // MARK: - URL handlers

    var quicklookMediaURL: URL? {
        didSet {
            if quicklookMediaURL != nil {
                QLPreviewPanel.shared().makeKeyAndOrderFront(nil);
            }
        }
    }

}
