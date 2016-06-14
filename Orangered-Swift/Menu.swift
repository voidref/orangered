//
//  Menu.swift
//  Orangered
//
//  Created by Alan Westbrook on 6/13/16.
//  Copyright © 2016 Rockwood Software. All rights reserved.
//

import Foundation
import Cocoa


class Menu: NSMenu {
    
    init() {
        super.init(title: "Orangered!")
        
        setup()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        autoenablesItems = false
    }
}
