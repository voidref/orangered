//
//  AppDelegate.swift
//  Orangered-Swift
//
//  Created by Alan Westbrook on 5/29/16.
//  Copyright © 2016 Rockwood Software. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    var controller:StatusItemController!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        controller = StatusItemController()
    }
}




