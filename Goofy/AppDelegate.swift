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
    
    @IBOutlet var window : NSWindow!
    var webView : WKWebView!
    @IBOutlet var view : NSView!
    @IBOutlet var loadingView : NSImageView!
    @IBOutlet var spinner : NSProgressIndicator!
    @IBOutlet var longLoading : NSTextField!
    @IBOutlet var reactivationMenuItem : NSMenuItem!
    @IBOutlet var statusbarMenuItem : NSMenuItem!
    @IBOutlet var toolbarTrenner : NSToolbarItem!
    @IBOutlet var toolbarSpacing : NSToolbarItem!
    @IBOutlet var toolbar : NSToolbar!
    @IBOutlet var titleLabel : TitleLabel!
    @IBOutlet var menuHandler : MenuHandler!
    
    var timer : NSTimer!
    var activatedFromBackground = false
    var isFullscreen = false
    
    var statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        window.backgroundColor = NSColor.whiteColor()
        window.minSize = NSSize(width: 380,height: 376)
        window.makeMainWindow()
        window.makeKeyWindow()
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .Hidden
        window.delegate = self
        loadingView.layer?.backgroundColor = NSColor.whiteColor().CGColor

        
        sizeWindow(window)
        
        startLoading()
        
        #if DEBUG
            let path = NSBundle.mainBundle().objectForInfoDictionaryKey("PROJECT_DIR") as! String
            var source = String(contentsOfFile: path+"/server/dist/fb.js", encoding: NSUTF8StringEncoding, error: nil)!+"init();"
        #else
            let version = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
            var jsurl = "https://dani.taurus.uberspace.de/goofyapp/fb" + version + ".js"
            if (NSBundle.mainBundle().objectForInfoDictionaryKey("GoofyJavaScriptURL") != nil) {
                jsurl = NSBundle.mainBundle().objectForInfoDictionaryKey("GoofyJavaScriptURL") as! String
            }
            let source = "function getScript(url,success){ var script = document.createElement('script'); script.src = url; var head = document.getElementsByTagName('head')[0], done=false; script.onload = script.onreadystatechange = function(){ if (!done && (!this.readyState || this.readyState == 'loaded' || this.readyState == 'complete')) { done=true; success(); script.onload = script.onreadystatechange = null; head.removeChild(script); } }; head.appendChild(script); }" +
            "getScript('" + jsurl + "', function() {init();});"
        #endif
        
        var reactivationToggle : Bool? = NSUserDefaults.standardUserDefaults().objectForKey("reactivationToggle") as? Bool
        if (reactivationToggle != nil && reactivationToggle==true) {
            self.reactivationMenuItem.state = 1
        }
        
        let userScript = WKUserScript(source: source, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
        let reactDevTools = WKUserScript(source: "Object.defineProperty(window, '__REACT_DEVTOOLS_GLOBAL_HOOK__', {value: {inject: function(runtime) {this._reactRuntime = runtime; },getSelectedInstance: null,Overlay: null}});", injectionTime: .AtDocumentStart, forMainFrameOnly: true)
        
        let userContentController = WKUserContentController()
        userContentController.addUserScript(userScript)
        userContentController.addUserScript(reactDevTools)
        
        let handler = NotificationScriptMessageHandler()
        userContentController.addScriptMessageHandler(handler, name: "notification")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        
        webView = WKWebView(frame: self.view.bounds, configuration: configuration)
        webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        webView.navigationDelegate = self
        webView.UIDelegate = self
        webView.setValue(true, forKey: "drawsTransparentBackground")
        
        
        // Layout
        view.addSubview(webView, positioned: NSWindowOrderingMode.Below, relativeTo: view);
        webView.autoresizingMask = NSAutoresizingMaskOptions.ViewWidthSizable | NSAutoresizingMaskOptions.ViewHeightSizable
        
        var s = NSProcessInfo.processInfo().arguments[0].componentsSeparatedByString("/")
        var st: String = s[s.count-4] as! String
        var url : String = "https://messenger.com/login"
        
        var req = NSMutableURLRequest(URL: NSURL(string: url)!)
        webView.loadRequest(req);
        
        
    }
    
    func windowDidResize(notification: NSNotification) {
        sizeWindow(notification.object as! NSWindow)
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
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: ((WKNavigationActionPolicy) -> Void)) {
        
        if let url = navigationAction.request.URL {
            if let host = url.host {
                var inApp = url.host!.hasSuffix("messenger.com") && !url.path!.hasPrefix("/l.php");
                var isLogin = url.host!.hasSuffix("facebook.com") && (url.path!.hasPrefix("/login") || url.path!.hasPrefix("/checkpoint"));
                
                if inApp || isLogin {
                    decisionHandler(.Allow)
                } else {
                    NSWorkspace.sharedWorkspace().openURL(navigationAction.request.URL!)
                    decisionHandler(.Cancel)
                }
            } else {
                decisionHandler(.Cancel)
            }
        } else {
            decisionHandler(.Cancel)
        }
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {

        
        NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: Selector("endLoading"), userInfo: nil, repeats: false)
        if webView.URL!.absoluteString!.rangeOfString("messenger.com/login") == nil{
            showMenuBar()
        }
        
    }
    
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    
    func applicationDidBecomeActive(aNotification: NSNotification) {
        NSApplication.sharedApplication().dockTile.badgeLabel = ""
        if (self.activatedFromBackground) {
            if (self.reactivationMenuItem.state == 1) {
                webView.evaluateJavaScript("reactivation()", completionHandler: nil);
            }
        } else {
            self.activatedFromBackground = true;
        }
        reopenWindow(self)
    }
    
    func changeDockIcon() {
        NSApplication.sharedApplication().applicationIconImage = NSImage(named: "Image")
    }
    
    func applicationShouldOpenUntitledFile(sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationOpenUntitledFile(sender: NSApplication) -> Bool {
        reopenWindow(self)
        return true
    }

    func windowDidEnterFullScreen(notification: NSNotification) {
        isFullscreen = true
        sizeWindow(window)
    }
    
    func windowDidExitFullScreen(notification: NSNotification) {
        isFullscreen = false
        sizeWindow(window)
    }
    
    
    @IBAction func reopenWindow(sender: AnyObject) {
        window.makeKeyAndOrderFront(self)
    }
    
    @IBAction func toggleReactivation(sender: AnyObject) {
        var i : NSMenuItem = sender as! NSMenuItem
        
        if (i.state == 0) {
            i.state = NSOnState
            NSUserDefaults.standardUserDefaults().setObject(true, forKey: "reactivationToggle")
        } else {
            i.state = NSOffState
            NSUserDefaults.standardUserDefaults().setObject(false, forKey: "reactivationToggle")
        }
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    var quicklookMediaURL: NSURL? {
        didSet {
            if quicklookMediaURL != nil {
                QLPreviewPanel.sharedPreviewPanel().makeKeyAndOrderFront(nil);
            }
        }
    }
    
    func endLoading() {
        timer.invalidate()
        loadingView.hidden = true
        spinner.stopAnimation(self)
        spinner.hidden = true
        longLoading.hidden = true

        sizeWindow(window)
    }
    
    func showMenuBar() {
        for item in toolbar.items {
            let i = item as! NSToolbarItem
            i.view?.hidden = false
            i.image = NSImage(named: i.label)
        }
        sizeWindow(window)
    }
    
    func hideMenuBar() {
        for item in toolbar.items {
            let i = item as! NSToolbarItem
            i.view?.hidden = true
            i.image = NSImage(named: "White")
        }
    }
    
    func startLoading() {
        loadingView.hidden = false
        spinner.startAnimation(self)
        spinner.hidden = false
        longLoading.hidden = true
        timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: Selector("longLoadingMessage"), userInfo: nil, repeats: false)
        
        hideMenuBar()
        
    }
    
    func longLoadingMessage() {
        if (!loadingView.hidden) {
            longLoading.hidden = false
        }
    }
    
    func statusBarItemClicked() {
        webView.evaluateJavaScript("reactivation()", completionHandler: nil);
        reopenWindow(self)
        NSApp.activateIgnoringOtherApps(true)
    }
    


}
