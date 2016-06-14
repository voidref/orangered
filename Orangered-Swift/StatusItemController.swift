//
//  StatusItemController.swift
//  Orangered
//
//  Created by Alan Westbrook on 6/13/16.
//  Copyright © 2016 Rockwood Software. All rights reserved.
//

import Foundation
import Cocoa

class StatusItemController: NSObject {
    
    enum State {
        case disconnected
        case connected
        case new
    }
    
    private var state = State.disconnected {
        didSet {
            updateState()
        }
    }
    
    private let statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
    
    private var statusPoller = Timer()
    private let prefs = UserDefaults.standard()
    private var statusConnection:URLSession?
    private let session = URLSession.shared()
    
    override init() {
        prefs.password = "refreddvoid"
        super.init()
        setup()
        login()
    }
    
    private func setup() {
        prefs.username = "voidref"
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = Menu()
        
        let loginItem = NSMenuItem(title: "Login...", action: #selector(handleLoginMenuSelected), keyEquivalent: "")
        menu.addItem(loginItem)
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "")
        menu.addItem(quitItem)
        
        menu.items.forEach { (item) in
            item.target = self
        }
        
        statusItem.menu = menu
        
        let image = NSImage(named: "GreyEnvelope")
        image?.isTemplate = true
        statusItem.image = image
        statusItem.highlightMode = true
    }
    
    private func login() {
        guard let url = URL(string: "https://ssl.reddit.com/api/login"),
            let uname = prefs.username,
            let password = prefs.password else {
                print("Error bad url, wat?")
                return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "user=\(uname)&passwd=\(password)".data(using: String.Encoding.utf8)
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            if let responseActual = response as? HTTPURLResponse {
                self.handleLoginResponse(responseActual)
            }
        })
        
        task.resume()
    }
    
    private func handleLoginResponse(_ response:HTTPURLResponse) {
        
        guard let headers = response.allHeaderFields as? [String:String] else {
            print("wrong headers ... or so: \(response.allHeaderFields)")
            return
        }
        
        guard let url = response.url else {
            print("missing url from response: \(response)")
            return
        }
        
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
        
        if cookies.count < 1 {
            print("Login error: \(response)")
        }
        else {
            HTTPCookieStorage.shared().setCookies(cookies, for: URL(string: "https://reddit.com"), mainDocumentURL: nil)
            
            setupStatusPoller()
        }
    }
    
    private func setupStatusPoller() {
        statusPoller.invalidate()
        let interval:TimeInterval = 60
        
        statusPoller = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(updateState), userInfo: nil, repeats: true)
        statusPoller.fire()
    }
    
    private func showLoginWindow() {
        
    }
    
    @objc private func updateState() {
        guard let uname = prefs.username,
            let url = URL(string: "http://www.reddit.com/user/\(uname)/about.json") else {
                print("User name empty")
                return
        }
        
        let task = session.dataTask(with: url) { (data, respose, error) in
            if let dataActual = data {
                print(try? JSONSerialization.jsonObject(with: dataActual, options: JSONSerialization.ReadingOptions.allowFragments))
            }
            else {
                print("Failure: \(respose)")
            }
        }
        
        task.resume()
    }
    
    @objc private func quit() {
        NSApplication.shared().stop(nil)
    }
    
    @objc  func handleLoginMenuSelected() {
        showLoginWindow()
    }
}
