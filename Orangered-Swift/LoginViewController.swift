//
//  LoginViewController.swift
//  Orangered
//
//  Created by Alan Westbrook on 6/13/16.
//  Copyright © 2016 Rockwood Software. All rights reserved.
//

import Cocoa

typealias LoginAction = (name:String, password:String) -> Void
class LoginViewController: NSViewController {

    let nameLabel = NSTextField()
    let passwordLabel = NSTextField()
    let nameField = NSTextField()
    let passwordField = NSSecureTextField()
    let loginButton = NSButton()
    let loginAction:LoginAction
    
    init(loginAction action: LoginAction) {
        loginAction = action

        // Effit, I want to override init (unfailable override), but I am required to call a failable initializer?
        super.init(nibName: nil, bundle: nil)!
        
        title = "Orangered! Login"
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
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setup() {
        view.translatesAutoresizingMaskIntoConstraints = false
        for sub in [nameLabel, nameField, passwordLabel, passwordField, loginButton] { add(sub: sub) }
        
        func setupLabel(label:NSTextField, text:String) {
            label.stringValue = text
            label.isEditable = false
            label.backgroundColor = #colorLiteral(red: 0.6470588235, green: 0.631372549, blue: 0.7725490196, alpha: 0)
            label.drawsBackground = false
            label.sizeToFit()
            label.isBezeled = false
        }
        
        setupLabel(label: nameLabel, text: "User Name:")
        setupLabel(label: passwordLabel, text: "Password:")
        
        let pref = UserDefaults.standard()
        nameField.stringValue = pref.username ?? ""
        passwordField.stringValue = pref.password ?? ""
                
        loginButton.title = NSLocalizedString("Login", comment: "login button title on the login window")
        loginButton.bezelStyle = .roundedBezelStyle
        loginButton.keyEquivalent = "\r"
        loginButton.target = self
        loginButton.action = #selector(loginClicked)
        
        let space:CGFloat = 16
        let fieldWidth:CGFloat = 160
        
        let fieldGuide = NSLayoutGuide()
        view.addLayoutGuide(fieldGuide)
        
        NSLayoutConstraint.activate([
            fieldGuide.topAnchor.constraint(equalTo: nameLabel.topAnchor),
            fieldGuide.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
            fieldGuide.rightAnchor.constraint(equalTo: nameField.rightAnchor),
            fieldGuide.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fieldGuide.bottomAnchor.constraint(equalTo: passwordLabel.bottomAnchor),
            
            nameLabel.rightAnchor.constraint(equalTo: nameField.leftAnchor, constant: -space / 2),
            nameField.firstBaselineAnchor.constraint(equalTo: nameLabel.firstBaselineAnchor),
            nameField.widthAnchor.constraint(equalToConstant: fieldWidth),
            
            passwordLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: space / 2),
            passwordLabel.rightAnchor.constraint(equalTo: nameLabel.rightAnchor),
            passwordField.firstBaselineAnchor.constraint(equalTo: passwordLabel.firstBaselineAnchor),
            passwordField.leftAnchor.constraint(equalTo: nameField.leftAnchor),
            passwordField.rightAnchor.constraint(equalTo: nameField.rightAnchor),
            
            loginButton.topAnchor.constraint(equalTo: fieldGuide.bottomAnchor, constant: space),
            loginButton.rightAnchor.constraint(equalTo: fieldGuide.rightAnchor),

            view.topAnchor.constraint(equalTo: nameLabel.topAnchor, constant: -space),
            view.bottomAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: space),
            view.widthAnchor.constraint(equalTo: fieldGuide.widthAnchor, constant: space * 2)
        ])
    }
    
    private func add(sub:NSView) {
        sub.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sub)
    }
    
    @objc private func loginClicked() {
        loginAction(name: nameField.stringValue, password: passwordField.stringValue)
    }
}
