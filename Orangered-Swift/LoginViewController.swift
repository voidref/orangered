//
//  LoginViewController.swift
//  Orangered
//
//  Created by Alan Westbrook on 6/13/16.
//  Copyright © 2016 Rockwood Software. All rights reserved.
//

import Cocoa

let kHelpURL = URL(string: "https://www.github.com/voidref/orangered")

typealias LoginAction = (name:String, password:String) -> Void

class LoginViewController: NSViewController {

    private let nameLabel = NSTextField()
    private let passwordLabel = NSTextField()
    private let nameField = NSTextField()
    private let passwordField = NSSecureTextField()
    private let loginButton = NSButton()
    private let helpButton = NSButton()
    private let loginAction:LoginAction
    
    init(loginAction action: LoginAction) {
        loginAction = action

        // Effit, I want to override init (unfailable override), but I am required to call a failable initializer?
        super.init(nibName: nil, bundle: nil)!
        
        title = NSLocalizedString("Orangered! Login", comment: "The login window title")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func loadView() {
        // Don't call into super, as we don't want it to try to load from a nib
        view = NSVisualEffectView()
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setup() {
        view.translatesAutoresizingMaskIntoConstraints = false
        for subview in [nameLabel, nameField, passwordLabel, passwordField, loginButton] { add(subview) }
        
        func setup(label:NSTextField, text:String) {
            label.stringValue = text
            label.isEditable = false
            label.backgroundColor = #colorLiteral(red: 0.6470588235, green: 0.631372549, blue: 0.7725490196, alpha: 0)
            label.drawsBackground = false
            label.sizeToFit()
            label.isBezeled = false
        }
        
        setup(label: nameLabel, text: NSLocalizedString("User Name:", comment: "reddit user name field label"))
        setup(label: passwordLabel, text: NSLocalizedString("Password:", comment: "password field label"))
        
        let pref = UserDefaults.standard
        nameField.stringValue = pref.username ?? ""
        passwordField.stringValue = pref.password ?? ""
                
        loginButton.title = NSLocalizedString("Login", comment: "login button title on the login window")
        loginButton.bezelStyle = .rounded
        loginButton.keyEquivalent = "\r"
        loginButton.target = self
        loginButton.action = #selector(loginClicked)
        
        let space:CGFloat = 16
        let fieldWidth:CGFloat = 160
        
        let fieldGuide = NSLayoutGuide()
        view.addLayoutGuide(fieldGuide)
        
        helpButton.bezelStyle = .helpButton
        helpButton.title = ""
        helpButton.target = self
        helpButton.action = #selector(helpClicked)
        add(helpButton)
        
        NSLayoutConstraint.activate([
            fieldGuide.topAnchor.constraint(equalTo: nameLabel.topAnchor),
            fieldGuide.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            fieldGuide.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            fieldGuide.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fieldGuide.bottomAnchor.constraint(equalTo: passwordLabel.bottomAnchor),
            
            nameLabel.trailingAnchor.constraint(equalTo: nameField.leadingAnchor, constant: -space / 2),
            nameField.firstBaselineAnchor.constraint(equalTo: nameLabel.firstBaselineAnchor),
            nameField.widthAnchor.constraint(equalToConstant: fieldWidth),
            
            passwordLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: space / 2),
            passwordLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            passwordField.firstBaselineAnchor.constraint(equalTo: passwordLabel.firstBaselineAnchor),
            passwordField.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            
            loginButton.topAnchor.constraint(equalTo: fieldGuide.bottomAnchor, constant: space),
            loginButton.trailingAnchor.constraint(equalTo: fieldGuide.trailingAnchor),

            helpButton.leadingAnchor.constraint(equalTo: fieldGuide.leadingAnchor),
            helpButton.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor),
            
            view.topAnchor.constraint(equalTo: nameLabel.topAnchor, constant: -space),
            view.bottomAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: space),
            view.widthAnchor.constraint(equalTo: fieldGuide.widthAnchor, constant: space * 2)
        ])
    }
    
    private func add(_ sub:NSView) {
        sub.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sub)
    }
    
    @objc private func loginClicked() {
        loginAction(name: nameField.stringValue, password: passwordField.stringValue)
    }
    
    @objc private func helpClicked() {
        if let urlActual = kHelpURL {
            NSWorkspace.shared().open(urlActual)
        }
        else {
            print("Umm, fix your url?")
        }
    }
}

