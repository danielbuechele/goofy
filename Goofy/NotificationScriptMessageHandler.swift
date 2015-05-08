//
//  NotificationScriptMessageHandler.swift
//  Goofy
//
//  Created by Daniel Büchele on 11/29/14.
//  Copyright (c) 2014 Daniel Büchele. All rights reserved.
//

import Foundation
import WebKit

class NotificationScriptMessageHandler: NSObject, WKScriptMessageHandler, NSUserNotificationCenterDelegate {
        
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        
        let type = message.body["type"] as! NSString
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
        
        switch type {
            case "NOT_LOGGED_IN":
                0
                //appDelegate.notLoggedIn()
                break
            case "LOADED":
                appDelegate.loadingView.hidden = true
                break
            case "NOTIFICATION":
                displayNotification(message.body["title"] as! NSString, text: message.body["text"] as! NSString, id: message.body["id"] as! NSString)
                break
            case "DOCK_COUNT":
                dockCount(message.body["content"] as! String)
                break
            case "SHOW_IMAGE":
                println(message.body["url"] as! String)
                appDelegate.quicklookMediaURL = NSURL(string: (message.body["url"] as! String))
                break
            case "CHOOSE_IMAGE":
                appDelegate.menuHandler.sendImage(nil)
                break
        case "SET_TITLE":
                appDelegate.titleLabel.setTitle(message.body["title"] as! String, active: message.body["activity"] as! String)
                break
            default:
                0
        }
    }
    
    func displayNotification(title: NSString, text: NSString, id: NSString) {
        var notification:NSUserNotification = NSUserNotification()
        notification.title = title as String
        notification.informativeText = text as String
        notification.deliveryDate = NSDate()
        notification.responsePlaceholder = "Reply"
        notification.hasReplyButton = true
        notification.userInfo = ["id":id]
        
        var notificationcenter:NSUserNotificationCenter = NSUserNotificationCenter.defaultUserNotificationCenter()
        notificationcenter.delegate = self
        notificationcenter.scheduleNotification(notification)
    }
    
    func dockCount(count: String) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
        var si = NSImage(named: "StatusItem")
        
        if (count == "0") {
            NSApplication.sharedApplication().dockTile.badgeLabel = ""
        } else {
            NSApplication.sharedApplication().dockTile.badgeLabel = count
            //var si = NSImage(named: "StatusItemUnread")
        }
        //si?.setTemplate(true)
        
        //appDelegate.statusBarItem.image = si
    }
    
    func userNotificationCenter(center: NSUserNotificationCenter, didActivateNotification notification: NSUserNotification) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
        let id = notification.userInfo!["id"] as! String
        if (notification.activationType == NSUserNotificationActivationType.Replied){
            let userResponse = notification.response?.string;
            appDelegate.webView.evaluateJavaScript("replyToNotification('" + id + "','" + userResponse! + "')", completionHandler: nil);
        } else {
            appDelegate.webView.evaluateJavaScript("reactivation('" + id + "')", completionHandler: nil);
        }
    }
    
}