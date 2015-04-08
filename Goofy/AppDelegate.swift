//
//  AppDelegate.swift
//  Goofy
//
//  Created by Daniel Büchele on 11/29/14.
//  Copyright (c) 2014 Daniel Büchele. All rights reserved.
//

import Cocoa
import WebKit
import QuartzCore

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate {
    
    @IBOutlet var window : NSWindow!
    var webView : WKWebView!
    @IBOutlet var view : NSView!
    @IBOutlet var loadingView : NSImageView!
    @IBOutlet var spinner : NSProgressIndicator!
    @IBOutlet var longLoading : NSTextField!
    @IBOutlet var reactivationMenuItem : NSMenuItem!
    @IBOutlet var statusbarMenuItem : NSMenuItem!
    var timer : NSTimer!
    var activatedFromBackground = false
    
    var statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        window.backgroundColor = NSColor.whiteColor()
        window.minSize = NSSize(width: 680,height: 376)
        window.makeMainWindow()
        window.makeKeyWindow()
        window.titlebarAppearsTransparent = true
        
        loadingView.layer?.backgroundColor = NSColor.whiteColor().CGColor
        startLoading()
        
        #if DEBUG
            let path = NSBundle.mainBundle().objectForInfoDictionaryKey("PROJECT_DIR") as String!
            var source = String(contentsOfFile: path+"/server/dist/fb.js", encoding: NSUTF8StringEncoding, error: nil)!+"init();"
        #else
            let version = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as String!
            var jsurl = "https://dani.taurus.uberspace.de/goofyapp/fb" + version + ".js"
            if (NSBundle.mainBundle().objectForInfoDictionaryKey("GoofyJavaScriptURL") != nil) {
                jsurl = NSBundle.mainBundle().objectForInfoDictionaryKey("GoofyJavaScriptURL") as String!
            }
            let source = "function getScript(url,success){ var script = document.createElement('script'); script.src = url; var head = document.getElementsByTagName('head')[0], done=false; script.onload = script.onreadystatechange = function(){ if (!done && (!this.readyState || this.readyState == 'loaded' || this.readyState == 'complete')) { done=true; success(); script.onload = script.onreadystatechange = null; head.removeChild(script); } }; head.appendChild(script); }" +
            "getScript('" + jsurl + "', function() {init();});"
        #endif
        
        var reactivationToggle : Bool? = NSUserDefaults.standardUserDefaults().objectForKey("reactivationToggle") as? Bool
        if (reactivationToggle != nil && reactivationToggle==true) {
            self.reactivationMenuItem.state = 1
        }
        
        let userScript = WKUserScript(source: source, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
        
        let userContentController = WKUserContentController()
        userContentController.addUserScript(userScript)
        
        let handler = NotificationScriptMessageHandler()
        userContentController.addScriptMessageHandler(handler, name: "notification")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        
        webView = WKWebView(frame: self.view.bounds, configuration: configuration)
        //webView.configuration.preferences.enableDevExtras();
        webView.navigationDelegate = self
        webView.UIDelegate = self
        
        view.addSubview(webView, positioned: NSWindowOrderingMode.Below, relativeTo: view);
        webView.autoresizingMask = NSAutoresizingMaskOptions.ViewWidthSizable | NSAutoresizingMaskOptions.ViewHeightSizable
        
        var s = NSProcessInfo.processInfo().arguments[0].componentsSeparatedByString("/")
        var st: String = s[s.count-4] as String
        var url : String = "https://www.messenger.com"
        
        /* Facebook at word support. Needs to be updated for Messenger.com
        if (st.rangeOfString("Goofy") != nil && countElements(st) > 10) {
            st = (st as NSString).stringByReplacingCharactersInRange(NSRange(location: 0,length: 6), withString: "")
            url = "https://" + st.stringByReplacingOccurrencesOfString(".app", withString:"") + ".facebook.com/messages"
            changeDockIcon()
        }*/
        
        var req = NSMutableURLRequest(URL: NSURL(string: url)!)
        req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/600.3.17 (KHTML, like Gecko) Version/8.0.3 Safari/600.3.17", forHTTPHeaderField: "User-Agent")
        webView.loadRequest(req);
        
        
        /*
        statusBarItem = statusBar.statusItemWithLength(-1)
        var si = NSImage(named: "StatusItem")
        si?.setTemplate(true)
        statusBarItem.image = si
        statusBarItem.target = self
        statusBarItem.action = Selector("statusBarItemClicked")
        */
        /*
        var contents : [String] = NSFileManager.defaultManager().contentsOfDirectoryAtPath("~/Library/Preferences/ByHost/".stringByExpandingTildeInPath, error: nil) as [String];
        contents = contents.filter( { (file: String) -> Bool in
            return file.rangeOfString("com.apple.notificationcenterui") != nil
        })
        var myDict = NSDictionary(contentsOfFile: "~/Library/Preferences/ByHost/".stringByExpandingTildeInPath+"/"+contents[0])
        println(myDict!["doNotDisturb"]!)
        */
        
        
    }
    
    
    func webView(webView: WKWebView!, decidePolicyForNavigationAction navigationAction: WKNavigationAction!, decisionHandler: ((WKNavigationActionPolicy) -> Void)!) {
        
        var backgroundURLs : Array = ["messenger.com","facebook.com/","facebook.com/ai.php","fbcdn","facebook.com/sound_iframe"]
        var inAppURLs : Array = ["facebook.com/messages","facebook.com/login","facebook.com/sound_iframe"]
        
        if let backgroundURLsUser = NSUserDefaults.standardUserDefaults().objectForKey("backgroundURLs") as? Array<String> {
            backgroundURLs.extend(backgroundURLsUser)
        }
        
        if let inAppURLsUser = NSUserDefaults.standardUserDefaults().objectForKey("inAppURLs") as? Array<String> {
            inAppURLs.extend(inAppURLsUser)
        }
        
        let inApp = inAppURLs.map({(url: String) -> Bool in
            return navigationAction.request.URL.absoluteString!.rangeOfString(url) != nil;
        })
        
        let background = backgroundURLs.map({(url: String) -> Bool in
            return navigationAction.request.URL.absoluteString!.rangeOfString(url) != nil;
        })
        
        if (contains(inApp,true) || contains(background,true)) {
            if (contains(inApp,true)) {
                startLoading()
            }
            decisionHandler(.Allow)
        } else {
            NSWorkspace.sharedWorkspace().openURL(navigationAction.request.URL)
            decisionHandler(.Cancel)
        }
    }
    
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: Selector("endLoading"), userInfo: nil, repeats: false)
    }
    
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    
    func applicationDidBecomeActive(aNotification: NSNotification) {
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
    
    
    @IBAction func reopenWindow(sender: AnyObject) {
        window.makeKeyAndOrderFront(self)
    }
    
    
    @IBAction func reload(sender: AnyObject) {
        startLoading()
        webView.reload()
    }
    
    @IBAction func toggleReactivation(sender: AnyObject) {
        var i : NSMenuItem = sender as NSMenuItem
        
        if (i.state == 0) {
            i.state = NSOnState
            NSUserDefaults.standardUserDefaults().setObject(true, forKey: "reactivationToggle")
        } else {
            i.state = NSOffState
            NSUserDefaults.standardUserDefaults().setObject(false, forKey: "reactivationToggle")
        }
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    
    func endLoading() {
        timer.invalidate()
        loadingView.hidden = true
        spinner.stopAnimation(self)
        spinner.hidden = true
        longLoading.hidden = true
        
    }
    
    func startLoading() {
        loadingView.hidden = false
        spinner.startAnimation(self)
        spinner.hidden = false
        longLoading.hidden = true
        timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: Selector("longLoadingMessage"), userInfo: nil, repeats: false)
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

