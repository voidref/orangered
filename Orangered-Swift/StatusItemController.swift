//
//  StatusItemController.swift
//  Orangered
//
//  Created by Alan Westbrook on 6/13/16.
//  Copyright © 2016 Rockwood Software. All rights reserved.
//

import Foundation
import Cocoa

private let kUpdateURL = URL(string: "http://voidref.com/orangered/version")

class StatusItemController: NSObject, NSUserNotificationCenterDelegate {
    
    enum State {
        case disconnected
        case mailfree
        case orangered
        case modmail
        case update
        
        private static let imageMap = [
            disconnected: #imageLiteral(resourceName: "GreyEnvelope"),
            mailfree: #imageLiteral(resourceName: "BlackEnvelope"),
            orangered: #imageLiteral(resourceName: "OrangeredEnvelope"),
            modmail: #imageLiteral(resourceName: "modmailgrey"),
            update: #imageLiteral(resourceName: "BlueEnvelope")]
        
        private static let urlMap = [
            disconnected: nil,
            mailfree: URL(string: "https://www.reddit.com/message/inbox/"),
            orangered: URL(string: "https://www.reddit.com/message/unread/"),
            modmail: URL(string: "https://www.reddit.com/message/moderator/"),
            update: nil
        ]
        
        func image() -> NSImage {
            return State.imageMap[self]!
        }
        
        func mailboxUrl() -> URL? {
            return State.urlMap[self]!
        }
    }
    
    private var state = State.disconnected {
        didSet {
            handleStateChanged()
        }
    }
    
    private let statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
    
    private var statusPoller:Timer?
    private let prefs = UserDefaults.standard()
    private var statusConnection:URLSession?
    private let session = URLSession.shared()
    private var loginWindowController:NSWindowController?
    private var mailboxItem:NSMenuItem?
    
    override init() {
        super.init()
        setup()
        login()
    }
    
    private func setup() {
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = Menu()
        
        mailboxItem = NSMenuItem(title: "Mailbox...", action: #selector(handleMailboxItemSelected), keyEquivalent: "")
        menu.addItem(mailboxItem!)
        menu.addItem(NSMenuItem.separator())

        let loginItem = NSMenuItem(title: "Login...", action: #selector(handleLoginItemSelected), keyEquivalent: "")
        menu.addItem(loginItem)

        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(handleLoginItemSelected), keyEquivalent: "")
        menu.addItem(prefsItem)

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
        guard let url = URL(string: "https://ssl.reddit.com/api/login") else {
            print("Error bad url, wat?")
            return
        }
        
        guard let uname = prefs.username, let password = prefs.password else {
            showLoginWindow()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "user=\(uname)&passwd=\(password)".data(using: String.Encoding.utf8)
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            if let responseActual = response as? HTTPURLResponse {
                self.handleLoginResponse(responseActual)
            }
            else {
                self.state = .disconnected
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
            state = .disconnected
        }
        else {
            HTTPCookieStorage.shared().setCookies(cookies, for: URL(string: "https://reddit.com"), mainDocumentURL: nil)
            
            prefs.loggedIn = true
            setupStatusPoller()
        }
    }
    
    private func setupStatusPoller() {
        statusPoller?.invalidate()
        let interval:TimeInterval = 60
        statusPoller = Timer(timeInterval: interval, target: self, selector: #selector(updateState), userInfo: nil, repeats: true)
        RunLoop.main().add(statusPoller!, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    private func showLoginWindow() {
        let login = LoginViewController { [weak self] (name, password) in
            self?.loginWindowController?.close()
            self?.prefs.username = name
            self?.prefs.password = password
            self?.login()
        }
        
        loginWindowController = NSWindowController(window: NSWindow(contentViewController: login))
        
        NSApp.activateIgnoringOtherApps(true)
        loginWindowController?.showWindow(self)
    }
    
    private func interpretResponse(json: String) {
        // Crude, but remarkably immune to data restructuring as long as the key value pair doesn't change.

        if json.contains("has_mod_mail\": true") {
            state = .modmail
            return
        }

        if json.contains("has_mail\": true") {
            state = .orangered
        }
        else if json.contains("has_mail\": false") {
            state = .mailfree
        }
        else {
            // probably login error
            state = .disconnected
        }
        
    }
    
    private func handleStateChanged() {
        statusItem.image = state.image()
        mailboxItem?.isEnabled = true
        
        switch state {
            case .orangered, .modmail:
                notifyMail()
                
            case .disconnected:
                mailboxItem?.isEnabled = false
                DispatchQueue.main.after(when: DispatchTime.now() + 10, execute: { 
                    self.login()
                })

            case .mailfree, .update:
                break
        }
    }
    
    private func notifyMail() {
        let note = NSUserNotification()
        note.title                  = "Orangered!";
        note.informativeText        = "You have a new message on reddit!";
        note.actionButtonTitle      = "Read";
        
        NSUserNotificationCenter.default().deliver(note)
    }
    
    private func openMailbox() {        
        if let url = state.mailboxUrl() {
            NSWorkspace.shared().open(url)
        }
        
        DispatchQueue.main.async { 
            self.updateState()
        }
        
        NSUserNotificationCenter.default().removeAllDeliveredNotifications()
    }
    
    @objc private func updateState() {
        guard let uname = prefs.username,
            let url = URL(string: "http://www.reddit.com/user/\(uname)/about.json") else {
                print("User name empty")
                return
        }
        
        let task = session.dataTask(with: url) { (data, respose, error) in
            if let dataActual = data, let json = String(data: dataActual, encoding: String.Encoding.utf8) {
                self.interpretResponse(json: json)
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
    
    @objc func handleLoginItemSelected() {
        showLoginWindow()
    }
    
    @objc func handleMailboxItemSelected() {
        openMailbox()
    }
    
    
    // MARK: uset notification center
    
    @objc func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        openMailbox()
    }
}
