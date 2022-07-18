//
//  main.swift
//  Orangered
//
//  Created by Alan Westbrook on 5/29/16.
//  Copyright © 2016 Rockwood Software. All rights reserved.
//

import AppKit

autoreleasepool { () -> () in
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}

