//
//  PrefViewController.swift
//  Orangered
//
//  Created by Alan Westbrook on 6/17/16.
//  Copyright © 2016 Rockwood Software. All rights reserved.
//

import Cocoa
import ServiceManagement

class PrefViewController: NSViewController {

    let startAtLogin = NSButton(cbWithTitle: "Start at Login", target: nil, action: #selector(salClicked))

    override func viewDidLoad() {
        super.viewDidLoad()
    
        setup()
    }
    
    override func loadView() {
        // Don't call into super, as we don't want it to try to load from a nib
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
    }
    
    fileprivate func setup() {
        startAtLogin.target = self
        startAtLogin.translatesAutoresizingMaskIntoConstraints = false
        
        title = "Orangered! Preferences"
        
        view.addSubview(startAtLogin)
        
        NSLayoutConstraint.activate([
            startAtLogin.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10),
            startAtLogin.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            view.bottomAnchor.constraint(equalTo: startAtLogin.bottomAnchor, constant: 10),
            view.widthAnchor.constraint(equalTo: startAtLogin.widthAnchor, constant: 20)
        ])
    }
    
    @objc fileprivate func salClicked() {
        print(SMLoginItemSetEnabled("com.rockwood.Orangered" as CFString, true))
    }
}

extension NSButton {
    convenience init(cbWithTitle title: String, target: NSObject?, action: Selector) {
        if #available(OSX 10.12, *) {
            self.init(checkboxWithTitle: title, target: target, action: action)
        } else {
            self.init()
            setButtonType(.switch)
            self.title = title
            self.target = target
            self.action = action
        }
        
    }
}
