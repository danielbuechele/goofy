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

    // MARK: - ContentController message handler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        
        let bodyValue = message.body as? NSDictionary
        let type = bodyValue?["type"] as! String
        let appDelegate = NSApplication.shared().delegate as! AppDelegate;
        
        switch type {
            case "NOT_LOGGED_IN":
                0
                //appDelegate.notLoggedIn()
                break
            case "LOADED":
                appDelegate.loadingView?.isHidden = true
                break
            case "NOTIFICATION":
                let pictureUrl = URL(string: bodyValue?["pictureUrl"] as! String)
                displayNotification(bodyValue?["title"] as! NSString, text: bodyValue?["text"] as! NSString, id: bodyValue?["id"] as! NSString, picture: NSImage(contentsOf: pictureUrl!))
                break
            case "DOCK_COUNT":
                dockCount(bodyValue?["content"] as! String)
                break
            case "SHOW_IMAGE":
                appDelegate.quicklookMediaURL = URL(string: (bodyValue?["url"] as! String))
                break
            case "CHOOSE_IMAGE":
                appDelegate.menuHandler.sendImage(nil)
                break
            case "SET_TITLE":
                appDelegate.titleLabel.setTitle(bodyValue?["title"] as! String, active: bodyValue?["activity"] as! String)
                break
            case "LOG":
                print(message.body)
            default:
                0
        }
    }

    
    // MARK: - Dock Badge counter, Status Item state

    func dockCount(_ count: String) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate;

        if (count == "0") {
            NSApplication.shared().dockTile.badgeLabel = ""
            appDelegate.changeStatusItemImage("StatusItem")
        } else {
            NSApplication.shared().dockTile.badgeLabel = count
            appDelegate.changeStatusItemImage("StatusItemUnread")
        }
    }


    // MARK: - OSX Notifications

    func displayNotification(_ title: NSString, text: NSString, id: NSString, picture: NSImage?) {
        let notification:NSUserNotification = NSUserNotification()
        notification.title = title as String
        notification.informativeText = text as String
        if let contentImage = picture {
            notification.contentImage = roundCorners(contentImage)
        }
        notification.deliveryDate = Date()
        notification.responsePlaceholder = "Reply"
        notification.hasReplyButton = true
        notification.userInfo = ["id":id]

        let notificationcenter:NSUserNotificationCenter = NSUserNotificationCenter.default
        notificationcenter.delegate = self
        notificationcenter.scheduleNotification(notification)
    }

    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate;
        let id = notification.userInfo!["id"] as! String
        if (notification.activationType == NSUserNotification.ActivationType.replied){
            let userResponse = notification.response?.string.replacingOccurrences(of: "\n", with: "\\n");
            appDelegate.webView.evaluateJavaScript("replyToNotification('" + id + "','" + userResponse! + "')", completionHandler: nil);
        } else {
            appDelegate.webView.evaluateJavaScript("reactivation('" + id + "')", completionHandler: nil);
        }
    }


    // MARK: - Image Processing
    
    func roundCorners(_ image: NSImage) -> NSImage {
        
        let existingImage = image
        let imageSize = existingImage.size
        let width = imageSize.width
        let height = imageSize.height
        let xRad = width / 2
        let yRad = height / 2
        let newSize = NSMakeSize(imageSize.height, imageSize.width)
        let roundedImage = NSImage(size: newSize)
        
        roundedImage.lockFocus()
        let ctx = NSGraphicsContext.current()
        ctx?.imageInterpolation = NSImageInterpolation.high
        
        let imageFrame = NSRect(x: 0, y: 0, width: width, height: height)
        let clipPath = NSBezierPath(roundedRect: imageFrame, xRadius: xRad, yRadius: yRad)
        clipPath.windingRule = NSWindingRule.evenOddWindingRule
        clipPath.addClip()
        
        let rect = NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        image.draw(at: NSZeroPoint, from: rect, operation: NSCompositingOperation.sourceOver, fraction: 1)
        roundedImage.unlockFocus()
        
        return roundedImage
    }
    
}
